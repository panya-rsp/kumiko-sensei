import AppKit
import Testing
@testable import KumikoSensei

struct MarkdownStylerTests {
    @Test func stylesHeadingBoldAndCodeInPlace() {
        let storage = NSTextStorage(string: "# Title\nplain **bold** `code`")
        MarkdownStyler.restyle(storage)
        #expect(storage.string == "# Title\nplain **bold** `code`")
        let heading = storage.attribute(.font, at: 2, effectiveRange: nil) as! NSFont
        #expect(heading.pointSize > MarkdownStyler.body.pointSize)
        let bold = storage.attribute(.font, at: 16, effectiveRange: nil) as! NSFont
        #expect(bold.fontDescriptor.symbolicTraits.contains(.bold))
        let code = storage.attribute(.font, at: 24, effectiveRange: nil) as! NSFont
        #expect(code.fontDescriptor.symbolicTraits.contains(.monoSpace))
        let plain = storage.attribute(.font, at: 9, effectiveRange: nil) as! NSFont
        #expect(plain == MarkdownStyler.body)
    }
}

extension MarkdownStylerTests {
    @Test func hidesMarkersOffTheCaretLineOnly() {
        let storage = NSTextStorage(string: "# Title\n**bold**")
        MarkdownStyler.restyle(storage, caret: NSRange(location: 12, length: 0))
        let hiddenHash = storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as! NSColor
        #expect(hiddenHash == NSColor.clear)
        let shownStars = storage.attribute(.foregroundColor, at: 8, effectiveRange: nil) as! NSColor
        #expect(shownStars != NSColor.clear)
        #expect(storage.string == "# Title\n**bold**")
    }
}

extension MarkdownStylerTests {
    @Test func rendersBoxTableAsGridOffCaret() {
        let table = "┌────┬────┐\n│ a  │ b  │\n├────┼────┤\n│ 1  │ 2  │\n└────┴────┘"
        let storage = NSTextStorage(string: "note\n" + table)
        MarkdownStyler.restyle(storage, caret: NSRange(location: 0, length: 0), width: 200)
        #expect(MarkdownStyler.tableBlocks(in: storage.string as NSString).count == 1)
        let frame = storage.attribute(.font, at: 5, effectiveRange: nil) as! NSFont
        #expect(frame.pointSize < 1)
        let header = storage.attribute(.font, at: 19, effectiveRange: nil) as! NSFont
        #expect(header.fontDescriptor.symbolicTraits.contains(.bold))
        #expect(header.fontDescriptor.symbolicTraits.contains(.monoSpace))
        let pipe = storage.attribute(.foregroundColor, at: 17, effectiveRange: nil) as! NSColor
        #expect(pipe == NSColor.clear)
        MarkdownStyler.restyle(storage, caret: NSRange(location: 20, length: 0), width: 200)
        let shownPipe = storage.attribute(.foregroundColor, at: 17, effectiveRange: nil) as! NSColor
        #expect(shownPipe != NSColor.clear)
        #expect(storage.string == "note\n" + table)
    }
}
