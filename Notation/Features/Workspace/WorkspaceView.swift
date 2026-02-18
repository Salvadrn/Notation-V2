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

                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if supabase.isGuestMode {
                        guestBanner
                    }
                }
        } detail: {
            if let notebook = viewModel.selectedNotebook {
                NotebookView(notebook: notebook)
            } else {
                VStack(spacing: 0) {
                    if supabase.isGuestMode {
                        guestInfoBar
                    }

                    BreadcrumbView(folders: viewModel.breadcrumb) { folder in
                        Task { await viewModel.selectFolder(folder) }
                    }

                    if viewModel.filteredNotebooks.isEmpty && !viewModel.isLoading {
                        welcomeView
                    } else {
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

    // MARK: - Guest Banner (sidebar bottom)

    private var guestBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Guest Mode")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Data saved locally")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer()
            Button("Sign Out") {
                supabase.exitGuestMode()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.Colors.destructive)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Colors.backgroundSecondary)
    }

    // MARK: - Guest info bar (detail top)

    private var guestInfoBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.accent)
            Text("Files are saved on this device only. \(viewModel.notebooks.count)/\(Constants.FreeTier.maxNotebooks) notebooks used.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, 8)
        .background(Theme.Colors.accent.opacity(0.08))
    }

    // MARK: - Welcome view when no notebooks

    private var welcomeView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text("Welcome to Notation")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Create a notebook to start writing, drawing, and organizing your ideas.")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Button {
                viewModel.showNewNotebook = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Notebook")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Theme.Colors.primaryFallback)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Quick tips
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "book.closed.fill", text: "Notebooks contain sections and pages")
                tipRow(icon: "folder.fill", text: "Organize notebooks into folders")
                tipRow(icon: "hand.draw.fill", text: "Draw with Apple Pencil on iPad")
                tipRow(icon: "keyboard", text: "Type directly on any page")
            }
            .padding(20)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxWidth: 360)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xl)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.primaryFallback)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
