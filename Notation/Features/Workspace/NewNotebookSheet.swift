import SwiftUI

struct NewNotebookSheet: View {
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedColor = Color.coverColors[0]
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                // Preview
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color(hex: selectedColor))
                    .frame(width: 140, height: 180)
                    .overlay {
                        VStack {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(title.isEmpty ? "Untitled" : title)
                                .font(Theme.Typography.footnote)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.sm)
                        }
                    }
                    .prominentShadow()

                // Title
                TextField("Notebook Title", text: $title)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .focused($isFocused)

                // Color Picker
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Cover Color")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.sm) {
                        ForEach(Color.coverColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if colorHex == selectedColor {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2)
                                            .padding(2)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = colorHex
                                }
                        }
                    }
                }

                Button {
                    onCreate(title.isEmpty ? "Untitled Notebook" : title)
                    dismiss()
                } label: {
                    Text("Create Notebook")
                        .font(Theme.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.primaryFallback)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("New Notebook")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
