import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Logo & Title
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "note.text")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text("Notation")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Your ideas, beautifully organized")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Form
            VStack(spacing: Theme.Spacing.lg) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    #if os(iOS)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    #if os(iOS)
                    .textContentType(.password)
                    #endif

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.destructive)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(Theme.Typography.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.primaryFallback)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Sign Up Link
            Button {
                viewModel.showSignUp = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Don't have an account?")
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("Sign Up")
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .fontWeight(.semibold)
                }
                .font(Theme.Typography.subheadline)
            }

            Spacer()
        }
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.backgroundPrimary)
    }
}
