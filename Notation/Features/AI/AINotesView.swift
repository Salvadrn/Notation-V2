import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct AINotesView: View {
    @StateObject private var viewModel = AINotesViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.accent)

                    Text("Generate Notes from Slide")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Upload a slide image or take a photo to generate structured study notes")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

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
                    // Upload options
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

                        // File import for both platforms
                        Button {
                            // File importer handled via .fileImporter modifier
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
                                    ProgressView()
                                        .tint(.white)
                                    Text("Analyzing...")
                                }
                            } else {
                                Label("Generate Notes", systemImage: "sparkles")
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
        .navigationTitle("AI Notes")
    }
}
