import SwiftUI

struct AuthGateView: View {
    @ObservedObject var supabase: SupabaseService
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if !supabase.hasCompletedOnboarding {
                // First time ever opening the app → show onboarding/login
                LoginView(viewModel: authViewModel)
            } else if supabase.isAuthenticated {
                // Returning user (guest or signed in) → go straight to workspace
                WorkspaceView()
            } else {
                // Completed onboarding before but not authenticated
                // (e.g. signed out) → show login again
                LoginView(viewModel: authViewModel)
            }
        }
        .animation(Theme.Animation.standard, value: supabase.isAuthenticated)
        .animation(Theme.Animation.standard, value: supabase.hasCompletedOnboarding)
    }
}
