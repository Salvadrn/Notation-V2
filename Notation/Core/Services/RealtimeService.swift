import Foundation
import Supabase
import Realtime

struct PresenceUser: Codable, Sendable {
    let userId: String
    let userName: String
    let pageId: String?
}

@MainActor
final class RealtimeService: ObservableObject {
    private let supabase: SupabaseService
    private var channels: [String: RealtimeChannelV2] = [:]
    private var channelTasks: [String: [Task<Void, Never>]] = [:]

    @Published var activeCollaborators: [String: [PresenceUser]] = [:]
    @Published var isConnected = false

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    private var currentUserId: String {
        supabase.currentUserId?.uuidString ?? "anonymous"
    }

    // MARK: - Notebook Channel

    func joinNotebookChannel(
        notebookId: UUID,
        userName: String,
        onPageChange: @escaping @Sendable (Page) -> Void,
        onLayerChange: @escaping @Sendable (PageLayer) -> Void
    ) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"

        let channel = supabase.client.realtimeV2.channel(channelName) {
            $0.broadcast.acknowledgeBroadcasts = true
        }

        // Listen for page changes via Postgres Changes
        let pageChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "pages"
        )

        let layerChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "page_layers"
        )

        // Listen for presence
        let presenceChanges = channel.presenceChange()

        // Subscribe
        await channel.subscribe()

        // Track presence
        try await channel.track(
            PresenceUser(
                userId: currentUserId,
                userName: userName,
                pageId: nil
            )
        )

        channels[channelName] = channel

        // Cancel any existing tasks for this channel
        channelTasks[channelName]?.forEach { $0.cancel() }

        var tasks: [Task<Void, Never>] = []

        // Handle page changes
        let pageTask = Task { @Sendable in
            for await change in pageChanges {
                guard !Task.isCancelled else { break }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                switch change {
                case .insert(let action):
                    if let page = try? action.decodeRecord(as: Page.self, decoder: decoder) {
                        await MainActor.run { onPageChange(page) }
                    }
                case .update(let action):
                    if let page = try? action.decodeRecord(as: Page.self, decoder: decoder) {
                        await MainActor.run { onPageChange(page) }
                    }
                case .delete:
                    break
                }
            }
        }
        tasks.append(pageTask)

        // Handle layer changes
        let layerTask = Task { @Sendable in
            for await change in layerChanges {
                guard !Task.isCancelled else { break }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                switch change {
                case .insert(let action):
                    if let layer = try? action.decodeRecord(as: PageLayer.self, decoder: decoder) {
                        await MainActor.run { onLayerChange(layer) }
                    }
                case .update(let action):
                    if let layer = try? action.decodeRecord(as: PageLayer.self, decoder: decoder) {
                        await MainActor.run { onLayerChange(layer) }
                    }
                case .delete:
                    break
                }
            }
        }
        tasks.append(layerTask)

        // Handle presence
        let presenceTask = Task { @Sendable [weak self] in
            for await action in presenceChanges {
                guard !Task.isCancelled else { break }
                let joins = (try? action.decodeJoins(as: PresenceUser.self)) ?? []
                let leaves = (try? action.decodeLeaves(as: PresenceUser.self)) ?? []
                await MainActor.run {
                    guard let self else { return }
                    var current = self.activeCollaborators[channelName] ?? []
                    for user in joins {
                        if !current.contains(where: { $0.userId == user.userId }) {
                            current.append(user)
                        }
                    }
                    let leaveIds = Set(leaves.map(\.userId))
                    current.removeAll { leaveIds.contains($0.userId) }
                    self.activeCollaborators[channelName] = current
                }
            }
        }
        tasks.append(presenceTask)

        channelTasks[channelName] = tasks
        isConnected = true
    }

    func leaveNotebookChannel(notebookId: UUID) async {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"

        // Cancel listener tasks first
        channelTasks[channelName]?.forEach { $0.cancel() }
        channelTasks.removeValue(forKey: channelName)

        if let channel = channels[channelName] {
            await channel.unsubscribe()
            channels.removeValue(forKey: channelName)
        }

        activeCollaborators.removeValue(forKey: channelName)

        if channels.isEmpty {
            isConnected = false
        }
    }

    func broadcastPageUpdate(notebookId: UUID, page: Page) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"
        guard let channel = channels[channelName] else { return }

        try await channel.broadcast(event: "page_update", message: page)
    }

    func updatePresencePage(notebookId: UUID, pageId: UUID?, userName: String) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"
        guard let channel = channels[channelName] else { return }

        try await channel.track(
            PresenceUser(
                userId: currentUserId,
                userName: userName,
                pageId: pageId?.uuidString
            )
        )
    }

    func disconnectAll() async {
        // Cancel all listener tasks
        for (_, tasks) in channelTasks {
            tasks.forEach { $0.cancel() }
        }
        channelTasks.removeAll()

        for (_, channel) in channels {
            await channel.unsubscribe()
        }
        channels.removeAll()
        activeCollaborators.removeAll()
        isConnected = false
    }
}

// Helper to decode Supabase JSON
extension JSONDecoder {
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
