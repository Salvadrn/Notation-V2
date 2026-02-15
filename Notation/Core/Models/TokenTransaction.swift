import Foundation

struct TokenTransaction: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var amount: Int
    var reason: String
    var referenceId: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case reason
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }

    var isCredit: Bool { amount > 0 }
    var isDebit: Bool { amount < 0 }

    static func credit(userId: UUID, amount: Int, reason: String, referenceId: String? = nil) -> TokenTransaction {
        TokenTransaction(
            id: UUID(),
            userId: userId,
            amount: abs(amount),
            reason: reason,
            referenceId: referenceId,
            createdAt: nil
        )
    }

    static func debit(userId: UUID, amount: Int, reason: String, referenceId: String? = nil) -> TokenTransaction {
        TokenTransaction(
            id: UUID(),
            userId: userId,
            amount: -abs(amount),
            reason: reason,
            referenceId: referenceId,
            createdAt: nil
        )
    }
}
