import Foundation

enum KnowledgeKind: String, Sendable {
    case session
    case inboxHandoff
}

enum CompletionState: Sendable {
    case delivered
    case inProgress
    case needsAttention
    case openQuestion

    var label: String {
        switch self {
        case .delivered: return "Delivered"
        case .inProgress: return "In progress"
        case .needsAttention: return "Needs attention"
        case .openQuestion: return "Open question"
        }
    }
}

struct EvidenceItem: Identifiable, Hashable, Sendable {
    let id: Int
    let text: String
    let references: [String]
    let isUnverified: Bool
}

struct MediaAsset: Identifiable, Hashable, Sendable {
    let url: URL
    let relativePath: String
    var id: String { relativePath }
    var fileName: String { url.lastPathComponent }
}

struct KnowledgeItem: Identifiable, Sendable {
    let id: String
    let kind: KnowledgeKind
    let folderURL: URL
    let primaryFileURL: URL
    let title: String
    let takeaway: String?
    let date: Date?
    let format: String?
    let sourceRepo: String?
    let status: String?
    let audience: String?
    let tags: [String]
    let isPRReviewPack: Bool
    let media: [MediaAsset]
    let artifactURL: URL?
    let sourceFiles: [URL]
    let handoff: MarkdownDocument?
    let visualBrief: MarkdownDocument?
    let prReviewPack: MarkdownDocument?
    let revisions: MarkdownDocument?
    let evidence: [EvidenceItem]
    let accuracyConstraints: [String]
    let identifiers: [String]
    let symbols: [String]
    let paths: [String]
    let modifiedAt: Date
    let completion: CompletionState

    static let explanationExclusions = ["One-line takeaway", "Evidence", "Visual request", "PR review pack", "Section plan", "Accuracy check", "Generated media", "Deliverables"]

    var explanationSections: [MarkdownSection] {
        if let handoff {
            let sections = handoff.sections(excluding: KnowledgeItem.explanationExclusions).filter { !$0.isEmpty }
            if !sections.isEmpty { return sections }
        }
        if let visualBrief {
            return visualBrief.sections(excluding: ["Generated media", "Deliverables"]).filter { !$0.isEmpty }
        }
        return []
    }

    var reviewGuideSections: [MarkdownSection] {
        if let prReviewPack {
            return prReviewPack.sections(excluding: ["Claude Code handoff"]).filter { !$0.isEmpty }
        }
        if let section = handoff?.section(titled: "PR review pack"), !section.isEmpty {
            return [section]
        }
        return []
    }

    var relaySection: MarkdownSection? { prReviewPack?.section(titled: "Claude Code handoff") }

    var repositoryName: String? {
        guard let sourceRepo, !sourceRepo.isEmpty else { return nil }
        let name = sourceRepo.split(separator: "(").first.map(String.init) ?? sourceRepo
        return name.trimmingCharacters(in: .whitespaces)
    }

    var dateText: String {
        guard let date else { return "Undated" }
        return KnowledgeItem.displayFormatter.string(from: date)
    }

    var prNumber: String? {
        for doc in [prReviewPack, handoff, visualBrief].compactMap({ $0 }) {
            if let number = KnowledgeExtractor.prNumber(in: doc.body) { return number }
        }
        return nil
    }

    var relayText: String {
        let pack = prReviewPack?.url?.lastPathComponent ?? "pr-review-pack.md"
        let mediaPath = media.first?.relativePath ?? "<media path>"
        let pr = prNumber.map { "PR #\($0)" } ?? "PR #…"
        return "Read this session's `\(pack)` at `\(folderURL.path)`, publish its referenced media (`\(mediaPath)`) using your authorized GitHub session, and insert the generated Markdown at the top of \(pr)."
    }

    static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

extension KnowledgeItem: Hashable {
    static func == (lhs: KnowledgeItem, rhs: KnowledgeItem) -> Bool { lhs.id == rhs.id && lhs.modifiedAt == rhs.modifiedAt }
    func hash(into hasher: inout Hasher) { hasher.combine(id); hasher.combine(modifiedAt) }
}
