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

    func signInWithApple(idToken: String, fullName: PersonNameComponents?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )

            // On first sign-in, Apple provides the user's name.
            // Save it to user metadata and create the profile row.
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            if !displayName.isEmpty {
                try await supabase.client.auth.update(
                    user: UserAttributes(data: ["full_name": .string(displayName)])
                )
            }

            // Upsert profile so it exists for both new and returning users
            let profile = Profile(
                id: session.user.id,
                fullName: displayName.isEmpty ? nil : displayName,
                avatarUrl: nil,
                subscriptionTier: .free,
                tokenBalance: Constants.Tokens.starterPackAmount,
                createdAt: nil,
                updatedAt: nil
            )

            try await supabase.client
                .from("profiles")
                .upsert(profile, onConflict: "id", ignoreDuplicates: true)
                .execute()

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
