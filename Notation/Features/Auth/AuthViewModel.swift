import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSignUp = false

    private let authService: AuthService

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }

    var isSignUpFormValid: Bool {
        isFormValid && !fullName.isEmpty
    }

    func signIn() async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields. Password must be at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp() async {
        guard isSignUpFormValid else {
            errorMessage = "Please fill in all fields. Password must be at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: email, password: password, fullName: fullName)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearForm() {
        email = ""
        password = ""
        fullName = ""
        errorMessage = nil
    }
}
