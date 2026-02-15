import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text("Create Account")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Start organizing your notes")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.lg) {
                    TextField("Full Name", text: $viewModel.fullName)
                        .textFieldStyle(.plain)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        #if os(iOS)
                        .textContentType(.name)
                        #endif

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

                    SecureField("Password (min 6 characters)", text: $viewModel.password)
                        .textFieldStyle(.plain)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        #if os(iOS)
                        .textContentType(.newPassword)
                        #endif

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.destructive)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await viewModel.signUp() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
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

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Already have an account?")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text("Sign In")
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
