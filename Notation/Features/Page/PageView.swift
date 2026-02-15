import SwiftUI

struct PageView: View {
    @StateObject private var viewModel: PageViewModel

    init(page: Page, onSave: @escaping (Page) -> Void) {
        _viewModel = StateObject(wrappedValue: PageViewModel(page: page, onSave: onSave))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            PageToolbar(viewModel: viewModel)

            // Page canvas in scroll view
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                PageCanvasView(viewModel: viewModel)
                    .frame(
                        width: viewModel.page.displaySize.width,
                        height: viewModel.page.displaySize.height
                    )
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .prominentShadow()
                    .padding(Theme.Spacing.xl)
            }
            .background(Theme.Colors.backgroundTertiary)
        }
        .sheet(isPresented: $viewModel.showSizePicker) {
            PageSizePickerView(
                selectedSize: viewModel.page.pageSize,
                selectedOrientation: viewModel.page.orientation,
                onSizeChange: { viewModel.updatePageSize($0) },
                onOrientationChange: { viewModel.updateOrientation($0) }
            )
        }
        .onFirstAppear {
            await viewModel.loadLayers()
        }
        .onDisappear {
            Task { await viewModel.flushSave() }
        }
    }
}
