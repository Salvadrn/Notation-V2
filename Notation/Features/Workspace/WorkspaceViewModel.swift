import SwiftUI
import Combine

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

    private let folderService: FolderService
    private let notebookService: NotebookService
    private let featureGate: FeatureGate
    private let localStorage = LocalStorageService.shared
    private let supabase = SupabaseService.shared

    init(
        folderService: FolderService = FolderService(),
        notebookService: NotebookService = NotebookService(),
        featureGate: FeatureGate
    ) {
        self.folderService = folderService
        self.notebookService = notebookService
        self.featureGate = featureGate
    }

    private var isGuest: Bool { supabase.isGuestMode }

    var filteredNotebooks: [Notebook] {
        if searchText.isEmpty { return notebooks }
        return notebooks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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
            folders = localStorage.fetchFolders()
            notebooks = localStorage.fetchNotebooks(folderId: selectedFolder?.id)
        } else {
            do {
                folders = try await folderService.fetchFolders()
                notebooks = try await notebookService.fetchNotebooks(folderId: selectedFolder?.id)
            } catch {
                ErrorHandler.shared.handle(error, title: "Failed to load workspace") {
                    await self.loadWorkspace()
                }
            }
        }
    }

    func selectFolder(_ folder: Folder?) async {
        selectedFolder = folder
        updateBreadcrumb()

        if isGuest {
            notebooks = localStorage.fetchNotebooks(folderId: folder?.id)
        } else {
            do {
                notebooks = try await notebookService.fetchNotebooks(folderId: folder?.id)
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
            let currentCount = localStorage.notebookCount()
            guard currentCount < Constants.FreeTier.maxNotebooks else {
                ErrorHandler.shared.handle(
                    NotationError.freeTierLimit("notebooks (max \(Constants.FreeTier.maxNotebooks) in guest mode)"),
                    title: "Notebook Limit"
                )
                return
            }
            let notebook = localStorage.createNotebook(title: title, folderId: selectedFolder?.id)
            notebooks.append(notebook)
        } else {
            let currentCount = notebooks.count
            guard featureGate.canCreateNotebook(currentCount: currentCount) else {
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

    func deleteNotebook(_ notebook: Notebook) async {
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
}
