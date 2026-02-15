import SwiftUI

struct NotationSheet<Content: View>: View {
    let title: String
    let content: () -> Content
    let onDismiss: () -> Void

    init(title: String, onDismiss: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onDismiss)
                    }
                }
        }
        .sheetStyle()
    }
}

struct ConfirmationSheet: View {
    let title: String
    let message: String
    let confirmLabel: String
    let isDestructive: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    init(
        title: String,
        message: String,
        confirmLabel: String = "Confirm",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                Text(title)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Theme.Spacing.md) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.backgroundTertiary)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }

                Button(action: onConfirm) {
                    Text(confirmLabel)
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(isDestructive ? Theme.Colors.destructive : Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
