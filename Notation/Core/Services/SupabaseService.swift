import Foundation
import Supabase

@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUserId: UUID?
    @Published var isAuthenticated = false

    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    func restoreSession() async {
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
}
