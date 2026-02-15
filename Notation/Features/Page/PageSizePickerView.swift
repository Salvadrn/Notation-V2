import SwiftUI

struct PageSizePickerView: View {
    let selectedSize: PageSizeType
    let selectedOrientation: PageOrientation
    let onSizeChange: (PageSizeType) -> Void
    let onOrientationChange: (PageOrientation) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section("Page Size") {
                    ForEach(PageSizeType.allCases, id: \.self) { size in
                        Button {
                            onSizeChange(size)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(size.displayName)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(Theme.Colors.textPrimary)

                                    let dimensions = Constants.PageSize.size(for: size)
                                    Text("\(Int(dimensions.width)) x \(Int(dimensions.height)) pt")
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }

                                Spacer()

                                if selectedSize == size {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }
                            }
                        }
                    }
                }

                SwiftUI.Section("Orientation") {
                    ForEach(PageOrientation.allCases, id: \.self) { orientation in
                        Button {
                            onOrientationChange(orientation)
                        } label: {
                            HStack {
                                Image(systemName: orientation == .portrait
                                      ? "rectangle.portrait"
                                      : "rectangle")
                                    .foregroundStyle(Theme.Colors.textSecondary)

                                Text(orientation.displayName)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()

                                if selectedOrientation == orientation {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Page Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheetStyle()
    }
}
