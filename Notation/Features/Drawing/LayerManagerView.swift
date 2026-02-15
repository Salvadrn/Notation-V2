import SwiftUI

struct LayerManagerView: View {
    let layers: [PageLayer]
    let onToggleVisibility: (PageLayer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Layers")
                .font(Theme.Typography.headline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

            ForEach(layers) { layer in
                HStack(spacing: Theme.Spacing.md) {
                    Button {
                        onToggleVisibility(layer)
                    } label: {
                        Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                layer.isVisible
                                    ? Theme.Colors.primaryFallback
                                    : Theme.Colors.textTertiary
                            )
                    }
                    .buttonStyle(.plain)

                    Image(systemName: layer.layerType.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 20)

                    Text(layer.layerType.displayName)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(
                            layer.isVisible
                                ? Theme.Colors.textPrimary
                                : Theme.Colors.textTertiary
                        )

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .padding(.horizontal, Theme.Spacing.sm)
            }

            Spacer()
        }
        .frame(minWidth: 180)
        .background(Theme.Colors.backgroundPrimary)
    }
}
