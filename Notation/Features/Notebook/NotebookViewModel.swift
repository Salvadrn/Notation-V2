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
    private let localStorage = LocalStorageService.shared
    private let supabase = SupabaseService.shared
    private let pdfExporter = PDFExporter()

    init(notebook: Notebook) {
        self.notebook = notebook
        self.sectionService = SectionService()
        self.pageService = PageService()
    }

    private var isGuest: Bool { supabase.isGuestMode }

    var currentPage: Page? {
        guard selectedPageIndex >= 0 && selectedPageIndex < pages.count else { return nil }
        return pages[selectedPageIndex]
    }

    var pageCount: Int { pages.count }

    // MARK: - Load

    func loadNotebook() async {
        isLoading = true
        defer { isLoading = false }

        if isGuest {
            sections = localStorage.fetchSections(notebookId: notebook.id)
            if selectedSection == nil {
                selectedSection = sections.first
            }
            // Auto-create a default section if none exist
            if sections.isEmpty {
                let section = localStorage.createSection(notebookId: notebook.id, title: "Section 1")
                sections = [section]
                selectedSection = section
            }
            if let section = selectedSection {
                pages = localStorage.fetchPages(sectionId: section.id)
                // Auto-create first page
                if pages.isEmpty {
                    let page = localStorage.createPage(sectionId: section.id, sortOrder: 0)
                    pages = [page]
                }
            }
        } else {
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
    }

    func selectSection(_ section: Section) async {
        selectedSection = section
        selectedPageIndex = 0
        if isGuest {
            pages = localStorage.fetchPages(sectionId: section.id)
            if pages.isEmpty {
                let page = localStorage.createPage(sectionId: section.id, sortOrder: 0)
                pages = [page]
            }
        } else {
            do {
                pages = try await pageService.fetchPages(sectionId: section.id)
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }

    // MARK: - Section Operations

    func createSection(title: String) async {
        if isGuest {
            let section = localStorage.createSection(notebookId: notebook.id, title: title)
            sections.append(section)
            await selectSection(section)
        } else {
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
    }

    func renameSection(_ section: Section, to title: String) async {
        var updated = section
        updated.title = title
        if isGuest {
            localStorage.updateSection(updated)
        } else {
            do {
                try await sectionService.updateSection(updated)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            sections[index] = updated
        }
    }

    func deleteSection(_ section: Section) async {
        if isGuest {
            localStorage.deleteSection(id: section.id)
        } else {
            do {
                try await sectionService.deleteSection(id: section.id)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        sections.removeAll { $0.id == section.id }
        if selectedSection?.id == section.id {
            selectedSection = sections.first
            if let next = selectedSection {
                await selectSection(next)
            } else {
                pages = []
            }
        }
    }

    // MARK: - Page Operations

    func addPage() async {
        guard let section = selectedSection else { return }
        if isGuest {
            let page = localStorage.createPage(sectionId: section.id, sortOrder: pages.count)
            pages.append(page)
            selectedPageIndex = pages.count - 1
        } else {
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
    }

    func deletePage(_ page: Page) async {
        if isGuest {
            localStorage.deletePage(id: page.id)
        } else {
            do {
                try await pageService.deletePage(id: page.id)
            } catch {
                ErrorHandler.shared.handle(error)
                return
            }
        }
        pages.removeAll { $0.id == page.id }
        if selectedPageIndex >= pages.count {
            selectedPageIndex = max(0, pages.count - 1)
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
