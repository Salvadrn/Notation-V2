import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Unable to retrieve Apple ID token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithApple(
                idToken: idToken,
                fullName: credential.fullName
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
