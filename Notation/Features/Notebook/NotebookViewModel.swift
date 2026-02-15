import SwiftUI
import Combine

@MainActor
final class NotebookViewModel: ObservableObject {
    @Published var notebook: Notebook
    @Published var sections: [Section] = []
    @Published var pages: [Page] = []
    @Published var selectedSection: Section?
    @Published var selectedPageIndex: Int = 0
    @Published var isLoading = false
    @Published var showNewSection = false

    private let sectionService: SectionService
    private let pageService: PageService
    private let pdfExporter = PDFExporter()

    init(notebook: Notebook) {
        self.notebook = notebook
        self.sectionService = SectionService()
        self.pageService = PageService()
    }

    var currentPage: Page? {
        guard selectedPageIndex >= 0 && selectedPageIndex < pages.count else { return nil }
        return pages[selectedPageIndex]
    }

    var pageCount: Int { pages.count }

    // MARK: - Load

    func loadNotebook() async {
        isLoading = true
        defer { isLoading = false }

        do {
            sections = try await sectionService.fetchSections(notebookId: notebook.id)
            if selectedSection == nil {
                selectedSection = sections.first
            }
            if let section = selectedSection {
                pages = try await pageService.fetchPages(sectionId: section.id)
            }
        } catch {
            ErrorHandler.shared.handle(error, title: "Failed to load notebook") {
                await self.loadNotebook()
            }
        }
    }

    func selectSection(_ section: Section) async {
        selectedSection = section
        selectedPageIndex = 0
        do {
            pages = try await pageService.fetchPages(sectionId: section.id)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    // MARK: - Section Operations

    func createSection(title: String) async {
        do {
            let section = try await sectionService.createSection(
                notebookId: notebook.id,
                title: title
            )
            sections.append(section)
            await selectSection(section)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func renameSection(_ section: Section, to title: String) async {
        var updated = section
        updated.title = title
        do {
            try await sectionService.updateSection(updated)
            if let index = sections.firstIndex(where: { $0.id == section.id }) {
                sections[index] = updated
            }
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func deleteSection(_ section: Section) async {
        do {
            try await sectionService.deleteSection(id: section.id)
            sections.removeAll { $0.id == section.id }
            if selectedSection?.id == section.id {
                selectedSection = sections.first
                if let next = selectedSection {
                    await selectSection(next)
                } else {
                    pages = []
                }
            }
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    // MARK: - Page Operations

    func addPage() async {
        guard let section = selectedSection else { return }
        do {
            let page = try await pageService.createPage(
                sectionId: section.id,
                sortOrder: pages.count
            )
            pages.append(page)
            selectedPageIndex = pages.count - 1
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func deletePage(_ page: Page) async {
        do {
            try await pageService.deletePage(id: page.id)
            pages.removeAll { $0.id == page.id }
            if selectedPageIndex >= pages.count {
                selectedPageIndex = max(0, pages.count - 1)
            }
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func goToNextPage() {
        if selectedPageIndex < pages.count - 1 {
            selectedPageIndex += 1
        }
    }

    func goToPreviousPage() {
        if selectedPageIndex > 0 {
            selectedPageIndex -= 1
        }
    }

    // MARK: - Export

    func exportNotebookPDF() -> Data {
        pdfExporter.exportPages(pages, textContents: [:])
    }

    func exportCurrentPagePDF() -> Data? {
        guard let page = currentPage else { return nil }
        return pdfExporter.exportPage(page, textContent: nil)
    }
}
