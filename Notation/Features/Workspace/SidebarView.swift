import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: WorkspaceViewModel

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedFolder?.id },
            set: { id in
                let folder = viewModel.folders.first { $0.id == id }
                Task { await viewModel.selectFolder(folder) }
            }
        )) {
            // All Notebooks
            Label("All Notebooks", systemImage: "books.vertical")
                .tag(nil as UUID?)
                .onTapGesture {
                    Task { await viewModel.selectFolder(nil) }
                }

            // Folder tree
            SwiftUI.Section("Folders") {
                ForEach(viewModel.rootFolders) { folder in
                    FolderRowView(
                        folder: folder,
                        allFolders: viewModel.folders,
                        expandedIDs: $viewModel.expandedFolderIDs,
                        onSelect: { selected in
                            Task { await viewModel.selectFolder(selected) }
                        },
                        onRename: { folder, name in
                            Task { await viewModel.renameFolder(folder, to: name) }
                        },
                        onDelete: { folder in
                            Task { await viewModel.deleteFolder(folder) }
                        }
                    )
                }
            }

            // Quick Actions
            SwiftUI.Section("Quick Actions") {
                #if os(iOS)
                NavigationLink {
                    AlphabetStudioView()
                } label: {
                    Label("My Alphabet Studio", systemImage: "hand.draw")
                }
                #endif

                NavigationLink {
                    AINotesView()
                } label: {
                    Label("Generate AI Notes", systemImage: "sparkles")
                }
            }
        }
        .listStyle(.sidebar)
    }
}
