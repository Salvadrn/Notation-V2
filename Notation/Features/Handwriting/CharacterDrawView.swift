#if os(iOS)
import SwiftUI
import PencilKit

struct CharacterDrawView: View {
    let character: Character
    let existingVariations: [Glyph]
    let onSave: (Data, Data?) -> Void
    let onDelete: (Glyph) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    @State private var showVariations = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Reference character
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Draw:")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text(String(character))
                        .font(.custom("Aptos-Light", size: 60))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .fill(.white)

                    // Guide lines
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 1)
                        Spacer()
                            .frame(height: 40)
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                            .frame(height: 1)
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    DrawingCanvasRepresentable(canvasView: $canvasView)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                }
                .frame(width: 200, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Colors.separator, lineWidth: 1)
                )

                // Variations count
                HStack {
                    Text("Variations: \(existingVariations.count) / \(Constants.Handwriting.maxVariations)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Spacer()

                    if !existingVariations.isEmpty {
                        Button("View All") {
                            showVariations = true
                        }
                        .font(Theme.Typography.caption)
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)

                // Actions
                HStack(spacing: Theme.Spacing.lg) {
                    Button {
                        canvasView.drawing = PKDrawing()
                    } label: {
                        Label("Clear", systemImage: "arrow.counterclockwise")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }

                    Button {
                        saveCharacter()
                    } label: {
                        Label("Save Variation", systemImage: "checkmark")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.primaryFallback)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .disabled(canvasView.drawing.strokes.isEmpty)
                }
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("Draw \"\(String(character))\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showVariations) {
                CharacterPreviewView(
                    character: character,
                    variations: existingVariations,
                    onDelete: onDelete
                )
            }
        }
    }

    private func saveCharacter() {
        let drawingData = canvasView.drawing.dataRepresentation()

        // Render as image
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: 2.0
        )
        let imageData = image.pngData()

        onSave(drawingData, imageData)
        canvasView.drawing = PKDrawing()
    }
}

struct DrawingCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 4)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
#endif
