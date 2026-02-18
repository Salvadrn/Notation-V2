import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var supabase: SupabaseService

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#1A1A2E"),
                        Color(hex: "#16213E"),
                        Color(hex: "#0F3460")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: geo.size.height * 0.08)

                        // Hero section
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#6366F1"), Color(hex: "#8B5CF6")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(hex: "#6366F1").opacity(0.4), radius: 20, y: 8)

                                Image(systemName: "pencil.and.scribble")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                            VStack(spacing: 8) {
                                Text("Notation")
                                    .font(.system(size: 38, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)

                                Text("Write. Create. Organize.")
                                    .font(.system(size: 17, weight: .regular, design: .serif))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        Spacer(minLength: 40)

                        // Feature highlights
                        VStack(spacing: 16) {
                            featureRow(
                                icon: "doc.richtext",
                                title: "Word-style Editor",
                                subtitle: "Type and format with headings, lists, and more"
                            )
                            featureRow(
                                icon: "folder.fill",
                                title: "Smart Organization",
                                subtitle: "Folders, notebooks, sections, and pages"
                            )
                            featureRow(
                                icon: "hand.draw.fill",
                                title: "Apple Pencil Support",
                                subtitle: "Draw and write naturally on iPad"
                            )
                            featureRow(
                                icon: "sparkles",
                                title: "AI-Powered Notes",
                                subtitle: "Generate notes from photos and slides"
                            )
                        }
                        .padding(.horizontal, 32)

                        Spacer(minLength: 40)

                        // Action buttons
                        VStack(spacing: 14) {
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .regular, design: .serif))
                                    .foregroundStyle(Color(hex: "#EF4444"))
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 4)
                            }

                            // Guest mode button
                            Button {
                                supabase.enterGuestMode()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Start Writing")
                                        .font(.system(size: 17, weight: .semibold, design: .serif))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#6366F1"), Color(hex: "#8B5CF6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "#6366F1").opacity(0.3), radius: 12, y: 4)
                            }

                            // Apple sign in
                            if supabase.isSupabaseConfigured {
                                SignInWithAppleButton(.signIn) { request in
                                    request.requestedScopes = [.fullName, .email]
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                            Task { await viewModel.signInWithApple(credential: credential) }
                                        }
                                    case .failure(let error):
                                        viewModel.errorMessage = error.localizedDescription
                                    }
                                }
                                .signInWithAppleButtonStyle(.white)
                                .frame(height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text("Files are saved on this device. Create an account later to sync across devices.")
                                .font(.system(size: 12, weight: .regular, design: .serif))
                                .foregroundStyle(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)

                            Text("Prohibida para los Therians")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundStyle(.white.opacity(0.25))
                                .tracking(1.5)
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)

                        Spacer(minLength: geo.size.height * 0.06)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "#8B5CF6"))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }
}
