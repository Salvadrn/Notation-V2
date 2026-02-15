import SwiftUI
import Combine

@MainActor
final class PageViewModel: ObservableObject {
    @Published var page: Page
    @Published var layers: [PageLayer] = []
    @Published var textBlocks: [TextBlock] = []
    @Published var selectedBlockId: UUID?
    @Published var isEditing = false
    @Published var showLayerManager = false
    @Published var showSizePicker = false
    @Published var isSaving = false

    private let pageService: PageService
    private let layerService: LayerService
    let onSave: (Page) -> Void

    private var autosaveTask: Task<Void, Never>?

    init(page: Page, onSave: @escaping (Page) -> Void) {
        self.page = page
        self.textBlocks = page.textContent.blocks
        self.onSave = onSave
        self.pageService = PageService()
        self.layerService = LayerService()
    }

    var textLayer: PageLayer? {
        layers.first { $0.layerType == .text }
    }

    var drawingLayer: PageLayer? {
        layers.first { $0.layerType == .drawing }
    }

    var handwritingLayer: PageLayer? {
        layers.first { $0.layerType == .handwriting }
    }

    // MARK: - Load

    func loadLayers() async {
        do {
            layers = try await layerService.ensureDefaultLayers(pageId: page.id)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    // MARK: - Text Editing

    func addBlock(style: TextBlockStyle = .body, after blockId: UUID? = nil) {
        let newBlock = TextBlock(id: UUID(), text: "", style: style)

        if let afterId = blockId,
           let index = textBlocks.firstIndex(where: { $0.id == afterId }) {
            textBlocks.insert(newBlock, at: index + 1)
        } else {
            textBlocks.append(newBlock)
        }

        selectedBlockId = newBlock.id
        scheduleAutosave()
    }

    func updateBlock(id: UUID, text: String) {
        if let index = textBlocks.firstIndex(where: { $0.id == id }) {
            textBlocks[index].text = text
            scheduleAutosave()
        }
    }

    func updateBlockStyle(id: UUID, style: TextBlockStyle) {
        if let index = textBlocks.firstIndex(where: { $0.id == id }) {
            textBlocks[index].style = style
            scheduleAutosave()
        }
    }

    func deleteBlock(id: UUID) {
        textBlocks.removeAll { $0.id == id }
        if selectedBlockId == id {
            selectedBlockId = textBlocks.last?.id
        }
        scheduleAutosave()
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        textBlocks.move(fromOffsets: source, toOffset: destination)
        scheduleAutosave()
    }

    // MARK: - Page Settings

    func updatePageSize(_ size: PageSizeType) {
        page.pageSize = size
        scheduleAutosave()
    }

    func updateOrientation(_ orientation: PageOrientation) {
        page.orientation = orientation
        scheduleAutosave()
    }

    // MARK: - Layer Visibility

    func toggleLayerVisibility(_ layer: PageLayer) async {
        do {
            let newVisibility = !layer.isVisible
            try await layerService.toggleVisibility(layerId: layer.id, isVisible: newVisibility)
            if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                layers[index].isVisible = newVisibility
            }
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        defer { isSaving = false }

        page.textContent = TextContent(blocks: textBlocks)
        do {
            try await pageService.updatePage(page)
            onSave(page)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(for: .seconds(Constants.Autosave.debounceInterval))
            guard !Task.isCancelled else { return }
            await save()
        }
    }

    func flushSave() async {
        autosaveTask?.cancel()
        await save()
    }

    // MARK: - Drawing Data

    func updateDrawingData(_ data: Data) async {
        guard let layer = drawingLayer else { return }
        do {
            try await layerService.updateDrawingData(layerId: layer.id, data: data)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }
}
