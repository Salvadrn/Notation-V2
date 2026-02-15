import SwiftUI

struct NewSectionSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                TextField("Section Title", text: $title)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .focused($isFocused)

                Button {
                    onCreate(title.isEmpty ? "Untitled Section" : title)
                    dismiss()
                } label: {
                    Text("Create Section")
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("New Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { isFocused = true }
        .sheetStyle()
    }
}
