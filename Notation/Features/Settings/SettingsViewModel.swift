import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: Profile = .empty
    @Published var isLoading = false
    @Published var tokenBalance = 0
    @Published var showSubscription = false
    @Published var showTokenStore = false

    private let authService: AuthService
    private let tokenService: TokenService
    private let supabase = SupabaseService.shared

    private var isGuest: Bool { supabase.isGuestMode }

    init(authService: AuthService = AuthService(), tokenService: TokenService = TokenService()) {
        self.authService = authService
        self.tokenService = tokenService
    }

    func loadProfile() async {
        // In guest mode, don't call Supabase at all
        if isGuest {
            profile = Profile(
                id: supabase.currentUserId ?? UUID(),
                fullName: "Guest",
                avatarUrl: nil,
                subscriptionTier: .free,
                tokenBalance: 0,
                createdAt: nil,
                updatedAt: nil
            )
            tokenBalance = 0
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            profile = try await authService.fetchProfile()
            tokenBalance = try await tokenService.fetchBalance()
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func updateProfile(fullName: String) async {
        guard !isGuest else { return }
        var updated = profile
        updated.fullName = fullName
        do {
            try await authService.updateProfile(updated)
            profile = updated
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }

    func signOut() async {
        if isGuest {
            supabase.exitGuestMode()
            return
        }
        do {
            try await authService.signOut()
        } catch {
            ErrorHandler.shared.handle(error)
        }
    }
}
