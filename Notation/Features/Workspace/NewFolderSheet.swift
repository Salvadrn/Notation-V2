import SwiftUI

struct NewFolderSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                TextField("Folder Name", text: $name)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .focused($isFocused)

                Button {
                    onCreate(name)
                    dismiss()
                } label: {
                    Text("Create Folder")
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(name.isEmpty ? Theme.Colors.backgroundTertiary : Theme.Colors.primaryFallback)
                        .foregroundStyle(name.isEmpty ? Theme.Colors.textTertiary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
                .disabled(name.isEmpty)
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("New Folder")
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
