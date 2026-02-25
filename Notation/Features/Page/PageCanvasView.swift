import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PageCanvasView: View {
    @ObservedObject var viewModel: PageViewModel
    #if os(iOS)
    var onHandwritingAction: ((HandwritingAction, UIImage) -> Void)?
    #endif

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
            }

            // Convert to Handwriting button (Navy blue)
            #if os(iOS)
            convertButton
            #endif
        }
        .clipped()
        #if os(iOS)
        .sheet(isPresented: $viewModel.showHandwritingResult) {
            HandwritingResultView(
                textBlocks: viewModel.textBlocks,
                onAction: { action, image in
                    onHandwritingAction?(action, image)
                }
            )
        }
        #endif
    }

    #if os(iOS)
    private var convertButton: some View {
        Button {
            viewModel.showHandwritingResult = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Convert to My Handwriting")
                    .font(.custom("Aptos-Bold", size: 14))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(hex: "#1B2A4A"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color(hex: "#1B2A4A").opacity(0.4), radius: 8, y: 4)
        }
        .padding(20)
    }
    #endif
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
