import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.Colors.primaryFallback)
                .clipShape(Circle())
                .prominentShadow()
        }
        .buttonStyle(.plain)
    }
}

struct FloatingActionMenu: View {
    @State private var isExpanded = false

    struct MenuItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let action: () -> Void
    }

    let items: [MenuItem]

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            if isExpanded {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(item.label)
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Theme.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                            .softShadow()

                        Button {
                            item.action()
                            withAnimation(Theme.Animation.smooth) {
                                isExpanded = false
                            }
                        } label: {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Theme.Colors.primaryFallback)
                                .clipShape(Circle())
                                .softShadow()
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            FloatingActionButton(icon: isExpanded ? "xmark" : "plus") {
                withAnimation(Theme.Animation.bouncy) {
                    isExpanded.toggle()
                }
            }
        }
    }
}
