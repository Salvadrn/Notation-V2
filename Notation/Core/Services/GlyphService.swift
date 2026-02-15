import Foundation
import Supabase

@MainActor
final class GlyphService {
    private let supabase: SupabaseService
    private let storageService: StorageService

    // In-memory cache of loaded glyphs grouped by character
    private var glyphCache: [String: [Glyph]] = [:]

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
        self.storageService = StorageService(supabase: supabase)
    }

    private var userId: UUID {
        get throws {
            guard let id = supabase.currentUserId else {
                throw NotationError.notAuthenticated
            }
            return id
        }
    }

    func fetchAllGlyphs() async throws -> [String: [Glyph]] {
        let uid = try userId
        let glyphs: [Glyph] = try await supabase.client
            .from("glyphs")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("character")
            .order("variation_index")
            .execute()
            .value

        var grouped: [String: [Glyph]] = [:]
        for glyph in glyphs {
            grouped[glyph.character, default: []].append(glyph)
        }
        glyphCache = grouped
        return grouped
    }

    func fetchGlyphs(for character: String) async throws -> [Glyph] {
        let uid = try userId
        let glyphs: [Glyph] = try await supabase.client
            .from("glyphs")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("character", value: character)
            .order("variation_index")
            .execute()
            .value
        glyphCache[character] = glyphs
        return glyphs
    }

    func saveGlyph(character: String, strokeData: Data, renderedImage: Data?) async throws -> Glyph {
        let uid = try userId
        let existingCount = (glyphCache[character] ?? []).count

        guard existingCount < Constants.Handwriting.maxVariations else {
            throw NotationError.freeTierLimit("Maximum \(Constants.Handwriting.maxVariations) variations per character")
        }

        var imageUrl: String?
        if let imageData = renderedImage {
            let fileName = "\(character.unicodeScalars.first?.value ?? 0)_\(existingCount).png"
            let path = try await storageService.uploadImage(
                bucket: AppConfig.glyphsBucket,
                data: imageData,
                fileName: fileName
            )
            imageUrl = path
        }

        let glyph = Glyph.new(
            userId: uid,
            character: character,
            variationIndex: existingCount,
            strokeData: strokeData
        )

        var glyphToInsert = glyph
        if let url = imageUrl {
            // We need a mutable copy with the imageUrl set
            glyphToInsert = Glyph(
                id: glyph.id,
                userId: glyph.userId,
                character: glyph.character,
                variationIndex: glyph.variationIndex,
                strokeData: glyph.strokeData,
                imageUrl: url,
                createdAt: glyph.createdAt
            )
        }

        try await supabase.client
            .from("glyphs")
            .insert(glyphToInsert)
            .execute()

        glyphCache[character, default: []].append(glyphToInsert)
        return glyphToInsert
    }

    func deleteGlyph(id: UUID, character: String) async throws {
        try await supabase.client
            .from("glyphs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        glyphCache[character]?.removeAll { $0.id == id }
    }

    func glyphSet(for character: String) -> GlyphSet {
        GlyphSet(character: character, variations: glyphCache[character] ?? [])
    }

    func randomGlyph(for character: String) -> Glyph? {
        glyphCache[character]?.randomElement()
    }

    var cachedGlyphs: [String: [Glyph]] {
        glyphCache
    }

    func hasGlyph(for character: String) -> Bool {
        !(glyphCache[character] ?? []).isEmpty
    }
}
