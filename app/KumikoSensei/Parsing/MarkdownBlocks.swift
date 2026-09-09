import Foundation

enum MarkdownBlock: Identifiable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullets([ListItem])
    case numbered([ListItem])
    case code(language: String, text: String)
    case quote(String)
    case table(header: [String], rows: [[String]])
    case rule

    struct ListItem: Hashable { let indent: Int; let text: String }

    var id: Int { hashValue }

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = MarkdownDocument.stripComments(markdown).components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0
        var paragraph: [String] = []
        func flushParagraph() {
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: " "))); paragraph = [] }
        }
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                index += 1
                while index < lines.count, !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") { code.append(lines[index]); index += 1 }
                blocks.append(.code(language: language, text: code.joined(separator: "\n")))
                index += 1
                continue
            }
            if trimmed.isEmpty { flushParagraph(); index += 1; continue }
            if let heading = MarkdownDocument.heading(in: trimmed) {
                flushParagraph(); blocks.append(.heading(level: heading.level, text: heading.title)); index += 1; continue
            }
            if trimmed == "---" || trimmed == "***" { flushParagraph(); blocks.append(.rule); index += 1; continue }
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quote: [String] = []
                while index < lines.count, lines[index].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    quote.append(lines[index].trimmingCharacters(in: .whitespaces).dropFirst().trimmingCharacters(in: .whitespaces)); index += 1
                }
                blocks.append(.quote(quote.joined(separator: " ")))
                continue
            }
            if trimmed.hasPrefix("|"), index + 1 < lines.count, lines[index + 1].trimmingCharacters(in: .whitespaces).range(of: #"^\|?\s*:?-{2,}"#, options: .regularExpression) != nil {
                flushParagraph()
                let header = cells(trimmed)
                index += 2
                var rows: [[String]] = []
                while index < lines.count, lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("|") { rows.append(cells(lines[index])); index += 1 }
                blocks.append(.table(header: header, rows: rows))
                continue
            }
            if let marker = MarkdownDocument.listMarker(trimmed) {
                flushParagraph()
                let numbered = trimmed.first?.isNumber == true
                var items: [ListItem] = []
                while index < lines.count {
                    let current = lines[index]
                    let currentTrimmed = current.trimmingCharacters(in: .whitespaces)
                    let indent = current.prefix { $0 == " " || $0 == "\t" }.count / 2
                    if let m = MarkdownDocument.listMarker(currentTrimmed) {
                        items.append(ListItem(indent: indent, text: String(currentTrimmed.dropFirst(m))))
                    } else if !currentTrimmed.isEmpty, indent >= 1, let last = items.popLast() {
                        items.append(ListItem(indent: last.indent, text: last.text + " " + currentTrimmed))
                    } else {
                        break
                    }
                    index += 1
                }
                _ = marker
                blocks.append(numbered ? .numbered(items) : .bullets(items))
                continue
            }
            paragraph.append(trimmed)
            index += 1
        }
        flushParagraph()
        return blocks
    }

    private static func cells(_ line: String) -> [String] {
        var t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("|") { t.removeFirst() }
        if t.hasSuffix("|") { t.removeLast() }
        return t.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
