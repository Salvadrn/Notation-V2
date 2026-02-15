#if os(iOS)
import SwiftUI
import PencilKit

@MainActor
final class DrawingViewModel: ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published var selectedTool: DrawingTool = .pen
    @Published var selectedColor: Color = .black
    @Published var strokeWidth: CGFloat = 3.0
    @Published var isToolPickerVisible = false

    enum DrawingTool: String, CaseIterable {
        case pen
        case pencil
        case marker
        case eraser

        var displayName: String {
            rawValue.capitalized
        }

        var iconName: String {
            switch self {
            case .pen: return "pencil.tip"
            case .pencil: return "pencil"
            case .marker: return "highlighter"
            case .eraser: return "eraser"
            }
        }
    }

    func updateTool() {
        let uiColor = UIColor(selectedColor)

        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: strokeWidth)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: uiColor, width: strokeWidth)
        case .marker:
            canvasView.tool = PKInkingTool(.marker, color: uiColor, width: strokeWidth * 3)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        }
    }

    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }

    func undoLastStroke() {
        canvasView.undoManager?.undo()
    }

    func redoLastStroke() {
        canvasView.undoManager?.redo()
    }

    func getDrawingData() -> Data {
        canvasView.drawing.dataRepresentation()
    }

    func loadDrawingData(_ data: Data) {
        do {
            let drawing = try PKDrawing(data: data)
            canvasView.drawing = drawing
        } catch {
            print("Failed to load drawing: \(error)")
        }
    }
}
#endif
