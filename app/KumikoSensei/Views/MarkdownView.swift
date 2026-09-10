import SwiftUI

enum InlineMarkdown {
    static func attributed(_ text: String) -> AttributedString {
        var result: AttributedString
        if let parsed = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = parsed
        } else {
            result = AttributedString(text)
        }
        for run in result.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                result[run.range].font = .system(.body, design: .monospaced)
                result[run.range].foregroundColor = Palette.info
            }
        }
        return result
    }
}

struct InlineText: View {
    let text: String

    var body: some View {
        Text(InlineMarkdown.attributed(text))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownBlock.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .textSelection(.enabled)
        .foregroundStyle(Palette.ink)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            InlineText(text: text)
                .font(level <= 2 ? .inter(.title3, .semibold) : .inter(.headline, .semibold))
                .padding(.top, level <= 2 ? 8 : 4)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            InlineText(text: text).font(.inter()).lineSpacing(3)
        case .bullets(let items):
            listView(items, numbered: false)
        case .numbered(let items):
            listView(items, numbered: true)
        case .code(_, let code):
            ScrollView(.horizontal) {
                Text(code).font(.deskMono).padding(12).fixedSize(horizontal: true, vertical: false)
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(Palette.cardRaised))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.rule, lineWidth: 1))
        case .quote(let text):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 1).fill(Palette.primary.opacity(0.6)).frame(width: 3)
                InlineText(text: text).font(.inter()).foregroundStyle(Palette.inkMuted)
            }
        case .table(let header, let rows):
            ScrollView(.horizontal) {
                Grid(alignment: .topLeading, horizontalSpacing: 18, verticalSpacing: 6) {
                    GridRow {
                        ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                            InlineText(text: cell).font(.inter(.callout, .semibold))
                        }
                    }
                    Divider().gridCellUnsizedAxes(.horizontal)
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                InlineText(text: cell).font(.inter(.callout)).frame(maxWidth: 360, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(Palette.cardRaised))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.rule, lineWidth: 1))
        case .rule:
            Divider()
        }
    }

    private func listView(_ items: [MarkdownBlock.ListItem], numbered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(numbered ? "\(index + 1)." : "•")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(Palette.primary)
                        .frame(minWidth: numbered ? 22 : 10, alignment: .trailing)
                    InlineText(text: item.text).font(.inter()).lineSpacing(2)
                }
                .padding(.leading, CGFloat(item.indent) * 18)
            }
        }
    }
}
