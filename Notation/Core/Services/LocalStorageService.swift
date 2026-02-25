import Foundation

@MainActor
final class LocalStorageService: ObservableObject {
    static let shared = LocalStorageService()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var baseURL: URL {
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Documents directory unavailable")
        }
        let dir = docs.appendingPathComponent("NotationLocal", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Guest User ID

    private let guestUserIdKey = "notation_guest_user_id"

    var guestUserId: UUID {
        if let stored = UserDefaults.standard.string(forKey: guestUserIdKey),
           let uuid = UUID(uuidString: stored) {
            return uuid
        }
        let newId = UUID()
        UserDefaults.standard.set(newId.uuidString, forKey: guestUserIdKey)
        return newId
    }

    // MARK: - Folders

    private var foldersURL: URL { baseURL.appendingPathComponent("folders.json") }

    func fetchFolders() -> [Folder] {
        load(from: foldersURL) ?? []
    }

    func saveFolders(_ folders: [Folder]) {
        save(folders, to: foldersURL)
    }

    func createFolder(name: String, parentId: UUID?, parentPath: String) -> Folder {
        var folders = fetchFolders()
        let folder = Folder.new(userId: guestUserId, name: name, parentId: parentId, parentPath: parentPath)
        folders.append(folder)
        saveFolders(folders)
        return folder
    }

    func deleteFolder(id: UUID) {
        var folders = fetchFolders()
        folders.removeAll { $0.id == id }
        saveFolders(folders)
    }

    func updateFolder(_ folder: Folder) {
        var folders = fetchFolders()
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
        }
        saveFolders(folders)
    }

    // MARK: - Notebooks

    private var notebooksURL: URL { baseURL.appendingPathComponent("notebooks.json") }

    func fetchNotebooks(folderId: UUID?) -> [Notebook] {
        let all: [Notebook] = load(from: notebooksURL) ?? []
        if let folderId {
            return all.filter { $0.folderId == folderId }
        }
        return all.filter { $0.folderId == nil }
    }

    func fetchAllNotebooks() -> [Notebook] {
        load(from: notebooksURL) ?? []
    }

    func createNotebook(title: String, folderId: UUID?) -> Notebook {
        var notebooks = fetchAllNotebooks()
        let notebook = Notebook.new(userId: guestUserId, folderId: folderId, title: title)
        notebooks.append(notebook)
        save(notebooks, to: notebooksURL)
        return notebook
    }

    func updateNotebook(_ notebook: Notebook) {
        var notebooks = fetchAllNotebooks()
        if let index = notebooks.firstIndex(where: { $0.id == notebook.id }) {
            notebooks[index] = notebook
        }
        save(notebooks, to: notebooksURL)
    }

    func deleteNotebook(id: UUID) {
        var notebooks = fetchAllNotebooks()
        notebooks.removeAll { $0.id == id }
        save(notebooks, to: notebooksURL)
        // Also delete related sections and pages
        deleteSectionsForNotebook(id)
    }

    func notebookCount() -> Int {
        fetchAllNotebooks().count
    }

    // MARK: - Sections

    private var sectionsURL: URL { baseURL.appendingPathComponent("sections.json") }

