import SwiftUI

@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: AppError?
    @Published var showError = false

    struct AppError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let isRecoverable: Bool
        var retryAction: (() async -> Void)?
    }

    func handle(_ error: Error, title: String = "Error", retryAction: (() async -> Void)? = nil) {
        let message: String
        let isRecoverable: Bool

        if let notationError = error as? NotationError {
            message = notationError.localizedDescription ?? "An unknown error occurred."
            isRecoverable = retryAction != nil
        } else {
            message = error.localizedDescription
            isRecoverable = retryAction != nil
        }

        currentError = AppError(
            title: title,
            message: message,
            isRecoverable: isRecoverable,
            retryAction: retryAction
        )
        showError = true
    }

    func dismiss() {
        showError = false
        currentError = nil
    }
}

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { error in
                if error.isRecoverable, let retry = error.retryAction {
                    Button("Retry") {
                        Task { await retry() }
                    }
                    Button("Dismiss", role: .cancel) {
                        errorHandler.dismiss()
                    }
                } else {
                    Button("OK", role: .cancel) {
                        errorHandler.dismiss()
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func withErrorHandling(_ handler: ErrorHandler = .shared) -> some View {
        modifier(ErrorAlertModifier(errorHandler: handler))
    }
}
