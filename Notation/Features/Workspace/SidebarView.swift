import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: WorkspaceViewModel

    var body: some View {
        List(selection: Binding(
            get: { viewModel.selectedFolder?.id },
            set: { id in
                let folder = viewModel.folders.first { $0.id == id }
                viewModel.selectedQuickAction = nil
                viewModel.selectedNotebook = nil
                Task { await viewModel.selectFolder(folder) }
            }
        )) {
            // All Notebooks
            Button {
                viewModel.activeFilter = .all
                viewModel.selectedQuickAction = nil
                viewModel.selectedNotebook = nil
                Task { await viewModel.selectFolder(nil) }
            } label: {
                Label {
                    Text("All Notebooks")
                } icon: {
                    Image(systemName: "books.vertical")
                }
                .foregroundStyle(
                    viewModel.activeFilter == .all && viewModel.selectedFolder == nil
                        ? Theme.Colors.primaryFallback
                        : Theme.Colors.textPrimary
                )
            }

            // Favorites
            Button {
                viewModel.activeFilter = .favorites
                viewModel.selectedQuickAction = nil
                viewModel.selectedNotebook = nil
                viewModel.selectedFolder = nil
            } label: {
                Label {
                    HStack {
                        Text("Favorites")
                        Spacer()
                        if viewModel.favoriteCount > 0 {
                            Text("\(viewModel.favoriteCount)")
                                .font(.custom("Aptos", size: 11))
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.backgroundTertiary)
                                .clipShape(Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(
                            viewModel.activeFilter == .favorites
                                ? Theme.Colors.primaryFallback
                                : Color.yellow.opacity(0.8)
                        )
                }
                .foregroundStyle(
                    viewModel.activeFilter == .favorites
                        ? Theme.Colors.primaryFallback
                        : Theme.Colors.textPrimary
                )
            }

            // Folder tree
            SwiftUI.Section("Folders") {
                ForEach(viewModel.rootFolders) { folder in
                    FolderRowView(
                        folder: folder,
                        allFolders: viewModel.folders,
                        expandedIDs: $viewModel.expandedFolderIDs,
                        onSelect: { selected in
                            viewModel.activeFilter = .all
                            viewModel.selectedQuickAction = nil
                            viewModel.selectedNotebook = nil
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

            // Quick Actions — rendered in detail column, NOT pushed in sidebar
            SwiftUI.Section("Quick Actions") {
                #if os(iOS)
                Button {
                    viewModel.selectedNotebook = nil
                    viewModel.selectedQuickAction = .alphabetStudio
                } label: {
                    Label("My Alphabet Studio", systemImage: "hand.draw")
                        .foregroundStyle(
                            viewModel.selectedQuickAction == .alphabetStudio
                                ? Theme.Colors.primaryFallback
                                : Theme.Colors.textPrimary
                        )
                }
                #endif

                Button {
                    viewModel.selectedNotebook = nil
                    viewModel.selectedQuickAction = .aiNotes
                } label: {
                    Label("Generate AI Notes", systemImage: "sparkles")
                        .foregroundStyle(
                            viewModel.selectedQuickAction == .aiNotes
                                ? Theme.Colors.primaryFallback
                                : Theme.Colors.textPrimary
                        )
                }
            }

            // Recently Deleted (Trash)
            SwiftUI.Section {
                Button {
                    viewModel.activeFilter = .trash
                    viewModel.selectedQuickAction = nil
                    viewModel.selectedNotebook = nil
                    viewModel.selectedFolder = nil
                } label: {
                    Label {
                        HStack {
                            Text("Recently Deleted")
                            Spacer()
                            if viewModel.trashCount > 0 {
                                Text("\(viewModel.trashCount)")
                                    .font(.custom("Aptos", size: 11))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.destructive)
                                    .clipShape(Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundStyle(
                                viewModel.activeFilter == .trash
                                    ? Theme.Colors.primaryFallback
                                    : Theme.Colors.textSecondary
                            )
                    }
                    .foregroundStyle(
                        viewModel.activeFilter == .trash
                            ? Theme.Colors.primaryFallback
                            : Theme.Colors.textPrimary
                    )
                }
            }
        }
        .listStyle(.sidebar)
    }
}
