import Foundation

struct MarkdownSection: Identifiable, Hashable, Sendable {
    let order: Int
    let level: Int
    let title: String
    let body: String

    var id: Int { order }
    var isEmpty: Bool { body.isEmpty }
    var firstParagraph: String? { MarkdownDocument.firstParagraph(of: body) }
    var bullets: [String] { MarkdownDocument.bullets(in: body) }
}

struct MarkdownDocument: Hashable, Sendable {
    let url: URL?
    let frontMatter: FrontMatter
    let preamble: String
    let sections: [MarkdownSection]

    init(text: String, url: URL? = nil) {
        self.url = url
        let fm = FrontMatter.parse(text)
        frontMatter = fm
        let stripped = MarkdownDocument.stripComments(fm.body)
        var sections: [MarkdownSection] = []
        var preambleLines: [String] = []
        var currentTitle: (level: Int, title: String)?
        var currentLines: [String] = []
        var inFence = false
        func flush() {
            if let current = currentTitle {
                sections.append(MarkdownSection(order: sections.count, level: current.level, title: current.title,
                                                body: currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
            } else {
                preambleLines = currentLines
            }
            currentLines = []
        }
        for line in stripped.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") { inFence.toggle() }
            if !inFence, let heading = MarkdownDocument.heading(in: line) {
                flush()
                currentTitle = heading
            } else {
                currentLines.append(line)
            }
        }
        flush()
        self.sections = sections
        preamble = preambleLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func load(_ url: URL) -> MarkdownDocument? {
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return nil }
        return MarkdownDocument(text: text, url: url)
    }

    var body: String { frontMatter.body }
    var fileName: String { url?.lastPathComponent ?? "" }
    var firstHeading: String? { sections.first?.title }

    func section(titled title: String) -> MarkdownSection? {
        let wanted = MarkdownDocument.normalizedTitle(title)
        return sections.first { MarkdownDocument.normalizedTitle($0.title).hasPrefix(wanted) }
    }

    func sections(excluding titles: [String]) -> [MarkdownSection] {
        let excluded = titles.map(MarkdownDocument.normalizedTitle)
        return sections.filter { section in
            let normalized = MarkdownDocument.normalizedTitle(section.title)
            return !excluded.contains { normalized.hasPrefix($0) }
        }
    }

    static func normalizedTitle(_ title: String) -> String {
        var t = title.lowercased()
        if let paren = t.firstIndex(of: "(") { t = String(t[..<paren]) }
        t = t.replacingOccurrences(of: "→", with: "->").replacingOccurrences(of: "—", with: "-")
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func heading(in line: String) -> (level: Int, title: String)? {
        var level = 0
        var index = line.startIndex
        while index < line.endIndex, line[index] == "#" { level += 1; index = line.index(after: index) }
        guard level > 0, level <= 6, index < line.endIndex, line[index] == " " else { return nil }
        let title = line[index...].trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? nil : (level, title)
    }

    static func stripComments(_ text: String) -> String {
        var result = text
        while let start = result.range(of: "<!--") {
            guard let end = result.range(of: "-->", range: start.upperBound..<result.endIndex) else {
                result.removeSubrange(start.lowerBound...)
                break
            }
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result
    }

    static func firstParagraph(of body: String) -> String? {
        var paragraph: [String] = []
        var inFence = false
        for line in body.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inFence.toggle(); continue }
            if inFence { continue }
            if trimmed.isEmpty {
                if !paragraph.isEmpty { break }
                continue
            }
            if heading(in: trimmed) != nil { if paragraph.isEmpty { continue } else { break } }
            paragraph.append(trimmed)
        }
        let joined = paragraph.joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    static func bullets(in body: String) -> [String] {
        var items: [String] = []
        var inFence = false
        for line in body.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { inFence.toggle(); continue }
            if inFence { continue }
            let leading = line.prefix { $0 == " " || $0 == "\t" }.count
            if let marker = listMarker(trimmed) {
                if leading >= 2, var last = items.popLast() {
                    last += "\n" + trimmed
                    items.append(last)
                } else {
                    items.append(String(trimmed.dropFirst(marker)))
                }
            } else if !trimmed.isEmpty, leading >= 2, var last = items.popLast() {
                last += " " + trimmed
                items.append(last)
            }
        }
        return items.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    static func listMarker(_ trimmed: String) -> Int? {
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") { return 2 }
        let digits = trimmed.prefix { $0.isNumber }
        if !digits.isEmpty, trimmed.dropFirst(digits.count).hasPrefix(". ") { return digits.count + 2 }
        return nil
    }

    static func codeSpans(in text: String) -> [String] {
        var spans: [String] = []
        var current: String?
        for character in text {
            if character == "`" {
                if let span = current {
                    let trimmed = span.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty, !trimmed.contains("\n") { spans.append(trimmed) }
                    current = nil
                } else {
                    current = ""
                }
            } else {
                current?.append(character)
            }
        }
        return spans
    }
}

enum KnowledgeExtractor {
    static let identifierPattern = try! NSRegularExpression(pattern: #"\b[A-Z][A-Z0-9]{1,9}-\d{2,7}\b|\bPR\s?#\d+\b|(?<![\w/])#\d{2,7}\b"#)
    static let commitPattern = try! NSRegularExpression(pattern: #"\b(?=[0-9a-f]*\d)[0-9a-f]{7,40}\b"#)

    static func identifiers(in text: String) -> [String] {
        unique(matches(identifierPattern, in: text) + matches(commitPattern, in: text))
    }

    static func pathsAndSymbols(in text: String) -> (paths: [String], symbols: [String]) {
        var paths: [String] = []
        var symbols: [String] = []
        for span in MarkdownDocument.codeSpans(in: text) {
            if span.contains(" ") && !span.contains("/") { continue }
            if span.contains("/") || span.range(of: #"^[\w.\-]+\.[a-z]{1,5}(:\d+)?$"#, options: .regularExpression) != nil {
                paths.append(span)
            } else if span.range(of: #"^[A-Za-z_$][\w.$]*(\(\))?$"#, options: .regularExpression) != nil {
                symbols.append(span)
            }
        }
        return (unique(paths), unique(symbols))
    }

    static func prNumber(in text: String) -> String? {
        matches(try! NSRegularExpression(pattern: #"PR\s?#?(\d+)"#), in: text).first.flatMap { $0.filter(\.isNumber).isEmpty ? nil : $0.filter(\.isNumber) }
    }

    static func isUnverified(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["not yet", "not performed", "not been performed", "unverified", "proposed", "awaiting", "not verified", "todo"].contains { lower.contains($0) }
    }

    private static func matches(_ regex: NSRegularExpression, in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
