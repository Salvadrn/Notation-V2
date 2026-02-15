import Foundation

enum SubscriptionTier: String, Codable {
    case free
    case pro
}

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var fullName: String?
    var avatarUrl: String?
    var subscriptionTier: SubscriptionTier
    var tokenBalance: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case subscriptionTier = "subscription_tier"
        case tokenBalance = "token_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isPro: Bool {
        subscriptionTier == .pro
    }

    static let empty = Profile(
        id: UUID(),
        fullName: nil,
        avatarUrl: nil,
        subscriptionTier: .free,
        tokenBalance: 0,
        createdAt: nil,
        updatedAt: nil
    )
}
