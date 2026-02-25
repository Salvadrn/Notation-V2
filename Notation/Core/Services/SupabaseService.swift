import Foundation
import Supabase

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUserId: UUID?
    @Published var isAuthenticated = false
    @Published var isGuestMode = false
    @Published var hasCompletedOnboarding = false

    private static let guestModeKey = "notation_is_guest_mode"
    private static let onboardingKey = "notation_has_completed_onboarding"

    private init() {
        let url = AppConfig.supabaseURL
        let key = AppConfig.supabaseAnonKey
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        // Restore onboarding state
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)

        // Don't auto-restore guest mode — always show LoginView on fresh launch
        // unless there's a real Supabase session. Guest mode activates when user
        // taps "Start Writing" on the login screen.
        // Local data is preserved regardless.
    }

    var isSupabaseConfigured: Bool {
        !AppConfig.supabaseAnonKey.hasPrefix("YOUR_")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
    }

    func restoreSession() async {
        if isGuestMode { return }
        guard isSupabaseConfigured else { return }

        do {
            let session = try await withThrowingTaskGroup(of: Session.self) { group in
                group.addTask {
                    try await self.client.auth.session
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(5))
                    throw CancellationError()
                }
                guard let result = try await group.next() else {
                    throw CancellationError()
                }
                group.cancelAll()
                return result
            }
            self.currentUserId = session.user.id
            self.isAuthenticated = true
        } catch {
            self.currentUserId = nil
            self.isAuthenticated = false
        }
    }

    func observeAuthChanges() {
        guard isSupabaseConfigured, !isGuestMode else { return }

        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        self.currentUserId = session?.user.id
                        self.isAuthenticated = true
                    case .signedOut:
                        self.currentUserId = nil
                        self.isAuthenticated = false
                    default:
                        break
                    }
                }
            }
        }
    }

    func enterGuestMode() {
        isGuestMode = true
        isAuthenticated = true
        currentUserId = LocalStorageService.shared.guestUserId
        UserDefaults.standard.set(true, forKey: Self.guestModeKey)
        completeOnboarding()
    }

    func exitGuestMode() {
        isGuestMode = false
        isAuthenticated = false
        currentUserId = nil
        UserDefaults.standard.set(false, forKey: Self.guestModeKey)
    }
}
