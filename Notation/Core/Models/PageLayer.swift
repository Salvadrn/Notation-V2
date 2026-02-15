import Foundation

enum LayerType: String, Codable, CaseIterable {
    case text
    case drawing
    case handwriting

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .drawing: return "Drawing"
        case .handwriting: return "Handwriting"
        }
    }

    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .drawing: return "pencil.tip"
        case .handwriting: return "hand.draw"
        }
    }
}

struct PageLayer: Codable, Identifiable, Equatable {
    let id: UUID
    let pageId: UUID
    let userId: UUID
    var layerType: LayerType
    var drawingData: Data?
    var isVisible: Bool
    var sortOrder: Int
    var version: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pageId = "page_id"
        case userId = "user_id"
        case layerType = "layer_type"
        case drawingData = "drawing_data"
        case isVisible = "is_visible"
        case sortOrder = "sort_order"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static func new(pageId: UUID, userId: UUID, type: LayerType, sortOrder: Int = 0) -> PageLayer {
        PageLayer(
            id: UUID(),
            pageId: pageId,
            userId: userId,
            layerType: type,
            drawingData: nil,
            isVisible: true,
            sortOrder: sortOrder,
            version: 1,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
