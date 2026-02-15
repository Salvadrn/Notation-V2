import SwiftUI

struct AuthGateView: View {
    @ObservedObject var supabase: SupabaseService
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if supabase.isAuthenticated {
                WorkspaceView()
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .animation(Theme.Animation.standard, value: supabase.isAuthenticated)
    }
}
