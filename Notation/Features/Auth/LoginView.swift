import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var supabase: SupabaseService

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Gray gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#1A1A1A"),
                        Color(hex: "#2A2A2A"),
                        Color(hex: "#333333")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: geo.size.height * 0.06)

                        // Hero section with app icon
                        VStack(spacing: 20) {
                            // App icon from Assets
                            Image("AppIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
                                .overlay(
                                    // Fallback if image not found
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#2A2A2A"), Color(hex: "#1A1A1A")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Text("N")
                                                .font(.custom("Aptos-Bold", size: 48))
                                                .foregroundStyle(.white)
                                        )
                                        .opacity(0) // Set to 1 if no asset
                                )

                            VStack(spacing: 8) {
                                Text("Notation")
                                    .font(.custom("Aptos-Bold", size: 40))
                                    .foregroundStyle(.white)

                                Text("Write. Create. Organize.")
                                    .font(.custom("Aptos", size: 17))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        Spacer(minLength: 36)

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

                        Spacer(minLength: 36)

                        // Action buttons
                        VStack(spacing: 14) {
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.custom("Aptos", size: 13))
                                    .foregroundStyle(Color(hex: "#CC4444"))
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 4)
                            }

                            // Guest mode button (primary)
                            Button {
                                supabase.enterGuestMode()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Start Writing")
                                        .font(.custom("Aptos-Bold", size: 17))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#4A4A4A"), Color(hex: "#5C5C5C")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
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
                                .font(.custom("Aptos", size: 12))
                                .foregroundStyle(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)

                            // Bigger, bolder Therians text
                            Text("Prohibida para los Therians")
                                .font(.custom("Aptos-Bold", size: 18))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(2)
                                .padding(.top, 12)
                        }
                        .padding(.horizontal, 32)

                        Spacer(minLength: geo.size.height * 0.05)
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
                .foregroundStyle(Color(hex: "#999999"))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Aptos-Bold", size: 15))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.custom("Aptos", size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()
        }
    }
}
