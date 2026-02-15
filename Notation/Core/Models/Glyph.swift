import Foundation

struct Glyph: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var character: String
    var variationIndex: Int
    var strokeData: Data
    var imageUrl: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case character
        case variationIndex = "variation_index"
        case strokeData = "stroke_data"
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }

    static func new(userId: UUID, character: String, variationIndex: Int, strokeData: Data) -> Glyph {
        Glyph(
            id: UUID(),
            userId: userId,
            character: character,
            variationIndex: variationIndex,
            strokeData: strokeData,
            imageUrl: nil,
            createdAt: nil
        )
    }
}

struct GlyphSet {
    let character: String
    var variations: [Glyph]

    var hasVariations: Bool {
        !variations.isEmpty
    }

    func randomVariation() -> Glyph? {
        variations.randomElement()
    }
}
