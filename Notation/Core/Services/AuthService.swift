import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    private let supabase: SupabaseService

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )

            // Create profile row
            let profile = Profile(
                id: response.user.id,
                fullName: fullName,
                avatarUrl: nil,
                subscriptionTier: .free,
                tokenBalance: Constants.Tokens.starterPackAmount,
                createdAt: nil,
                updatedAt: nil
            )

            try await supabase.client
                .from("profiles")
                .insert(profile)
                .execute()

        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.client.auth.signIn(
                email: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signOut() async throws {
        try await supabase.client.auth.signOut()
    }

    func fetchProfile() async throws -> Profile {
        guard let userId = supabase.currentUserId else {
            throw NotationError.notAuthenticated
        }

        let profile: Profile = try await supabase.client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }

    func updateProfile(_ profile: Profile) async throws {
        try await supabase.client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
    }
}

enum NotationError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case notFound
    case insufficientTokens
    case freeTierLimit(String)
    case networkError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .notAuthorized:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested item was not found."
        case .insufficientTokens:
            return "You don't have enough tokens. Please purchase more."
        case .freeTierLimit(let feature):
            return "You've reached the free tier limit for \(feature). Upgrade to Pro for unlimited access."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
