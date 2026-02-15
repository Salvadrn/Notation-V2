import SwiftUI

struct BreadcrumbView: View {
    let folders: [Folder]
    let onSelect: (Folder?) -> Void

    var body: some View {
        if !folders.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    Button {
                        onSelect(nil)
                    } label: {
                        Text("Home")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }

                    ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.textTertiary)

                        if index == folders.count - 1 {
                            Text(folder.name)
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .fontWeight(.medium)
                        } else {
                            Button {
                                onSelect(folder)
                            } label: {
                                Text(folder.name)
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(Theme.Colors.primaryFallback)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .background(Theme.Colors.backgroundSecondary.opacity(0.5))
        }
    }
}
