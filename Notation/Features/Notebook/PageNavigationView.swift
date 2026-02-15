import SwiftUI

struct PageNavigationView: View {
    let pages: [Page]
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Pages")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        Button {
                            selectedIndex = index
                        } label: {
                            HStack {
                                // Thumbnail placeholder
                                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                    .fill(selectedIndex == index
                                          ? Theme.Colors.primaryFallback.opacity(0.15)
                                          : Theme.Colors.backgroundTertiary)
                                    .frame(width: 50, height: 65)
                                    .overlay {
                                        VStack(spacing: 2) {
                                            ForEach(0..<4, id: \.self) { _ in
                                                RoundedRectangle(cornerRadius: 1)
                                                    .fill(Theme.Colors.textTertiary.opacity(0.3))
                                                    .frame(height: 2)
                                                    .padding(.horizontal, 6)
                                            }
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                            .strokeBorder(
                                                selectedIndex == index
                                                    ? Theme.Colors.primaryFallback
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Page \(index + 1)")
                                        .font(Theme.Typography.footnote)
                                        .fontWeight(selectedIndex == index ? .semibold : .regular)
                                        .foregroundStyle(
                                            selectedIndex == index
                                                ? Theme.Colors.primaryFallback
                                                : Theme.Colors.textPrimary
                                        )

                                    Text(page.pageSize.displayName)
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
            }
        }
        .background(Theme.Colors.backgroundSecondary)
    }
}