    func fetchSections(notebookId: UUID) -> [Section] {
        let all: [Section] = load(from: sectionsURL) ?? []
        return all.filter { $0.notebookId == notebookId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func createSection(notebookId: UUID, title: String) -> Section {
        var sections: [Section] = load(from: sectionsURL) ?? []
        let existing = sections.filter { $0.notebookId == notebookId }
        let section = Section(
            id: UUID(),
            notebookId: notebookId,
            userId: guestUserId,
            title: title,
            sortOrder: existing.count,
            createdAt: Date(),
            updatedAt: Date()
        )
        sections.append(section)
        save(sections, to: sectionsURL)
        return section
    }

    func updateSection(_ section: Section) {
        var sections: [Section] = load(from: sectionsURL) ?? []
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            sections[index] = section
        }
        save(sections, to: sectionsURL)
    }

    func deleteSection(id: UUID) {
        var sections: [Section] = load(from: sectionsURL) ?? []
        sections.removeAll { $0.id == id }
        save(sections, to: sectionsURL)
        deletePagesForSection(id)
    }

    private func deleteSectionsForNotebook(_ notebookId: UUID) {
        var sections: [Section] = load(from: sectionsURL) ?? []
        let toDelete = sections.filter { $0.notebookId == notebookId }
        for section in toDelete {
            deletePagesForSection(section.id)
        }
        sections.removeAll { $0.notebookId == notebookId }
        save(sections, to: sectionsURL)
    }

    // MARK: - Pages

    private var pagesURL: URL { baseURL.appendingPathComponent("pages.json") }

    func fetchPages(sectionId: UUID) -> [Page] {
        let all: [Page] = load(from: pagesURL) ?? []
        return all.filter { $0.sectionId == sectionId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func createPage(sectionId: UUID, sortOrder: Int) -> Page {
        var pages: [Page] = load(from: pagesURL) ?? []
        let page = Page.new(sectionId: sectionId, userId: guestUserId, sortOrder: sortOrder)
        pages.append(page)
        save(pages, to: pagesURL)
        return page
    }

    func updatePage(_ page: Page) {
        var pages: [Page] = load(from: pagesURL) ?? []
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages[index] = page
        } else {
            pages.append(page)
        }
        save(pages, to: pagesURL)
    }

    func deletePage(id: UUID) {
        var pages: [Page] = load(from: pagesURL) ?? []
        pages.removeAll { $0.id == id }
        save(pages, to: pagesURL)
    }

    private func deletePagesForSection(_ sectionId: UUID) {
        var pages: [Page] = load(from: pagesURL) ?? []
        pages.removeAll { $0.sectionId == sectionId }
        save(pages, to: pagesURL)
    }

    // MARK: - Layers

    private var layersURL: URL { baseURL.appendingPathComponent("layers.json") }

    func fetchLayers(pageId: UUID) -> [PageLayer] {
        let all: [PageLayer] = load(from: layersURL) ?? []
        return all.filter { $0.pageId == pageId }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func ensureDefaultLayers(pageId: UUID) -> [PageLayer] {
        let existing = fetchLayers(pageId: pageId)
        if !existing.isEmpty { return existing }

        var allLayers: [PageLayer] = load(from: layersURL) ?? []
        var created: [PageLayer] = []
        for (index, type) in [LayerType.text, .drawing, .handwriting].enumerated() {
            let layer = PageLayer.new(pageId: pageId, userId: guestUserId, type: type, sortOrder: index)
            allLayers.append(layer)
            created.append(layer)
        }
        save(allLayers, to: layersURL)
        return created
    }

    func toggleLayerVisibility(layerId: UUID, isVisible: Bool) {
        var layers: [PageLayer] = load(from: layersURL) ?? []
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isVisible = isVisible
        }
        save(layers, to: layersURL)
    }

    func updateDrawingData(layerId: UUID, data: Data) {
        var layers: [PageLayer] = load(from: layersURL) ?? []
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].drawingData = data
        }
        save(layers, to: layersURL)
    }

    // MARK: - Glyphs

    private var glyphsURL: URL { baseURL.appendingPathComponent("glyphs.json") }

    func fetchAllGlyphs() -> [String: [Glyph]] {
        let all: [Glyph] = load(from: glyphsURL) ?? []
        var grouped: [String: [Glyph]] = [:]
        for glyph in all {
            grouped[glyph.character, default: []].append(glyph)
        }
        return grouped
    }

    func fetchGlyphs(for character: String) -> [Glyph] {
        let all: [Glyph] = load(from: glyphsURL) ?? []
        return all.filter { $0.character == character }.sorted { $0.variationIndex < $1.variationIndex }
    }

    func saveGlyph(_ glyph: Glyph) {
        var all: [Glyph] = load(from: glyphsURL) ?? []
        all.append(glyph)
        save(all, to: glyphsURL)
    }

    func deleteGlyph(id: UUID) {
        var all: [Glyph] = load(from: glyphsURL) ?? []
        all.removeAll { $0.id == id }
        save(all, to: glyphsURL)
    }

    // MARK: - Generic JSON Helpers

    private func load<T: Decodable>(from url: URL) -> T? {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            // File doesn't exist yet — normal for first launch
            return nil
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[LocalStorage] Failed to decode \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[LocalStorage] Failed to save \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
