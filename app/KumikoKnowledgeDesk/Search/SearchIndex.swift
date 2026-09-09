import Foundation

enum SearchField: CaseIterable, Sendable {
    case title, identifiers, filename, takeaway, evidence, symbols, reviewGuide, tags, repo, body

    var weight: Double {
        switch self {
        case .title: return 10
        case .identifiers: return 9
        case .filename: return 7
        case .takeaway: return 6
        case .evidence: return 5
        case .symbols: return 5
        case .reviewGuide: return 4
        case .tags: return 4
        case .repo: return 3
        case .body: return 1
        }
    }

    var label: String {
        switch self {
        case .title: return "title"
        case .identifiers: return "identifier"
        case .filename: return "file name"
        case .takeaway: return "takeaway"
        case .evidence: return "evidence"
        case .symbols: return "symbol or path"
        case .reviewGuide: return "review guide"
        case .tags: return "tag"
        case .repo: return "repository"
        case .body: return "text"
        }
    }
}

struct SearchDocument: Sendable {
    let itemID: String
    let fields: [SearchField: String]
    let originalFields: [SearchField: String]

    init(item: KnowledgeItem) {
        itemID = item.id
        var fields: [SearchField: String] = [:]
        fields[.title] = item.title
        fields[.identifiers] = item.identifiers.joined(separator: " ")
        fields[.filename] = ([item.id] + item.sourceFiles.map(\.lastPathComponent) + item.media.map(\.relativePath)).joined(separator: " ")
        fields[.takeaway] = item.takeaway ?? ""
        fields[.evidence] = item.evidence.map(\.text).joined(separator: "\n")
        fields[.symbols] = (item.symbols + item.paths).joined(separator: " ")
        fields[.reviewGuide] = item.reviewGuideSections.map { $0.title + "\n" + $0.body }.joined(separator: "\n")
        fields[.tags] = item.tags.joined(separator: " ")
        fields[.repo] = item.sourceRepo ?? ""
        fields[.body] = [item.handoff, item.visualBrief, item.prReviewPack, item.revisions].compactMap { $0?.body }.joined(separator: "\n")
        originalFields = fields
        self.fields = fields.mapValues { $0.lowercased() }
    }
}

struct SearchHit: Identifiable, Sendable {
    let item: KnowledgeItem
    let score: Double
    let excerpt: String
    let matchedField: SearchField
    var id: String { item.id }
}

protocol SearchProvider: Sendable {
    func search(_ query: String, in index: SearchIndex) -> [SearchHit]
}

struct SearchIndex: Sendable {
    private(set) var documents: [SearchDocument] = []
    private(set) var itemsByID: [String: KnowledgeItem] = [:]

    init(items: [KnowledgeItem] = []) { rebuild(items: items) }

    mutating func rebuild(items: [KnowledgeItem]) {
        documents = items.map(SearchDocument.init)
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    var isEmpty: Bool { documents.isEmpty }
}

struct LexicalSearchProvider: SearchProvider {
    func search(_ query: String, in index: SearchIndex) -> [SearchHit] {
        let terms = query.lowercased().split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { !$0.isEmpty }
        guard !terms.isEmpty else { return [] }
        var hits: [SearchHit] = []
        for document in index.documents {
            guard let item = index.itemsByID[document.itemID] else { continue }
            var score = 0.0
            var best: (field: SearchField, term: String)?
            var allTermsMatched = true
            for term in terms {
                var bestWeight = 0.0
                var totalOccurrences = 0
                for field in SearchField.allCases {
                    guard let text = document.fields[field], !text.isEmpty else { continue }
                    let count = occurrences(of: term, in: text)
                    guard count > 0 else { continue }
                    totalOccurrences += count
                    var weight = field.weight
                    if field == .title, text.hasPrefix(term) { weight += 5 }
                    if weight > bestWeight {
                        bestWeight = weight
                        if best == nil || field.weight > best!.field.weight { best = (field, term) }
                    }
                }
                if bestWeight == 0 { allTermsMatched = false; break }
                score += bestWeight + 0.1 * Double(min(totalOccurrences, 10))
            }
            guard allTermsMatched, let best else { continue }
            if let title = document.fields[.title], terms.allSatisfy({ title.contains($0) }) { score += 20 }
            hits.append(SearchHit(item: item, score: score, excerpt: excerpt(for: terms.first ?? best.term, in: document, preferring: best.field), matchedField: best.field))
        }
        return hits.sorted { ($0.score, $0.item.date ?? .distantPast) > ($1.score, $1.item.date ?? .distantPast) }
    }

    private func occurrences(of term: String, in text: String) -> Int {
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: term, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }

    private func excerpt(for term: String, in document: SearchDocument, preferring field: SearchField) -> String {
        let order: [SearchField] = [.takeaway, .evidence, .reviewGuide, .body, .symbols, .identifiers, .filename, .repo, .tags, .title]
        for candidate in order {
            guard let text = document.originalFields[candidate], let range = text.range(of: term, options: .caseInsensitive) else { continue }
            if candidate == .title { return document.originalFields[.takeaway] ?? "" }
            let start = text.index(range.lowerBound, offsetBy: -70, limitedBy: text.startIndex) ?? text.startIndex
            let end = text.index(range.upperBound, offsetBy: 90, limitedBy: text.endIndex) ?? text.endIndex
            var snippet = String(text[start..<end]).replacingOccurrences(of: "\n", with: " ")
            snippet = snippet.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            return (start > text.startIndex ? "…" : "") + snippet + (end < text.endIndex ? "…" : "")
        }
        return document.originalFields[.takeaway] ?? ""
    }
}
