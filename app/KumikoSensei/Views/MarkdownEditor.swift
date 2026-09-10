import AppKit
import SwiftUI

struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        let textView = scroll.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.font = MarkdownStyler.body
        textView.postsFrameChangedNotifications = true
        context.coordinator.resizeObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: textView, queue: .main) { [weak textView, weak coordinator = context.coordinator] _ in
            guard let textView, let coordinator, let storage = textView.textStorage, textView.tableWidth != coordinator.lastWidth else { return }
            coordinator.lastWidth = textView.tableWidth
            MarkdownStyler.restyle(storage, caret: textView.selectedRange(), width: textView.tableWidth)
        }
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        let textView = scroll.documentView as! NSTextView
        guard textView.string != text, let storage = textView.textStorage else { return }
        textView.string = text
        MarkdownStyler.restyle(storage, caret: textView.selectedRange(), width: textView.tableWidth)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditor
        var resizeObserver: NSObjectProtocol?
        var lastWidth: CGFloat = 0
        init(_ parent: MarkdownEditor) { self.parent = parent }
        deinit { resizeObserver.map(NotificationCenter.default.removeObserver) }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, let storage = textView.textStorage else { return }
            MarkdownStyler.restyle(storage, caret: textView.selectedRange(), width: textView.tableWidth)
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, let storage = textView.textStorage else { return }
            MarkdownStyler.restyle(storage, caret: textView.selectedRange(), width: textView.tableWidth)
        }
    }
}

private extension NSTextView {
    var tableWidth: CGFloat {
        guard let container = textContainer else { return .infinity }
        return container.size.width - 2 * container.lineFragmentPadding
    }
}

enum MarkdownStyler {
    static let body = Inter.nsFont(size: 14)
    private static let headingSizes: [CGFloat] = [22, 18, 16]

    static func restyle(_ storage: NSTextStorage, caret: NSRange? = nil, width: CGFloat = .infinity) {
        let scratch = NSMutableAttributedString(string: storage.string)
        style(scratch, caret: caret, width: width)
        let text = storage.string as NSString
        storage.beginEditing()
        var location = 0
        while location < text.length {
            let line = text.lineRange(for: NSRange(location: location, length: 0))
            if !storage.attributedSubstring(from: line).isEqual(to: scratch.attributedSubstring(from: line)) {
                scratch.enumerateAttributes(in: line) { attributes, range, _ in storage.setAttributes(attributes, range: range) }
            }
            location = line.upperBound
        }
        storage.endEditing()
    }

