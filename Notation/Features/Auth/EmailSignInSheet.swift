import SwiftUI

enum EmailSignInMode {
    case password
    case magicLink
}

struct EmailSignInSheet: View {
    @EnvironmentObject var supabase: SupabaseService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false
    @State private var signInMode: EmailSignInMode = .magicLink
    @State private var magicLinkSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: signInMode == .magicLink ? "link.circle.fill" : "envelope.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text(headerTitle)
                        .font(.custom("Aptos-Bold", size: 24))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(headerSubtitle)
                        .font(.custom("Aptos", size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                // Mode picker
                Picker("Sign In Method", selection: $signInMode) {
                    Text("Magic Link").tag(EmailSignInMode.magicLink)
                    Text("Password").tag(EmailSignInMode.password)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                // Form
                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 24)
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .font(.custom("Aptos", size: 16))
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if signInMode == .password {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .frame(width: 24)
                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .font(.custom("Aptos", size: 16))
                        }
                        .padding(14)
                        .background(Theme.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .animation(.easeInOut(duration: 0.2), value: signInMode)

                if let error = errorMessage {
                    Text(error)
                        .font(.custom("Aptos", size: 13))
                        .foregroundStyle(Theme.Colors.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if showConfirmation {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "#34A853"))
                        Text("Check your email to confirm your account.")
                            .font(.custom("Aptos", size: 14))
                            .foregroundStyle(Color(hex: "#34A853"))
                    }
                    .padding(.horizontal, 32)
                }

                if magicLinkSent {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(Theme.Colors.primaryFallback)
                            Text("Magic link sent!")
                                .font(.custom("Aptos-Bold", size: 15))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }

                        Text("Check your email inbox and tap the link to sign in. You can close this sheet.")
                            .font(.custom("Aptos", size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(Theme.Colors.primaryFallback.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                }

                // Action buttons
                VStack(spacing: 14) {
                    Button {
                        #if os(iOS)
                        HapticService.light()
                        #endif
                        Task { await handleSubmit() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(actionButtonTitle)
                                    .font(.custom("Aptos-Bold", size: 17))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSubmitDisabled)
                    .opacity(isSubmitDisabled ? 0.5 : 1)

                    if signInMode == .password {
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = nil
                                showConfirmation = false
                            }
                        } label: {
                            Text(isSignUp
                                 ? "Already have an account? Sign In"
                                 : "Don't have an account? Create one")
                                .font(.custom("Aptos", size: 14))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle(signInMode == .magicLink ? "Magic Link" : (isSignUp ? "Create Account" : "Email Sign In"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .withErrorHandling()
        }
    }

    // MARK: - Computed Properties

    private var headerTitle: String {
        switch signInMode {
        case .magicLink:
            return "Sign In with Magic Link"
        case .password:
            return isSignUp ? "Create Account" : "Sign In with Email"
        }
    }

    private var headerSubtitle: String {
        switch signInMode {
        case .magicLink:
            return "Enter your email and we'll send you a secure link to sign in — no password needed."
        case .password:
            return isSignUp
                ? "Create an account to sync your notebooks across devices."
                : "Sign in to sync your notebooks across devices."
        }
    }

    private var actionButtonTitle: String {
        switch signInMode {
        case .magicLink:
            return magicLinkSent ? "Resend Magic Link" : "Send Magic Link"
        case .password:
            return isSignUp ? "Create Account" : "Sign In"
        }
    }

    private var isSubmitDisabled: Bool {
        if isLoading { return true }
        if email.isEmpty { return true }
        if signInMode == .password && password.isEmpty { return true }
        return false
    }

    // MARK: - Actions

    private func handleSubmit() async {
        isLoading = true
        errorMessage = nil
        showConfirmation = false

        do {
            let authService = AuthService()

            switch signInMode {
            case .magicLink:
                try await authService.signInWithMagicLink(email: email)
                magicLinkSent = true
                #if os(iOS)
                HapticService.success()
                #endif

            case .password:
                if isSignUp {
                    try await authService.signUpWithEmail(email: email, password: password)
                    await supabase.restoreSession()
                    if supabase.isAuthenticated {
                        supabase.observeAuthChanges()
                        supabase.completeOnboarding()
                        dismiss()
                    } else {
                        showConfirmation = true
                    }
                } else {
                    if supabase.isGuestMode {
                        supabase.exitGuestMode()
                    }
                    try await authService.signInWithEmail(email: email, password: password)
                    await supabase.restoreSession()
                    supabase.observeAuthChanges()
                    supabase.completeOnboarding()
                    dismiss()
                }
            }
        } catch {
            if !supabase.isAuthenticated && !supabase.isGuestMode {
                supabase.enterGuestMode()
            }
            errorMessage = error.localizedDescription
            #if os(iOS)
            HapticService.error()
            #endif
        }

        isLoading = false
    }
}
