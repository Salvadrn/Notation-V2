import SwiftUI
#if os(iOS)
import UIKit
#endif

struct NotebookView: View {
    @StateObject private var viewModel: NotebookViewModel
    @StateObject private var appearance = AppearanceManager.shared
    @State private var showExportSheet = false
    @State private var showPageExportSheet = false
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

            // Page content — swipeable
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
            } else {
                pageSwipeContent
            }
        }
        .navigationTitle(viewModel.notebook.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Page navigation
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        #if os(iOS)
                        HapticService.selection()
                        #endif
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
                        #if os(iOS)
                        HapticService.selection()
                        #endif
                        viewModel.goToNextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.selectedPageIndex >= viewModel.pageCount - 1)
                }

                Menu {
                    Button {
                        #if os(iOS)
                        HapticService.medium()
                        #endif
                        Task { await viewModel.addPage() }
                    } label: {
                        Label("Blank Page", systemImage: "doc")
                    }

                    Button {
                        viewModel.showTemplateSheet = true
                    } label: {
                        Label("From Template...", systemImage: "doc.text")
                    }
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
                        showPageExportSheet = true
                    } label: {
                        Label("Export Page PDF", systemImage: "doc.richtext")
                    }
                    .disabled(viewModel.currentPage == nil)
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
        .sheet(isPresented: $viewModel.showTemplateSheet) {
            PageTemplateSheet { template in
                Task { await viewModel.addPage(template: template) }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showExportSheet) {
            let pdfData = viewModel.exportNotebookPDF()
            ShareSheet(items: [pdfData])
        }
        .sheet(isPresented: $showPageExportSheet) {
            if let pdfData = viewModel.exportCurrentPagePDF() {
                ShareSheet(items: [pdfData])
            }
        }
        #endif
        .onChange(of: viewModel.selectedPageIndex) { _, newIndex in
            #if os(iOS)
            HapticService.selection()
            #endif
            // Auto-create page when swiping to the "new page" placeholder
            if newIndex == viewModel.pages.count {
                Task {
                    #if os(iOS)
                    HapticService.medium()
                    #endif
                    await viewModel.addPage()
                }
            }
        }
        .onFirstAppear {
            await viewModel.loadNotebook()
        }
        .withErrorHandling()
    }

    // MARK: - Page Swipe Content

    @ViewBuilder
    private var pageSwipeContent: some View {
        let newPageIndex = viewModel.pages.count

        if appearance.pageSwipeDirection == .vertical {
            // Vertical paging using ScrollView
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        makePageView(page: page)
                            .containerRelativeFrame(.vertical)
                            .id(index)
                    }

                    // "New Page" placeholder at the end
                    newPagePlaceholder
                        .containerRelativeFrame(.vertical)
                        .id(newPageIndex)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding(
                get: { viewModel.selectedPageIndex as Int? },
                set: { newVal in
                    if let val = newVal {
                        viewModel.selectedPageIndex = val
                    }
                }
            ))
        } else {
            // Horizontal paging using TabView
            TabView(selection: $viewModel.selectedPageIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    makePageView(page: page)
                        .tag(index)
                }

                // "New Page" placeholder at the end
                newPagePlaceholder
                    .tag(newPageIndex)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private func makePageView(page: Page) -> PageView {
        var pageView = PageView(
            page: page,
            onSave: { updated in
                if let idx = viewModel.pages.firstIndex(where: { $0.id == updated.id }) {
                    viewModel.pages[idx] = updated
                }
            }
        )
        #if os(iOS)
        pageView.onHandwritingAction = { action, image in
            Task { await viewModel.handleHandwritingAction(action, image: image) }
        }
        #endif
        return pageView
    }

    private var newPagePlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.primaryFallback.opacity(0.4))

            Text("New Page")
                .font(.custom("Aptos-Bold", size: 18))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Swipe here to create a new page")
                .font(.custom("Aptos", size: 14))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.backgroundTertiary)
    }
}

#if os(iOS)
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
