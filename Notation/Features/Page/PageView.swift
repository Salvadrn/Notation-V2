import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PageView: View {
    @StateObject private var viewModel: PageViewModel
    #if os(iOS)
    var onHandwritingAction: ((HandwritingAction, UIImage) -> Void)?
    #endif

    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var showZoomIndicator = false

    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 3.0

    init(page: Page, onSave: @escaping (Page) -> Void) {
        _viewModel = StateObject(wrappedValue: PageViewModel(page: page, onSave: onSave))
    }

    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(viewModel: viewModel)
            canvasWithZoom
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

    // MARK: - Canvas with Zoom

    private var canvasWithZoom: some View {
        ZStack(alignment: .bottomLeading) {
            zoomableScrollView
            if showZoomIndicator || currentZoom != 1.0 {
                zoomIndicator
            }
        }
    }

    private var zoomableScrollView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            canvasContent
        }
        .background(Theme.Colors.backgroundTertiary)
        .gesture(pinchGesture)
    }

    private var canvasContent: some View {
        canvasView
            .frame(
                width: viewModel.page.displaySize.width,
                height: viewModel.page.displaySize.height
            )
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .prominentShadow()
            .padding(Theme.Spacing.xl)
            .scaleEffect(currentZoom)
            .frame(
                width: viewModel.page.displaySize.width * currentZoom + Theme.Spacing.xl * 2,
                height: viewModel.page.displaySize.height * currentZoom + Theme.Spacing.xl * 2
            )
    }

    @ViewBuilder
    private var canvasView: some View {
        #if os(iOS)
        PageCanvasView(viewModel: viewModel, onHandwritingAction: onHandwritingAction)
        #else
        PageCanvasView(viewModel: viewModel)
        #endif
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newZoom = lastZoom * value
                currentZoom = min(max(newZoom, minZoom), maxZoom)
                withAnimation(.easeInOut(duration: 0.15)) {
                    showZoomIndicator = true
                }
            }
            .onEnded { _ in
                lastZoom = currentZoom
                hideZoomIndicator()
            }
    }

    // MARK: - Zoom Indicator

    private var zoomIndicator: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentZoom = max(currentZoom - 0.25, minZoom)
                    lastZoom = currentZoom
                }
                showZoomBriefly()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }

            Text("\(Int(currentZoom * 100))%")
                .font(.custom("Aptos-Bold", size: 13))
                .monospacedDigit()
                .frame(minWidth: 44)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentZoom = min(currentZoom + 0.25, maxZoom)
                    lastZoom = currentZoom
                }
                showZoomBriefly()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }

            Divider()
                .frame(height: 18)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentZoom = 1.0
                    lastZoom = 1.0
                }
                hideZoomIndicator()
            } label: {
                Text("Reset")
                    .font(.custom("Aptos", size: 12))
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(12)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func hideZoomIndicator() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            if currentZoom == 1.0 {
                withAnimation(.easeOut(duration: 0.3)) {
                    showZoomIndicator = false
                }
            }
        }
    }

    private func showZoomBriefly() {
        withAnimation { showZoomIndicator = true }
        hideZoomIndicator()
    }
}
