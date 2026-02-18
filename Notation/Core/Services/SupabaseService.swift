import Foundation
import Supabase

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUserId: UUID?
    @Published var isAuthenticated = false
    @Published var isGuestMode = false

    private static let guestModeKey = "notation_is_guest_mode"

    private init() {
        let url = AppConfig.supabaseURL
        let key = AppConfig.supabaseAnonKey
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        // Restore guest mode if previously set
        if UserDefaults.standard.bool(forKey: Self.guestModeKey) {
            self.isGuestMode = true
            self.isAuthenticated = true
            self.currentUserId = LocalStorageService.shared.guestUserId
        }
    }

    var isSupabaseConfigured: Bool {
        !AppConfig.supabaseAnonKey.hasPrefix("YOUR_")
    }

    func restoreSession() async {
        if isGuestMode { return }
        guard isSupabaseConfigured else { return }

        do {
            let session = try await client.auth.session
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
    }

    func exitGuestMode() {
        isGuestMode = false
        isAuthenticated = false
        currentUserId = nil
        UserDefaults.standard.set(false, forKey: Self.guestModeKey)
    }
}
