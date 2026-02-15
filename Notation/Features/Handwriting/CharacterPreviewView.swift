#if os(iOS)
import SwiftUI
import PencilKit

struct CharacterPreviewView: View {
    let character: Character
    let variations: [Glyph]
    let onDelete: (Glyph) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if variations.isEmpty {
                    EmptyStateView(
                        icon: "hand.draw",
                        title: "No Variations",
                        subtitle: "Draw this character to create variations"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                        ForEach(Array(variations.enumerated()), id: \.element.id) { index, glyph in
                            VStack(spacing: Theme.Spacing.sm) {
                                // Render the glyph from PKDrawing data
                                GlyphPreview(strokeData: glyph.strokeData)
                                    .frame(width: 80, height: 80)
                                    .background(Theme.Colors.backgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))

                                Text("Variation \(index + 1)")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onDelete(glyph)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Variations: \"\(String(character))\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct GlyphPreview: View {
    let strokeData: Data

    var body: some View {
        GeometryReader { geometry in
            if let drawing = try? PKDrawing(data: strokeData) {
                let image = drawing.image(from: drawing.bounds, scale: 2.0)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                Image(systemName: "questionmark")
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }
}
#endif
