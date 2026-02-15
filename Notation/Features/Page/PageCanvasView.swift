import SwiftUI

struct PageCanvasView: View {
    @ObservedObject var viewModel: PageViewModel

    var body: some View {
        ZStack {
            // Background with ruled lines
            RuledLinesBackground(pageSize: viewModel.page.displaySize)

            // Text layer
            if viewModel.textLayer?.isVisible != false {
                TextEditorView(viewModel: viewModel)
            }

            // Drawing layer (iPad only)
            #if os(iOS)
            if viewModel.drawingLayer?.isVisible != false,
               let drawingLayer = viewModel.drawingLayer {
                DrawingCanvasView(
                    layerId: drawingLayer.id,
                    initialData: drawingLayer.drawingData,
                    onDrawingChanged: { data in
                        Task { await viewModel.updateDrawingData(data) }
                    }
                )
                .allowsHitTesting(viewModel.isEditing == false)
            }
            #endif

            // Handwriting layer
            if viewModel.handwritingLayer?.isVisible != false {
                HandwritingRenderView(blocks: viewModel.textBlocks)
                    .allowsHitTesting(false)
            }
        }
        .clipped()
    }
}

struct RuledLinesBackground: View {
    let pageSize: CGSize
    let lineSpacing: CGFloat = 28
    let margin: CGFloat = 40

    var body: some View {
        Canvas { context, size in
            let startY: CGFloat = 60

            var y = startY
            while y < size.height - margin {
                let path = Path { p in
                    p.move(to: CGPoint(x: margin, y: y))
                    p.addLine(to: CGPoint(x: size.width - margin, y: y))
                }
                context.stroke(path, with: .color(.gray.opacity(0.15)), lineWidth: 0.5)
                y += lineSpacing
            }

            // Left margin line
            let marginPath = Path { p in
                p.move(to: CGPoint(x: margin - 2, y: 0))
                p.addLine(to: CGPoint(x: margin - 2, y: size.height))
            }
            context.stroke(marginPath, with: .color(.red.opacity(0.15)), lineWidth: 0.5)
        }
        .frame(width: pageSize.width, height: pageSize.height)
    }
}
