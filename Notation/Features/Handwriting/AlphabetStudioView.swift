#if os(iOS)
import SwiftUI

struct AlphabetStudioView: View {
    @StateObject private var viewModel = AlphabetStudioViewModel()
    @State private var appeared = false

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 90), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(AlphabetStudioViewModel.CharacterCategory.allCases, id: \.self) { category in
                        Button {
                            HapticService.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.selectedCategory = category
                            }
                        } label: {
                            Text(category.rawValue)
                                .font(.custom("Aptos-Bold", size: 14))
                                .foregroundStyle(
                                    viewModel.selectedCategory == category
                                        ? .white
                                        : Theme.Colors.textSecondary
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.selectedCategory == category
                                        ? Theme.Colors.primaryFallback
                                        : Theme.Colors.backgroundTertiary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, 14)
            }
            .background(Theme.Colors.backgroundSecondary)

            Divider()

            // Progress indicator with animated bar
            HStack(spacing: 8) {
                let total = viewModel.currentCharacters.count
                let drawn = viewModel.currentCharacters.filter { viewModel.hasGlyph(for: $0) }.count

                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text("\(drawn)/\(total) characters drawn")
                    .font(.custom("Aptos-Bold", size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                // Animated progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.backgroundTertiary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primaryFallback, Theme.Colors.primaryFallback.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: total > 0
                                    ? geo.size.width * CGFloat(drawn) / CGFloat(total)
                                    : 0,
                                height: 8
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: drawn)
                    }
                }
                .frame(width: 90, height: 8)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, 12)

            Divider()

            // Character grid with staggered animations
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                    ForEach(Array(viewModel.currentCharacters.enumerated()), id: \.element) { index, character in
                        CharacterCell(
                            character: character,
                            variationCount: viewModel.variationCount(for: character),
                            hasGlyph: viewModel.hasGlyph(for: character)
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .scaleEffect(appeared ? 1 : 0.85)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.7)
                                .delay(Double(index) * 0.02),
                            value: appeared
                        )
                        .onTapGesture {
                            HapticService.light()
                            viewModel.selectCharacter(character)
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
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
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
        .onChange(of: viewModel.selectedCategory) { _, _ in
            // Re-trigger stagger animation on category change
            appeared = false
            withAnimation {
                appeared = true
            }
        }
        .withErrorHandling()
    }
}

struct CharacterCell: View {
    let character: Character
    let variationCount: Int
    let hasGlyph: Bool

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        hasGlyph
                            ? Theme.Colors.primaryFallback.opacity(0.1)
                            : Theme.Colors.backgroundTertiary
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                hasGlyph
                                    ? Theme.Colors.primaryFallback.opacity(0.3)
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .frame(width: 68, height: 68)

                Text(String(character))
                    .font(.custom("Aptos-Bold", size: 30))
                    .foregroundStyle(
                        hasGlyph
                            ? Theme.Colors.textPrimary
                            : Theme.Colors.textSecondary
                    )

                if hasGlyph {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .offset(x: 24, y: -24)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})

            if hasGlyph {
                Text("\(variationCount) var")
                    .font(.custom("Aptos-Bold", size: 11))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }
}
#endif
