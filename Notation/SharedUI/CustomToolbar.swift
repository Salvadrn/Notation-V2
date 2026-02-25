import SwiftUI

struct CustomToolbar<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            content()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.backgroundSecondary)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String?
    let isActive: Bool
    let action: () -> Void

    init(icon: String, label: String? = nil, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                if let label {
                    Text(label)
                        .font(.custom("Aptos", size: 10))
                }
            }
            .foregroundStyle(isActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
            .frame(width: 40, height: 36)
            .background(isActive ? Theme.Colors.primaryFallback.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
