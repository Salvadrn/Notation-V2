import SwiftUI

struct TextEditorView: View {
    @ObservedObject var viewModel: PageViewModel
    @FocusState private var focusedBlockId: UUID?

    private let margin: CGFloat = 40
    private let topPadding: CGFloat = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.textBlocks.enumerated()), id: \.element.id) { index, block in
                TextBlockView(
                    block: block,
                    isFocused: focusedBlockId == block.id,
                    onTextChange: { text in
                        viewModel.updateBlock(id: block.id, text: text)
                    },
                    onStyleChange: { style in
                        viewModel.updateBlockStyle(id: block.id, style: style)
                    },
                    onReturn: {
                        viewModel.addBlock(after: block.id)
                        // Focus will move to new block
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let newId = viewModel.textBlocks[safe: index + 1]?.id {
                                focusedBlockId = newId
                            }
                        }
                    },
                    onDelete: {
                        if block.text.isEmpty && viewModel.textBlocks.count > 1 {
                            let prevIndex = max(0, index - 1)
                            focusedBlockId = viewModel.textBlocks[safe: prevIndex]?.id
                            viewModel.deleteBlock(id: block.id)
                        }
                    }
                )
                .focused($focusedBlockId, equals: block.id)
            }

            // Tap area to add new block
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.textBlocks.isEmpty || viewModel.textBlocks.last?.text.isEmpty == false {
                        viewModel.addBlock()
                    }
                    focusedBlockId = viewModel.textBlocks.last?.id
                }
        }
        .padding(.horizontal, margin)
        .padding(.top, topPadding)
        .padding(.bottom, margin)
        .onChange(of: focusedBlockId) { _, newValue in
            viewModel.selectedBlockId = newValue
            viewModel.isEditing = newValue != nil
        }
    }
}

struct TextBlockView: View {
    let block: TextBlock
    let isFocused: Bool
    let onTextChange: (String) -> Void
    let onStyleChange: (TextBlockStyle) -> Void
    let onReturn: () -> Void
    let onDelete: () -> Void

    @State private var text: String

    init(block: TextBlock, isFocused: Bool, onTextChange: @escaping (String) -> Void,
         onStyleChange: @escaping (TextBlockStyle) -> Void, onReturn: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.block = block
        self.isFocused = isFocused
        self.onTextChange = onTextChange
        self.onStyleChange = onStyleChange
        self.onReturn = onReturn
        self.onDelete = onDelete
        _text = State(initialValue: block.text)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Bullet/number prefix
            switch block.style {
            case .bullet:
                Text("\u{2022}")
                    .font(blockFont)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 16)
            case .quote:
                Rectangle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.4))
                    .frame(width: 3)
            default:
                EmptyView()
            }

            TextField("", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(blockFont)
                .foregroundStyle(blockColor)
                .lineLimit(nil)
                .onChange(of: text) { _, newValue in
                    onTextChange(newValue)
                }
                .onSubmit {
                    onReturn()
                }
        }
        .padding(.vertical, blockVerticalPadding)
    }

    private var blockFont: Font {
        switch block.style {
        case .heading: return .system(size: 24, weight: .bold, design: .rounded)
        case .subheading: return .system(size: 18, weight: .semibold, design: .rounded)
        case .body: return .system(size: 14, weight: .regular)
        case .bullet: return .system(size: 14, weight: .regular)
        case .numbered: return .system(size: 14, weight: .regular)
        case .quote: return .system(size: 14, weight: .regular, design: .serif)
        case .code: return .system(size: 12, weight: .regular, design: .monospaced)
        }
    }

    private var blockColor: Color {
        switch block.style {
        case .quote: return Theme.Colors.textSecondary
        case .code: return Color(hex: "#D946EF")
        default: return Theme.Colors.textPrimary
        }
    }

    private var blockVerticalPadding: CGFloat {
        switch block.style {
        case .heading: return 8
        case .subheading: return 6
        default: return 2
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
