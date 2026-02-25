import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

@MainActor
final class NotebookViewModel: ObservableObject {
    @Published var notebook: Notebook
    @Published var sections: [Section] = []
    @Published var pages: [Page] = []
    @Published var selectedSection: Section?
    @Published var selectedPageIndex: Int = 0
    @Published var isLoading = false
    @Published var showNewSection = false
    @Published var showTemplateSheet = false

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

    func addPage(template: PageTemplate = .blank) async {
        guard let section = selectedSection else { return }
        if isGuest {
            var page = localStorage.createPage(sectionId: section.id, sortOrder: pages.count)
            if template != .blank {
                page.textContent = template.textContent
                page.title = template.rawValue
                localStorage.updatePage(page)
            }
            pages.append(page)
            selectedPageIndex = pages.count - 1
        } else {
            do {
                var page = try await pageService.createPage(
                    sectionId: section.id,
                    sortOrder: pages.count
                )
                if template != .blank {
                    page.textContent = template.textContent
                    page.title = template.rawValue
                    try await pageService.updatePage(page)
                }
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

    // MARK: - Handwriting Actions

    #if os(iOS)
    func handleHandwritingAction(_ action: HandwritingAction, image: UIImage) async {
        switch action {
        case .insertNewPage:
            // Create a new page and set the handwriting image as a text block placeholder
            await addPage()
            // The image data will be stored — for now we note it in the page title
            if var page = currentPage {
                page.title = "Handwriting"
                if isGuest {
                    localStorage.updatePage(page)
                } else {
                    try? await pageService.updatePage(page)
                }
                if let idx = pages.firstIndex(where: { $0.id == page.id }) {
                    pages[idx] = page
                }
            }

        case .replaceInCurrentPage:
            // Replace current page text blocks — mark page as handwriting-converted
            guard var page = currentPage else { return }
            page.title = "Handwriting"
            // Clear existing text content since it's being replaced by the handwriting image
            page.textContent = TextContent(blocks: [TextBlock(id: UUID(), text: "[Handwriting converted]", style: .body)])
            if isGuest {
                localStorage.updatePage(page)
            } else {
                try? await pageService.updatePage(page)
            }
            if let idx = pages.firstIndex(where: { $0.id == page.id }) {
                pages[idx] = page
            }

        case .insertInCurrentPage:
            // Append a marker to the current page's text blocks
            guard var page = currentPage else { return }
            var blocks = page.textContent.blocks
            blocks.append(TextBlock(id: UUID(), text: "[Handwriting inserted]", style: .body))
            page.textContent = TextContent(blocks: blocks)
            if isGuest {
                localStorage.updatePage(page)
            } else {
                try? await pageService.updatePage(page)
            }
            if let idx = pages.firstIndex(where: { $0.id == page.id }) {
                pages[idx] = page
            }
        }
    }
    #endif

    // MARK: - Export

    func exportNotebookPDF() -> Data {
        pdfExporter.exportPages(pages, textContents: [:])
    }

    func exportCurrentPagePDF() -> Data? {
        guard let page = currentPage else { return nil }
        return pdfExporter.exportPage(page, textContent: nil)
    }
}
