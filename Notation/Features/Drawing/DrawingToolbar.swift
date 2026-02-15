#if os(iOS)
import SwiftUI

struct DrawingToolbar: View {
    @ObservedObject var viewModel: DrawingViewModel

    let penColors: [Color] = [.black, .blue, .red, .green, .orange, .purple]

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Tool selection
            ForEach(DrawingViewModel.DrawingTool.allCases, id: \.self) { tool in
                Button {
                    viewModel.selectedTool = tool
                    viewModel.updateTool()
                } label: {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(
                            viewModel.selectedTool == tool
                                ? Theme.Colors.primaryFallback
                                : Theme.Colors.textSecondary
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            viewModel.selectedTool == tool
                                ? Theme.Colors.primaryFallback.opacity(0.15)
                                : Theme.Colors.backgroundTertiary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                }
                .buttonStyle(.plain)
            }

            Divider()
                .frame(height: 24)

            // Color selection
            ForEach(penColors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if viewModel.selectedColor == color {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                                .padding(1)
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedColor = color
                        viewModel.updateTool()
                    }
            }

            Divider()
                .frame(height: 24)

            // Stroke width
            Slider(value: $viewModel.strokeWidth, in: 1...20)
                .frame(width: 80)
                .onChange(of: viewModel.strokeWidth) { _, _ in
                    viewModel.updateTool()
                }

            Spacer()

            // Undo/Redo
            Button { viewModel.undoLastStroke() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.plain)

            Button { viewModel.redoLastStroke() } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .buttonStyle(.plain)

            Button { viewModel.clearCanvas() } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.Colors.destructive)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.backgroundSecondary)
    }
}
#endif
