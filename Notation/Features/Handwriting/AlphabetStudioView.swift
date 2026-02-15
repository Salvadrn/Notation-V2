#if os(iOS)
import SwiftUI

struct AlphabetStudioView: View {
    @StateObject private var viewModel = AlphabetStudioViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: Theme.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(AlphabetStudioViewModel.CharacterCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(Theme.Animation.quick) {
                                viewModel.selectedCategory = category
                            }
                        } label: {
                            Text(category.rawValue)
                                .font(Theme.Typography.subheadline)
                                .fontWeight(viewModel.selectedCategory == category ? .semibold : .regular)
                                .foregroundStyle(
                                    viewModel.selectedCategory == category
                                        ? Theme.Colors.primaryFallback
                                        : Theme.Colors.textSecondary
                                )
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(
                                    viewModel.selectedCategory == category
                                        ? Theme.Colors.primaryFallback.opacity(0.1)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.backgroundSecondary)

            Divider()

            // Character grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(viewModel.currentCharacters, id: \.self) { character in
                        CharacterCell(
                            character: character,
                            variationCount: viewModel.variationCount(for: character),
                            hasGlyph: viewModel.hasGlyph(for: character)
                        )
                        .onTapGesture {
                            viewModel.selectCharacter(character)
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle("My Alphabet Studio")
        .sheet(isPresented: $viewModel.showCharacterDraw) {
            if let character = viewModel.selectedCharacter {
                CharacterDrawView(
                    character: character,
                    existingVariations: viewModel.glyphSets[String(character)] ?? [],
                    onSave: { drawingData, image in
                        Task {
                            await viewModel.saveGlyph(
                                character: String(character),
                                drawingData: drawingData,
                                renderedImage: image
                            )
                        }
                    },
                    onDelete: { glyph in
                        Task { await viewModel.deleteGlyph(glyph) }
                    }
                )
            }
        }
        .onFirstAppear {
            await viewModel.loadGlyphs()
        }
        .withErrorHandling()
    }
}

struct CharacterCell: View {
    let character: Character
    let variationCount: Int
    let hasGlyph: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(
                        hasGlyph
                            ? Theme.Colors.success.opacity(0.1)
                            : Theme.Colors.backgroundTertiary
                    )
                    .frame(width: 60, height: 60)

                Text(String(character))
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        hasGlyph
                            ? Theme.Colors.success
                            : Theme.Colors.textSecondary
                    )
            }

            if hasGlyph {
                Text("\(variationCount)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }
}
#endif
