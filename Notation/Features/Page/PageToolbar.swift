import SwiftUI

struct PageToolbar: View {
    @ObservedObject var viewModel: PageViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Text style buttons
                Group {
                    styleButton("H1", style: .heading)
                    styleButton("H2", style: .subheading)
                    styleButton("P", style: .body)

                    Divider()
                        .frame(height: 20)

                    iconStyleButton("list.bullet", style: .bullet)
                    iconStyleButton("text.quote", style: .quote)
                    iconStyleButton("chevron.left.forwardslash.chevron.right", style: .code)
                }

                Divider()
                    .frame(height: 20)

                // Layer visibility toggles
                ForEach(viewModel.layers) { layer in
                    Button {
                        Task { await viewModel.toggleLayerVisibility(layer) }
                    } label: {
                        Image(systemName: layer.layerType.iconName)
                            .font(.system(size: 14))
                            .foregroundStyle(
                                layer.isVisible
                                    ? Theme.Colors.primaryFallback
                                    : Theme.Colors.textTertiary
                            )
                            .frame(width: 28, height: 28)
                            .background(
                                layer.isVisible
                                    ? Theme.Colors.primaryFallback.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 20)

                // Page settings
                Button {
                    viewModel.showSizePicker = true
                } label: {
                    Label(viewModel.page.pageSize.displayName, systemImage: "doc")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Save indicator
                if viewModel.isSaving {
                    HStack(spacing: Theme.Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Saving...")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Theme.Colors.backgroundSecondary)
    }

    @ViewBuilder
    private func styleButton(_ label: String, style: TextBlockStyle) -> some View {
        let isActive = viewModel.textBlocks.first(where: { $0.id == viewModel.selectedBlockId })?.style == style

        Button {
            if let blockId = viewModel.selectedBlockId {
                viewModel.updateBlockStyle(id: blockId, style: style)
            }
        } label: {
            Text(label)
                .font(.custom(isActive ? "Aptos-Bold" : "Aptos", size: 12))
                .foregroundStyle(isActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background(isActive ? Theme.Colors.primaryFallback.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func iconStyleButton(_ icon: String, style: TextBlockStyle) -> some View {
        let isActive = viewModel.textBlocks.first(where: { $0.id == viewModel.selectedBlockId })?.style == style

        Button {
            if let blockId = viewModel.selectedBlockId {
                viewModel.updateBlockStyle(id: blockId, style: style)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background(isActive ? Theme.Colors.primaryFallback.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
