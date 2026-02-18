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
        .onAppear {
            // Auto-focus the first block so user can start typing immediately
            if let firstId = viewModel.textBlocks.first?.id {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedBlockId = firstId
                }
            }
        }
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
                    .foregroundStyle(.black)
                    .frame(width: 16)
            case .quote:
                Rectangle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.4))
                    .frame(width: 3)
            default:
                EmptyView()
            }

            TextField(blockPlaceholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(blockFont)
                .foregroundStyle(.black)
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

    private var blockPlaceholder: String {
        switch block.style {
        case .heading: return "Heading"
        case .subheading: return "Subheading"
        case .body: return "Start typing..."
        case .bullet: return "List item"
        case .numbered: return "Numbered item"
        case .quote: return "Quote"
        case .code: return "Code"
        }
    }

    private var blockFont: Font {
        switch block.style {
        case .heading: return .system(size: 24, weight: .bold, design: .serif)
        case .subheading: return .system(size: 18, weight: .semibold, design: .serif)
        case .body: return .system(size: 15, weight: .regular, design: .default)
        case .bullet: return .system(size: 15, weight: .regular, design: .default)
        case .numbered: return .system(size: 15, weight: .regular, design: .default)
        case .quote: return .system(size: 15, weight: .regular, design: .serif)
        case .code: return .system(size: 13, weight: .regular, design: .monospaced)
        }
    }

    private var blockVerticalPadding: CGFloat {
        switch block.style {
        case .heading: return 8
        case .subheading: return 6
        default: return 3
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
