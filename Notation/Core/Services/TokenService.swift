import Foundation
import Supabase

private struct IncrementTokenParams: Encodable {
    let user_id_input: String
    let amount_input: Int
}

@MainActor
final class TokenService {
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

    func fetchBalance() async throws -> Int {
        let uid = try userId
        let profile: Profile = try await supabase.client
            .from("profiles")
            .select("token_balance")
            .eq("id", value: uid.uuidString)
            .single()
            .execute()
            .value
        return profile.tokenBalance
    }

    func hasEnoughTokens(for cost: Int) async throws -> Bool {
        let balance = try await fetchBalance()
        return balance >= cost
    }

    func addTokens(amount: Int, reason: String, referenceId: String? = nil) async throws {
        let uid = try userId

        // Record transaction
        let transaction = TokenTransaction.credit(
            userId: uid,
            amount: amount,
            reason: reason,
            referenceId: referenceId
        )

        try await supabase.client
            .from("token_transactions")
            .insert(transaction)
            .execute()

        // Update balance
        try await supabase.client.rpc(
            "increment_token_balance",
            params: IncrementTokenParams(user_id_input: uid.uuidString, amount_input: amount)
        ).execute()
    }

    func deductTokens(amount: Int, reason: String, referenceId: String? = nil) async throws {
        let uid = try userId
        let balance = try await fetchBalance()

        guard balance >= amount else {
            throw NotationError.insufficientTokens
        }

        // Record transaction
        let transaction = TokenTransaction.debit(
            userId: uid,
            amount: amount,
            reason: reason,
            referenceId: referenceId
        )

        try await supabase.client
            .from("token_transactions")
            .insert(transaction)
            .execute()

        // Update balance
        try await supabase.client.rpc(
            "increment_token_balance",
            params: IncrementTokenParams(user_id_input: uid.uuidString, amount_input: -amount)
        ).execute()
    }

    func fetchTransactionHistory() async throws -> [TokenTransaction] {
        let uid = try userId
        let transactions: [TokenTransaction] = try await supabase.client
            .from("token_transactions")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return transactions
    }
}
