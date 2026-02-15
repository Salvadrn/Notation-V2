import SwiftUI

struct WorkspaceView: View {
    @StateObject private var viewModel: WorkspaceViewModel
    @EnvironmentObject var supabase: SupabaseService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showSettings = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    init() {
        let gate = FeatureGate(subscriptionService: SubscriptionService())
        _viewModel = StateObject(wrappedValue: WorkspaceViewModel(featureGate: gate))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationTitle("Notation")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                viewModel.showNewFolder = true
                            } label: {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }

                            Button {
                                viewModel.showNewNotebook = true
                            } label: {
                                Label("New Notebook", systemImage: "book.closed.fill")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        } detail: {
            if let notebook = viewModel.selectedNotebook {
                NotebookView(notebook: notebook)
            } else {
                VStack(spacing: Theme.Spacing.lg) {
                    BreadcrumbView(folders: viewModel.breadcrumb) { folder in
                        Task { await viewModel.selectFolder(folder) }
                    }

                    NotebookGridView(
                        notebooks: viewModel.filteredNotebooks,
                        onSelect: { notebook in
                            viewModel.selectedNotebook = notebook
                        },
                        onDelete: { notebook in
                            Task { await viewModel.deleteNotebook(notebook) }
                        },
                        onRename: { notebook, name in
                            Task { await viewModel.renameNotebook(notebook, to: name) }
                        }
                    )
                }
                .searchable(text: $viewModel.searchText, prompt: "Search notebooks...")
                .navigationTitle(viewModel.selectedFolder?.name ?? "All Notebooks")
            }
        }
        .sheet(isPresented: $viewModel.showNewFolder) {
            NewFolderSheet { name in
                Task { await viewModel.createFolder(name: name) }
            }
        }
        .sheet(isPresented: $viewModel.showNewNotebook) {
            NewNotebookSheet { title in
                Task { await viewModel.createNotebook(title: title) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onFirstAppear {
            await viewModel.loadWorkspace()
        }
        .withErrorHandling()
    }
}
