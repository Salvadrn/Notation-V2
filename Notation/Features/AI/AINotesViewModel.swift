import SwiftUI
#if os(iOS)
import PhotosUI
#endif

@MainActor
final class AINotesViewModel: ObservableObject {
    @Published var selectedImage: Data?
    @Published var generatedNotes: AIGeneratedNotes?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showImagePicker = false
    @Published var showCamera = false
    @Published var jobs: [AIJob] = []

    #if os(iOS)
    @Published var photosPickerItem: PhotosPickerItem?
    #endif

    private let aiService: AIService

    init(aiService: AIService = AIService()) {
        self.aiService = aiService
    }

    func generateNotes(pageId: UUID? = nil) async {
        guard let imageData = selectedImage else {
            errorMessage = "Please select an image first."
            return
        }

        isProcessing = true
        errorMessage = nil
        generatedNotes = nil

        do {
            let notes = try await aiService.generateNotesFromImage(
                imageData: imageData,
                pageId: pageId
            )
            generatedNotes = notes
        } catch {
            if let notationError = error as? NotationError {
                errorMessage = notationError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isProcessing = false
    }

    func loadJobs() async {
        do {
            jobs = try await aiService.fetchJobs()
        } catch {
            // Silently fail for history
        }
    }

    #if os(iOS)
    func handlePhotoPicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImage = data
            }
        } catch {
            errorMessage = "Failed to load image."
        }
    }
    #endif

    func clearResults() {
        selectedImage = nil
        generatedNotes = nil
        errorMessage = nil
    }
}
