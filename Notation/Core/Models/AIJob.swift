import Foundation

enum AIInputType: String, Codable {
    case photo
    case pdf
    case image
}

enum AIJobStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

struct AIGeneratedNotes: Codable, Equatable {
    var title: String
    var summary: String
    var sections: [AISection]
    var keyDefinitions: [AIDefinition]
}

struct AISection: Codable, Equatable, Identifiable {
    let id: UUID
    var heading: String
    var bullets: [String]

    init(heading: String, bullets: [String]) {
        self.id = UUID()
        self.heading = heading
        self.bullets = bullets
    }
}

struct AIDefinition: Codable, Equatable, Identifiable {
    let id: UUID
    var term: String
    var definition: String

    init(term: String, definition: String) {
        self.id = UUID()
        self.term = term
        self.definition = definition
    }
}

struct AIJob: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var pageId: UUID?
    var inputType: AIInputType
    var inputUrl: String?
    var outputNotes: AIGeneratedNotes?
    var tokensUsed: Int
    var status: AIJobStatus
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pageId = "page_id"
        case inputType = "input_type"
        case inputUrl = "input_url"
        case outputNotes = "output_notes"
        case tokensUsed = "tokens_used"
        case status
        case createdAt = "created_at"
    }
}
