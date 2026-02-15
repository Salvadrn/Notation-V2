#if os(iOS)
import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    let layerId: UUID
    let initialData: Data?
    let onDrawingChanged: (Data) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .pencilOnly
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)

        // Allow finger drawing as fallback
        canvasView.drawingPolicy = .anyInput

        // Load initial drawing data
        if let data = initialData {
            do {
                canvasView.drawing = try PKDrawing(data: data)
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: (Data) -> Void
        private var debounceTask: Task<Void, Never>?

        init(onDrawingChanged: @escaping (Data) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                let data = canvasView.drawing.dataRepresentation()
                onDrawingChanged(data)
            }
        }
    }
}
#endif
