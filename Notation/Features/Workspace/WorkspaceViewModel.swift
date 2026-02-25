import SwiftUI
import Combine

enum QuickAction: Hashable {
    case alphabetStudio
    case aiNotes
}

enum WorkspaceFilter: Hashable {
    case all
    case favorites
    case trash
}

@MainActor
final class WorkspaceViewModel: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var notebooks: [Notebook] = []
    @Published var selectedFolder: Folder?
    @Published var expandedFolderIDs: Set<UUID> = []
    @Published var breadcrumb: [Folder] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var showNewFolder = false
    @Published var showNewNotebook = false
    @Published var selectedNotebook: Notebook?
    @Published var selectedQuickAction: QuickAction?
    @Published var activeFilter: WorkspaceFilter = .all
    @Published var syncStatus: SyncStatus = .idle

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error
    }

    private let folderService: FolderService
    private let notebookService: NotebookService
    private var featureGate: FeatureGate?
    private let localStorage = LocalStorageService.shared
    private let supabase = SupabaseService.shared

    init(
        folderService: FolderService = FolderService(),
        notebookService: NotebookService = NotebookService()
    ) {
        self.folderService = folderService
        self.notebookService = notebookService
    }

    /// Must be called once the SubscriptionService is available from @EnvironmentObject
    func configure(subscriptionService: SubscriptionService) {
        guard featureGate == nil else { return }
        featureGate = FeatureGate(subscriptionService: subscriptionService)
    }

    private var isGuest: Bool { supabase.isGuestMode }

    // MARK: - Filtered Views

    var filteredNotebooks: [Notebook] {
        var result: [Notebook]

        switch activeFilter {
        case .all:
            result = notebooks.filter { !$0.isDeleted }
        case .favorites:
            result = notebooks.filter { $0.isFavorite && !$0.isDeleted }
        case .trash:
            result = notebooks.filter { $0.isDeleted }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        // Favorites first for "all" view
        if activeFilter == .all {
            result.sort { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
                return (lhs.updatedAt ?? .distantPast) > (rhs.updatedAt ?? .distantPast)
            }
        }

        return result
    }

    var trashCount: Int {
        notebooks.filter { $0.isDeleted }.count
    }

    var favoriteCount: Int {
        notebooks.filter { $0.isFavorite && !$0.isDeleted }.count
    }

    var rootFolders: [Folder] {
        folders.filter { $0.parentId == nil }
    }

    func subfolders(of parentId: UUID) -> [Folder] {
        folders.filter { $0.parentId == parentId }
    }

    // MARK: - Load Data

    func loadWorkspace() async {
        isLoading = true
        defer { isLoading = false }

        if isGuest {
            syncStatus = .offline
            folders = localStorage.fetchFolders()
            let allNotebooks = localStorage.fetchAllNotebooks()
            if activeFilter == .trash {
                notebooks = allNotebooks
            } else if let folderId = selectedFolder?.id {
                notebooks = allNotebooks.filter { $0.folderId == folderId }
            } else {
                notebooks = allNotebooks
            }
            // Auto-purge expired trash items
            purgeExpiredNotebooks()
        } else {
            syncStatus = .syncing
            do {
                folders = try await folderService.fetchFolders()
                notebooks = try await notebookService.fetchAllNotebooks()
                syncStatus = .synced
                // Auto-dismiss sync status after delay
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if syncStatus == .synced { syncStatus = .idle }
                }
            } catch {
                syncStatus = .error
                ErrorHandler.shared.handle(error, title: "Failed to load workspace") {
                    await self.loadWorkspace()
                }
            }
        }
    }

    func selectFolder(_ folder: Folder?) async {
        selectedFolder = folder
        activeFilter = .all
        updateBreadcrumb()

        if isGuest {
            let allNotebooks = localStorage.fetchAllNotebooks()
            if let folderId = folder?.id {
                notebooks = allNotebooks.filter { $0.folderId == folderId }
            } else {
                notebooks = allNotebooks
            }
        } else {
            do {
                notebooks = try await notebookService.fetchAllNotebooks()
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }

    // MARK: - Folder Operations

    func createFolder(name: String) async {
        if isGuest {
            let folder = localStorage.createFolder(
                name: name,
                parentId: selectedFolder?.id,
                parentPath: selectedFolder?.path ?? ""
            )
            folders.append(folder)
        } else {
            do {
                let folder = try await folderService.createFolder(
                    name: name,
                    parentId: selectedFolder?.id,
                    parentPath: selectedFolder?.path ?? ""
                )
                folders.append(folder)
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }

    func renameFolder(_ folder: Folder, to name: String) async {
        var updated = folder
        updated.name = name
        if isGuest {
            localStorage.updateFolder(updated)
            if let index = folders.firstIndex(where: { $0.id == folder.id }) {
                folders[index] = updated
            }
        } else {
            do {
                try await folderService.updateFolder(updated)
                if let index = folders.firstIndex(where: { $0.id == folder.id }) {
                    folders[index] = updated
                }
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }

    func deleteFolder(_ folder: Folder) async {
        if isGuest {
            localStorage.deleteFolder(id: folder.id)
        } else {
            do {
                try await folderService.deleteFolder(id: folder.id)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        folders.removeAll { $0.id == folder.id }
        if selectedFolder?.id == folder.id {
            await selectFolder(nil)
        }
    }

    func moveFolder(_ folder: Folder, toParent parent: Folder?) async {
        if !isGuest {
            do {
                try await folderService.moveFolder(
                    folder.id,
                    toParent: parent?.id,
                    parentPath: parent?.path ?? ""
                )
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        await loadWorkspace()
    }

    func toggleExpanded(_ folderId: UUID) {
        if expandedFolderIDs.contains(folderId) {
            expandedFolderIDs.remove(folderId)
        } else {
            expandedFolderIDs.insert(folderId)
        }
    }

    // MARK: - Notebook Operations

    func createNotebook(title: String) async {
        if isGuest {
            let activeCount = localStorage.fetchAllNotebooks().filter { !$0.isDeleted }.count
            guard activeCount < Constants.FreeTier.maxNotebooks else {
                ErrorHandler.shared.handle(
                    NotationError.freeTierLimit("notebooks (max \(Constants.FreeTier.maxNotebooks) in guest mode)"),
                    title: "Notebook Limit"
                )
                return
            }
            let notebook = localStorage.createNotebook(title: title, folderId: selectedFolder?.id)
            notebooks.append(notebook)
        } else {
            // Refresh tier before checking gate
            await featureGate?.refreshTier()
            let activeCount = notebooks.filter { !$0.isDeleted }.count
            guard featureGate?.canCreateNotebook(currentCount: activeCount) ?? true else {
                ErrorHandler.shared.handle(
                    NotationError.freeTierLimit("notebooks"),
                    title: "Notebook Limit"
                )
                return
            }
            do {
                let notebook = try await notebookService.createNotebook(
                    title: title,
                    folderId: selectedFolder?.id
                )
                notebooks.append(notebook)
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }

    /// Soft delete — moves notebook to trash (30 day retention)
    func softDeleteNotebook(_ notebook: Notebook) async {
        var updated = notebook
        updated.isDeleted = true
        updated.deletedAt = Date()

        if isGuest {
            localStorage.updateNotebook(updated)
        } else {
            do {
                try await notebookService.updateNotebook(updated)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index] = updated
        }
    }

    /// Restore notebook from trash
    func restoreNotebook(_ notebook: Notebook) async {
        var updated = notebook
        updated.isDeleted = false
        updated.deletedAt = nil

        if isGuest {
            localStorage.updateNotebook(updated)
        } else {
            do {
                try await notebookService.updateNotebook(updated)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index] = updated
        }
    }

    /// Permanently delete — no recovery
    func permanentlyDeleteNotebook(_ notebook: Notebook) async {
        if isGuest {
            localStorage.deleteNotebook(id: notebook.id)
        } else {
            do {
                try await notebookService.deleteNotebook(id: notebook.id)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        notebooks.removeAll { $0.id == notebook.id }
    }

    /// Empty entire trash
    func emptyTrash() async {
        let trashed = notebooks.filter { $0.isDeleted }
        for notebook in trashed {
            await permanentlyDeleteNotebook(notebook)
        }
    }

    func renameNotebook(_ notebook: Notebook, to title: String) async {
        var updated = notebook
        updated.title = title
        if isGuest {
            localStorage.updateNotebook(updated)
        } else {
            do {
                try await notebookService.updateNotebook(updated)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index] = updated
        }
    }

    func moveNotebook(_ notebook: Notebook, toFolder folder: Folder?) async {
        if !isGuest {
            do {
                try await notebookService.moveNotebook(notebook.id, toFolder: folder?.id)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        notebooks.removeAll { $0.id == notebook.id }
    }

    // MARK: - Favorites

    func toggleFavorite(_ notebook: Notebook) async {
        var updated = notebook
        updated.isFavorite.toggle()

        if isGuest {
            localStorage.updateNotebook(updated)
        } else {
            do {
                try await notebookService.updateNotebook(updated)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index] = updated
        }
    }

    // MARK: - Private

    private func updateBreadcrumb() {
        guard let folder = selectedFolder else {
            breadcrumb = []
            return
        }

        let pathComponents = folder.path
            .components(separatedBy: "/")
            .filter { !$0.isEmpty }

        breadcrumb = pathComponents.compactMap { idString in
            folders.first { $0.id.uuidString == idString }
        }
    }

    /// Remove notebooks that have been in trash for > 30 days
    private func purgeExpiredNotebooks() {
        let expired = notebooks.filter { $0.shouldPurge }
        for notebook in expired {
            if isGuest {
                localStorage.deleteNotebook(id: notebook.id)
            }
            notebooks.removeAll { $0.id == notebook.id }
        }
    }
}
