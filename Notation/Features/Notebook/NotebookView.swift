import SwiftUI

struct NotebookView: View {
    @StateObject private var viewModel: NotebookViewModel
    @State private var showExportSheet = false
    @State private var showPageNav = false

    init(notebook: Notebook) {
        _viewModel = StateObject(wrappedValue: NotebookViewModel(notebook: notebook))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section tabs
            SectionTabBar(
                sections: viewModel.sections,
                selectedSection: viewModel.selectedSection,
                onSelect: { section in
                    Task { await viewModel.selectSection(section) }
                },
                onAdd: { viewModel.showNewSection = true },
                onRename: { section, name in
                    Task { await viewModel.renameSection(section, to: name) }
                },
                onDelete: { section in
                    Task { await viewModel.deleteSection(section) }
                }
            )

            Divider()

            // Page content
            if viewModel.pages.isEmpty {
                VStack(spacing: Theme.Spacing.lg) {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Pages",
                        subtitle: "Add a page to start writing"
                    )

                    Button {
                        Task { await viewModel.addPage() }
                    } label: {
                        Label("Add Page", systemImage: "plus")
                            .font(Theme.Typography.headline)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.primaryFallback)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let page = viewModel.currentPage {
                PageView(
                    page: page,
                    onSave: { updated in
                        if let index = viewModel.pages.firstIndex(where: { $0.id == updated.id }) {
                            viewModel.pages[index] = updated
                        }
                    }
                )
            }
        }
        .navigationTitle(viewModel.notebook.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Page navigation
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        viewModel.goToPreviousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.selectedPageIndex == 0)

                    Text("\(viewModel.selectedPageIndex + 1) / \(viewModel.pageCount)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .monospacedDigit()

                    Button {
                        viewModel.goToNextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.selectedPageIndex >= viewModel.pageCount - 1)
                }

                Button {
                    Task { await viewModel.addPage() }
                } label: {
                    Image(systemName: "doc.badge.plus")
                }

                Button {
                    showPageNav.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }

                Menu {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export Notebook PDF", systemImage: "arrow.down.doc")
                    }

                    Button {
                        // Export current page
                    } label: {
                        Label("Export Page PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showNewSection) {
            NewSectionSheet { title in
                Task { await viewModel.createSection(title: title) }
            }
        }
        .inspector(isPresented: $showPageNav) {
            PageNavigationView(
                pages: viewModel.pages,
                selectedIndex: $viewModel.selectedPageIndex
            )
            .inspectorColumnWidth(min: 150, ideal: 200, max: 250)
        }
        .onFirstAppear {
            await viewModel.loadNotebook()
        }
        .withErrorHandling()
    }
}