    private static func style(_ storage: NSMutableAttributedString, caret: NSRange?, width: CGFloat) {
        let full = NSRange(location: 0, length: storage.length)
        let text = storage.string as NSString
        let activeLines = caret.map { text.lineRange(for: $0) }
        var markers: [NSRange] = []
        func marker(_ range: NSRange) { markers.append(range) }
        storage.setAttributes([.font: body, .foregroundColor: ink], range: full)
        each(#"^(#{1,3})[ \t]+.+$"#, in: storage) { m in
            let level = m.range(at: 1).length
            storage.addAttribute(.font, value: Inter.nsFont(size: headingSizes[level - 1], weight: .semibold), range: m.range)
            marker(NSRange(location: m.range.location, length: level + 1))
        }
        each(#"\*\*([^*\n]+?)\*\*"#, in: storage) { m in
            addTrait(.bold, storage, m.range(at: 1))
            marker(NSRange(location: m.range.location, length: 2))
            marker(NSRange(location: m.range.upperBound - 2, length: 2))
        }
        each(#"(?<![*\w])[*_](?![*_])([^*_\n]+?)[*_](?![*_\w])"#, in: storage) { m in
            addTrait(.italic, storage, m.range(at: 1))
            marker(NSRange(location: m.range.location, length: 1))
            marker(NSRange(location: m.range.upperBound - 1, length: 1))
        }
        each(#"~~([^~\n]+?)~~"#, in: storage) { m in
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: m.range(at: 1))
            marker(NSRange(location: m.range.location, length: 2))
            marker(NSRange(location: m.range.upperBound - 2, length: 2))
        }
        each(#"`([^`\n]+)`"#, in: storage) { m in
            storage.addAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: body.pointSize - 1, weight: .regular),
                .backgroundColor: primaryWash,
            ], range: m.range)
            marker(NSRange(location: m.range.location, length: 1))
            marker(NSRange(location: m.range.upperBound - 1, length: 1))
        }
        each(#"^-{3,}$"#, in: storage) { m in dim(storage, m.range) }
        each(#"^[ \t]*(?:[-*+]|\d+\.)[ \t]"#, in: storage) { m in
            storage.addAttribute(.foregroundColor, value: primary, range: m.range)
        }
        each(#"^[ \t]*[-*+][ \t](\[[ xX]\])"#, in: storage) { m in
            let done = storage.attributedSubstring(from: m.range(at: 1)).string.lowercased().contains("x")
            storage.addAttribute(.foregroundColor, value: done ? secondary : primary, range: m.range(at: 1))
        }
        each(#"^>.*$"#, in: storage) { m in
            addTrait(.italic, storage, m.range)
            dim(storage, m.range)
        }
        each(#"\[([^\]\n]+)\]\(([^)\n]+)\)"#, in: storage) { m in
            storage.addAttributes([.foregroundColor: info, .underlineStyle: NSUnderlineStyle.single.rawValue], range: m.range(at: 1))
            marker(NSRange(location: m.range.location, length: 1))
            marker(NSRange(location: m.range(at: 1).upperBound, length: m.range.upperBound - m.range(at: 1).upperBound))
        }
        for block in tableBlocks(in: text) {
            let active = activeLines.map { NSIntersectionRange($0, block.range).length > 0 } ?? true
            let size = max(6, min(body.pointSize - 2, (body.pointSize - 2) * width / (CGFloat(block.widestLine) * monoCharWidth)))
            let mono = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            storage.addAttribute(.font, value: mono, range: block.range)
            var dataRow = 0
            for line in block.lines {
                if line.isFrame {
                    if active { dim(storage, line.range) } else { storage.addAttributes(hidden, range: line.range) }
                    continue
                }
                if dataRow == 0 { addTrait(.bold, storage, line.range) }
                if dataRow % 2 == 1 { storage.addAttribute(.backgroundColor, value: zebra, range: NSRange(location: line.range.location, length: line.contentLength)) }
                dataRow += 1
                each(#"[│|]"#, in: storage, range: line.range) { m in
                    if active { dim(storage, m.range) } else { marker(m.range) }
                }
            }
        }
        for range in markers {
            if let activeLines, NSIntersectionRange(activeLines, range).length > 0 {
                dim(storage, range)
            } else if activeLines != nil {
                storage.addAttributes(hidden, range: range)
            } else {
                dim(storage, range)
            }
        }
    }

    private static let ink = NSColor(Palette.ink)
    private static let inkMuted = NSColor(Palette.inkMuted)
    private static let primary = NSColor(Palette.primary)
    private static let secondary = NSColor(Palette.secondary)
    private static let info = NSColor(Palette.info)
    private static let primaryWash = NSColor(Palette.primaryWash)
    private static let zebra = NSColor(Palette.primaryWash).withAlphaComponent(0.45)
    private static let hidden: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 0.5), .foregroundColor: NSColor.clear]
    private static let monoCharWidth = ("M" as NSString).size(withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: body.pointSize - 2, weight: .regular)]).width

    struct TableLine {
        let range: NSRange
        let contentLength: Int
        let isFrame: Bool
    }

    struct TableBlock {
        var lines: [TableLine]
        var range: NSRange { NSUnionRange(lines.first!.range, lines.last!.range) }
        var widestLine: Int { lines.map(\.contentLength).max() ?? 1 }
    }

    static func tableBlocks(in text: NSString) -> [TableBlock] {
        let row = try! NSRegularExpression(pattern: #"^[ \t]*[│┌├└|].*$"#, options: .anchorsMatchLines)
        let frame = try! NSRegularExpression(pattern: #"^[ \t│┌├└┬┼┴┐┤┘─|:\-]+$"#)
        var blocks: [TableBlock] = []
        var current: [TableLine] = []
        var expectedStart = -1
        for m in row.matches(in: text as String, range: NSRange(location: 0, length: text.length)) {
            let lineRange = text.lineRange(for: m.range)
            let line = TableLine(range: lineRange, contentLength: m.range.length, isFrame: frame.firstMatch(in: text as String, range: m.range) != nil)
            if lineRange.location != expectedStart, !current.isEmpty { blocks.append(TableBlock(lines: current)); current = [] }
            current.append(line)
            expectedStart = lineRange.upperBound
        }
        if !current.isEmpty { blocks.append(TableBlock(lines: current)) }
        return blocks
    }

    private static func each(_ pattern: String, in storage: NSMutableAttributedString, range: NSRange? = nil, _ apply: (NSTextCheckingResult) -> Void) {
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        regex.matches(in: storage.string, range: range ?? NSRange(location: 0, length: storage.length)).forEach(apply)
    }

    private static func dim(_ storage: NSMutableAttributedString, _ range: NSRange) {
        storage.addAttribute(.foregroundColor, value: inkMuted, range: range)
    }

    private static func addTrait(_ trait: NSFontDescriptor.SymbolicTraits, _ storage: NSMutableAttributedString, _ range: NSRange) {
        storage.enumerateAttribute(.font, in: range) { value, sub, _ in
            let current = value as? NSFont ?? body
            let descriptor = current.fontDescriptor.withSymbolicTraits(current.fontDescriptor.symbolicTraits.union(trait))
            storage.addAttribute(.font, value: NSFont(descriptor: descriptor, size: current.pointSize) ?? current, range: sub)
        }
    }
}
