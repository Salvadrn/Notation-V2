import Foundation
import Supabase

@MainActor
final class LayerService {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    private var userId: UUID {
        get throws {
            guard let id = supabase.currentUserId else {
                throw NotationError.notAuthenticated
            }
            return id
        }
    }

    func fetchLayers(pageId: UUID) async throws -> [PageLayer] {
        let layers: [PageLayer] = try await supabase.client
            .from("page_layers")
            .select()
            .eq("page_id", value: pageId.uuidString)
            .order("sort_order")
            .execute()
            .value
        return layers
    }

    func createLayer(pageId: UUID, type: LayerType, sortOrder: Int = 0) async throws -> PageLayer {
        let uid = try userId
        let layer = PageLayer.new(pageId: pageId, userId: uid, type: type, sortOrder: sortOrder)
        try await supabase.client
            .from("page_layers")
            .insert(layer)
            .execute()
        return layer
    }

    func updateLayer(_ layer: PageLayer) async throws {
        var updated = layer
        updated.version += 1
        try await supabase.client
            .from("page_layers")
            .update(updated)
            .eq("id", value: layer.id.uuidString)
            .execute()
    }

    func deleteLayer(id: UUID) async throws {
        try await supabase.client
            .from("page_layers")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func toggleVisibility(layerId: UUID, isVisible: Bool) async throws {
        struct VisibilityUpdate: Encodable {
            let isVisible: Bool
            enum CodingKeys: String, CodingKey {
                case isVisible = "is_visible"
            }
        }

        try await supabase.client
            .from("page_layers")
            .update(VisibilityUpdate(isVisible: isVisible))
            .eq("id", value: layerId.uuidString)
            .execute()
    }

    func updateDrawingData(layerId: UUID, data: Data) async throws {
        struct DrawingUpdate: Encodable {
            let drawingData: Data
            enum CodingKeys: String, CodingKey {
                case drawingData = "drawing_data"
            }
        }

        try await supabase.client
            .from("page_layers")
            .update(DrawingUpdate(drawingData: data))
            .eq("id", value: layerId.uuidString)
            .execute()
    }

    func ensureDefaultLayers(pageId: UUID) async throws -> [PageLayer] {
        let existing = try await fetchLayers(pageId: pageId)
        if !existing.isEmpty { return existing }

        let uid = try userId
        var layers: [PageLayer] = []

        for (index, type) in [LayerType.text, .drawing, .handwriting].enumerated() {
            let layer = PageLayer.new(pageId: pageId, userId: uid, type: type, sortOrder: index)
            try await supabase.client
                .from("page_layers")
                .insert(layer)
                .execute()
            layers.append(layer)
        }

        return layers
    }
}
