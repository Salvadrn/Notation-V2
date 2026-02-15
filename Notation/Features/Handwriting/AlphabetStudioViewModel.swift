#if os(iOS)
import SwiftUI
import PencilKit

@MainActor
final class AlphabetStudioViewModel: ObservableObject {
    @Published var glyphSets: [String: [Glyph]] = [:]
    @Published var selectedCategory: CharacterCategory = .uppercase
    @Published var selectedCharacter: Character?
    @Published var isLoading = false
    @Published var showCharacterDraw = false

    private let glyphService: GlyphService

    init(glyphService: GlyphService = GlyphService()) {
        self.glyphService = glyphService
    }

    enum CharacterCategory: String, CaseIterable {
        case uppercase = "A-Z"
        case lowercase = "a-z"
        case numbers = "0-9"
        case accented = "Accented"
        case punctuation = "Symbols"

        var characters: [Character] {
            switch self {
            case .uppercase: return Constants.uppercaseLetters
            case .lowercase: return Constants.lowercaseLetters
            case .numbers: return Constants.digits
            case .accented: return Constants.accentedCharacters
            case .punctuation: return Constants.punctuation
            }
        }
    }

    var currentCharacters: [Character] {
        selectedCategory.characters
    }

    func loadGlyphs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            glyphSets = try await glyphService.fetchAllGlyphs()
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func variationCount(for character: Character) -> Int {
        glyphSets[String(character)]?.count ?? 0
    }

    func hasGlyph(for character: Character) -> Bool {
        variationCount(for: character) > 0
    }

    func saveGlyph(character: String, drawingData: Data, renderedImage: Data?) async {
        do {
            let glyph = try await glyphService.saveGlyph(
                character: character,
                strokeData: drawingData,
                renderedImage: renderedImage
            )
            glyphSets[character, default: []].append(glyph)
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func deleteGlyph(_ glyph: Glyph) async {
        do {
            try await glyphService.deleteGlyph(id: glyph.id, character: glyph.character)
            glyphSets[glyph.character]?.removeAll { $0.id == glyph.id }
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func selectCharacter(_ char: Character) {
        selectedCharacter = char
        showCharacterDraw = true
    }
}
#endif
