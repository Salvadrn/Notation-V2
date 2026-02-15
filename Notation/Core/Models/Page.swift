import Foundation

struct TextContent: Codable, Equatable {
    var blocks: [TextBlock]

    static let empty = TextContent(blocks: [])
}

struct TextBlock: Codable, Equatable, Identifiable {
    let id: UUID
    var text: String
    var style: TextBlockStyle

    static func paragraph(_ text: String = "") -> TextBlock {
        TextBlock(id: UUID(), text: text, style: .body)
    }

    static func heading(_ text: String) -> TextBlock {
        TextBlock(id: UUID(), text: text, style: .heading)
    }

    static func bullet(_ text: String) -> TextBlock {
        TextBlock(id: UUID(), text: text, style: .bullet)
    }
}

enum TextBlockStyle: String, Codable, Equatable {
    case heading
    case subheading
    case body
    case bullet
    case numbered
    case quote
    case code
}

struct Page: Codable, Identifiable, Equatable {
    let id: UUID
    let sectionId: UUID
    let userId: UUID
    var title: String
    var pageSize: PageSizeType
    var orientation: PageOrientation
    var textContent: TextContent
    var sortOrder: Int
    var version: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sectionId = "section_id"
        case userId = "user_id"
        case title
        case pageSize = "page_size"
        case orientation
        case textContent = "text_content"
        case sortOrder = "sort_order"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displaySize: CGSize {
        let base = Constants.PageSize.size(for: pageSize)
        switch orientation {
        case .portrait: return base
        case .landscape: return CGSize(width: base.height, height: base.width)
        }
    }

    static func new(sectionId: UUID, userId: UUID, sortOrder: Int = 0) -> Page {
        Page(
            id: UUID(),
            sectionId: sectionId,
            userId: userId,
            title: "",
            pageSize: .a4,
            orientation: .portrait,
            textContent: .empty,
            sortOrder: sortOrder,
            version: 1,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
