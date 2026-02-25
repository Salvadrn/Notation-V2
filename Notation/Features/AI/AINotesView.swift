import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
#endif

struct AINotesView: View {
    @StateObject private var viewModel = AINotesViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showSubscription = false
    @State private var showFileImporter = false

    private var isProUser: Bool { subscriptionService.isProUser }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(isProUser ? Theme.Colors.accent : Theme.Colors.textTertiary)

                        if !isProUser {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .offset(x: 22, y: -18)
                        }
                    }

                    Text("Generate Notes from Slide")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Upload a slide image or take a photo to generate structured study notes")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                // Pro-only gate
                if !isProUser {
                    proLockedOverlay
                } else {
                    // Image selection
                    if let imageData = viewModel.selectedImage {
                        #if os(iOS)
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                                .prominentShadow()

                            Button("Remove Image") {
                                viewModel.clearResults()
                            }
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.destructive)
                        }
                        #endif
                    } else {
                        VStack(spacing: Theme.Spacing.md) {
                            #if os(iOS)
                            PhotosPicker(
                                selection: $viewModel.photosPickerItem,
                                matching: .images
                            ) {
                                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                    .font(Theme.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.md)
                                    .background(Theme.Colors.primaryFallback)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                            }
                            .onChange(of: viewModel.photosPickerItem) { _, newValue in
                                Task { await viewModel.handlePhotoPicker(newValue) }
                            }
                            #endif

                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import File", systemImage: "doc.badge.arrow.up")
                                    .font(Theme.Typography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(Theme.Spacing.md)
                                    .background(Theme.Colors.backgroundTertiary)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.xl)
                    }

                    // Generate button
                    if viewModel.selectedImage != nil {
                        Button {
                            Task { await viewModel.generateNotes() }
                        } label: {
                            Group {
                                if viewModel.isProcessing {
                                    HStack(spacing: Theme.Spacing.sm) {
                                        ProgressView().tint(.white)
                                        Text("Analyzing...")
                                    }
                                } else {
                                    Label("Generate Notes (\(Constants.Tokens.costPerAIGeneration) tokens)", systemImage: "sparkles")
                                }
                            }
                            .font(Theme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                        }
                        .disabled(viewModel.isProcessing)
                        .padding(.horizontal, Theme.Spacing.xl)
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.destructive)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.destructive.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                            .padding(.horizontal, Theme.Spacing.xl)
                    }

                    // Results
                    if let notes = viewModel.generatedNotes {
                        AIResultView(notes: notes)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }
                }
            }
        }
        .navigationTitle("AI Notes")
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image, .pdf]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    viewModel.selectedImage = data
                }
            case .failure:
                break
            }
        }
    }

    // MARK: - Pro Locked Overlay

    private var proLockedOverlay: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Text("Pro Feature")
                .font(.custom("Aptos-Bold", size: 22))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("AI note generation requires a Pro subscription.\nUpload photos and slides to get structured study notes automatically.")
                .font(.custom("Aptos", size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            VStack(spacing: 10) {
                lockedFeatureRow(icon: "sparkles", text: "AI-powered note extraction")
                lockedFeatureRow(icon: "doc.text.fill", text: "Structured summaries & key points")
                lockedFeatureRow(icon: "camera.fill", text: "Photo & slide analysis")
                lockedFeatureRow(icon: "bolt.fill", text: "500 tokens included monthly")
            }
            .padding(16)
            .background(Theme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showSubscription = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro — $4.99/mo")
                        .font(.custom("Aptos-Bold", size: 17))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Colors.primaryFallback)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private func lockedFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 24)
            Text(text)
                .font(.custom("Aptos", size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
    }
}
