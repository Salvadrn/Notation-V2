import Foundation
import Supabase
import Realtime

struct PresenceUser: Codable {
    let userId: String
    let userName: String
    let pageId: String?
}

@MainActor
final class RealtimeService: ObservableObject {
    private let supabase: SupabaseService
    private var channels: [String: RealtimeChannelV2] = [:]

    @Published var activeCollaborators: [String: [PresenceUser]] = [:]
    @Published var isConnected = false

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Notebook Channel

    func joinNotebookChannel(
        notebookId: UUID,
        userName: String,
        onPageChange: @escaping (Page) -> Void,
        onLayerChange: @escaping (PageLayer) -> Void
    ) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"

        let channel = supabase.client.realtimeV2.channel(channelName) {
            $0.broadcast.acknowledgeBroadcasts = true
        }

        // Listen for page changes via Postgres Changes
        let pageChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "pages",
            filter: "section_id=in.(select id from sections where notebook_id='\(notebookId.uuidString)')"
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
                userId: supabase.currentUserId?.uuidString ?? "",
                userName: userName,
                pageId: nil
            )
        )

        channels[channelName] = channel
        isConnected = true

        // Handle page changes
        Task {
            for await change in pageChanges {
                if let record = change.record {
                    if let data = try? JSONSerialization.data(withJSONObject: record),
                       let page = try? JSONDecoder.supabaseDecoder.decode(Page.self, from: data) {
                        await MainActor.run { onPageChange(page) }
                    }
                }
            }
        }

        // Handle layer changes
        Task {
            for await change in layerChanges {
                if let record = change.record {
                    if let data = try? JSONSerialization.data(withJSONObject: record),
                       let layer = try? JSONDecoder.supabaseDecoder.decode(PageLayer.self, from: data) {
                        await MainActor.run { onLayerChange(layer) }
                    }
                }
            }
        }

        // Handle presence
        Task {
            for await _ in presenceChanges {
                let presences = channel.presenceState()
                var users: [PresenceUser] = []
                for (_, presenceList) in presences {
                    for presence in presenceList {
                        if let data = try? JSONSerialization.data(withJSONObject: presence),
                           let user = try? JSONDecoder().decode(PresenceUser.self, from: data) {
                            users.append(user)
                        }
                    }
                }
                await MainActor.run {
                    self.activeCollaborators[channelName] = users
                }
            }
        }
    }

    func leaveNotebookChannel(notebookId: UUID) async {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"
        if let channel = channels[channelName] {
            await channel.unsubscribe()
            channels.removeValue(forKey: channelName)
        }

        if channels.isEmpty {
            isConnected = false
        }
    }

    func broadcastPageUpdate(notebookId: UUID, page: Page) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"
        guard let channel = channels[channelName] else { return }

        let data = try JSONEncoder().encode(page)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        try await channel.broadcast(event: "page_update", message: dict)
    }

    func updatePresencePage(notebookId: UUID, pageId: UUID?, userName: String) async throws {
        let channelName = "\(Constants.Realtime.channelPrefix)\(notebookId.uuidString)"
        guard let channel = channels[channelName] else { return }

        try await channel.track(
            PresenceUser(
                userId: supabase.currentUserId?.uuidString ?? "",
                userName: userName,
                pageId: pageId?.uuidString
            )
        )
    }

    func disconnectAll() async {
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
