import Foundation

enum HandoffFormat: String, CaseIterable, Identifiable {
    case infographic, cheatsheet, bento, presentation
    case prReviewPack = "pr-review-pack"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .prReviewPack: return "PR review pack"
        default: return rawValue.capitalized
        }
    }
}

struct HandoffDraft {
    var title = ""
    var slug = ""
    var sourceRepo = ""
    var branchOrCommit = ""
    var takeaway = ""
    var context = ""
    var story = ""
    var beforeAfter = ""
    var evidence = ""
    var decisions = ""
    var caveats = ""
    var visualRequest = ""
    var format: HandoffFormat = .infographic
    var audience = "developer"
    var reviewerTakeaway = ""
    var whyItMatters = ""
    var reviewFocus = ""
    var prPlacement = ""
}

struct AskKumikoDraft {
    let fileURL: URL
    let prompt: String
}

struct HandoffComposer {
    enum ComposerError: LocalizedError {
        case invalidSlug, exists(URL), missingTitle, missingQuestion

        var errorDescription: String? {
            switch self {
            case .invalidSlug: return "Slug must use lowercase letters, numbers, and single hyphens."
            case .exists(let url): return "A handoff already exists at \(url.lastPathComponent)."
            case .missingTitle: return "Give the handoff a title."
            case .missingQuestion: return "Write the question first."
            }
        }
    }

    let root: URL
    var today: Date = Date()

    var inboxURL: URL { root.appending(path: LibraryScanner.inboxPath) }

    static func slugify(_ text: String) -> String {
        let lowered = text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        let replaced = lowered.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        let collapsed = replaced.replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    static func isValidSlug(_ slug: String) -> Bool {
        slug.range(of: #"^[a-z0-9]+(-[a-z0-9]+)*$"#, options: .regularExpression) != nil
    }

    func templateText() -> String {
        let url = root.appending(path: LibraryScanner.templatePath)
        if let text = try? String(contentsOf: url, encoding: .utf8) { return text }
        return HandoffComposer.fallbackTemplate
    }

    func render(_ draft: HandoffDraft) -> String {
        var text = templateText()
        let date = LibraryScanner.dayFormatter.string(from: today)
        text = replaceField(in: text, key: "title", value: quoted(draft.title))
        text = replaceField(in: text, key: "slug", value: quoted(draft.slug))
        text = replaceField(in: text, key: "source_repo", value: quoted(draft.sourceRepo))
        text = replaceField(in: text, key: "branch_or_commit", value: quoted(draft.branchOrCommit))
        text = replaceField(in: text, key: "created_at", value: quoted(date))
        text = replaceField(in: text, key: "visual_format", value: draft.format.rawValue)
        text = replaceField(in: text, key: "audience", value: draft.audience.isEmpty ? "developer" : draft.audience)

        text = fill(section: "One-line takeaway", in: text, with: draft.takeaway)
        text = fill(section: "Goal and context", in: text, with: draft.context)
        text = fill(section: "The story", in: text, with: draft.story)
        text = fill(section: "Before", in: text, with: draft.beforeAfter)
        text = fill(section: "Evidence to verify", in: text, with: bulletize(draft.evidence), replacingPlaceholderBullet: true)
        text = fill(section: "Key decisions", in: text, with: draft.decisions)
        text = fill(section: "Caveats", in: text, with: draft.caveats)
        text = fill(section: "Visual request", in: text, with: draft.visualRequest)
        if draft.format == .prReviewPack {
            let pack = """
            ### Reviewer takeaway
            \(draft.reviewerTakeaway)

            ### Why this matters
            \(draft.whyItMatters)

            ### Review focus
            \(bulletize(draft.reviewFocus))

            ### PR placement
            \(draft.prPlacement)
            """
            text = fill(section: "PR review pack", in: text, with: pack)
        }
        return text
    }

    func write(_ draft: HandoffDraft) throws -> URL {
        guard !draft.title.trimmingCharacters(in: .whitespaces).isEmpty else { throw ComposerError.missingTitle }
        guard HandoffComposer.isValidSlug(draft.slug) else { throw ComposerError.invalidSlug }
        let destination = inboxURL.appending(path: "\(draft.slug).md")
        try FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw ComposerError.exists(destination) }
        try Data(render(draft).utf8).write(to: destination, options: .withoutOverwriting)
        return destination
    }

    func writeQuestion(_ question: String, about items: [KnowledgeItem]) throws -> AskKumikoDraft {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ComposerError.missingQuestion }
        let date = LibraryScanner.dayFormatter.string(from: today)
        var slug = "ask-kumiko--" + String(HandoffComposer.slugify(trimmed).prefix(48)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if slug == "ask-kumiko--" { slug += date }
        var destination = inboxURL.appending(path: "\(slug).md")
        var counter = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = inboxURL.appending(path: "\(slug)-\(counter).md")
            counter += 1
        }
        let repos = Array(Set(items.compactMap(\.repositoryName))).sorted().joined(separator: ", ")
        var lines: [String] = [
            "---",
            "title: \(quoted("Question: " + trimmed.prefix(80)))",
            "slug: \(quoted(destination.deletingPathExtension().lastPathComponent))",
            "source_repo: \(quoted(repos))",
            "branch_or_commit: \"\"",
            "created_at: \(quoted(date))",
            "status: question",
            "visual_format: cheatsheet",
            "audience: developer",
            "---",
            "",
            "# Question",
            "",
            trimmed,
            "",
            "## Referenced sessions",
            "",
        ]
        if items.isEmpty {
            lines.append("- No sessions were attached. Answer from the library as a whole.")
        }
        for item in items {
            lines.append("- `\(item.id)` — \(item.title)")
            if let takeaway = item.takeaway { lines.append("  - takeaway: \(takeaway)") }
            for evidence in item.evidence.prefix(6) {
                lines.append("  - evidence: \(evidence.text.components(separatedBy: "\n").first ?? evidence.text)")
            }
        }
        lines += [
            "",
            "## Expected answer",
            "",
            "Write the answer as attributable Markdown in a new `sessions/` folder. Separate verified facts, proposals, and unresolved questions. Cite the referenced session files and evidence paths. Do not access GitHub, organization systems, or any source outside this library unless the user provides it.",
            "",
        ]
        try FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        try Data(lines.joined(separator: "\n").utf8).write(to: destination, options: .withoutOverwriting)
        let relative = LibraryScanner.relativePath(of: destination, from: root)
        let prompt = "Open Cheatbook in Codex and ask: “Read and follow `agents/kumiko-sensei.md`. Answer the question in `\(relative)` using only the referenced sessions and their evidence. Save the answer as Markdown in a new session folder, separate verified facts from proposals and open questions, and do not generate media unless asked.”"
        return AskKumikoDraft(fileURL: destination, prompt: prompt)
    }

    private func quoted(_ value: any StringProtocol) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "'") + "\""
    }

    private func replaceField(in text: String, key: String, value: String) -> String {
        let pattern = "(?m)^\(NSRegularExpression.escapedPattern(for: key)):.*$"
        let replacement = NSRegularExpression.escapedTemplate(for: "\(key): \(value)")
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        if regex.firstMatch(in: text, range: range) == nil {
            return text.replacingOccurrences(of: "\n---\n", with: "\n\(key): \(value)\n---\n", options: [], range: text.range(of: "\n---\n"))
        }
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }

    private func fill(section title: String, in text: String, with content: String, replacingPlaceholderBullet: Bool = false) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }
        var lines = text.components(separatedBy: "\n")
        let wanted = MarkdownDocument.normalizedTitle(title)
        guard let headingIndex = lines.firstIndex(where: { line in
            guard let heading = MarkdownDocument.heading(in: line) else { return false }
            return MarkdownDocument.normalizedTitle(heading.title).hasPrefix(wanted)
        }) else { return text }
        var insertAt = headingIndex + 1
        var inComment = false
        while insertAt < lines.count {
            let line = lines[insertAt].trimmingCharacters(in: .whitespaces)
            if MarkdownDocument.heading(in: line) != nil && !inComment { break }
            if line.hasPrefix("<!--") { inComment = !line.contains("-->") ; insertAt += 1; continue }
            if inComment { if line.contains("-->") { inComment = false }; insertAt += 1; continue }
            if line.isEmpty { insertAt += 1; continue }
            if replacingPlaceholderBullet, line.hasPrefix("- `path/to/") { lines.remove(at: insertAt); continue }
            break
        }
        lines.insert(contentsOf: [trimmed, ""], at: insertAt)
        return lines.joined(separator: "\n")
    }

    private func bulletize(_ text: String) -> String {
        text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            .map { $0.hasPrefix("- ") || $0.hasPrefix("* ") ? $0 : "- \($0)" }.joined(separator: "\n")
    }

    static let fallbackTemplate = """
    ---
    title: ""
    slug: ""
    source_repo: ""
    branch_or_commit: ""
    created_at: "YYYY-MM-DD"
    status: ready
    visual_format: infographic # infographic | cheatsheet | bento | presentation | pr-review-pack
    audience: developer
    ---

    # One-line takeaway

    ## Goal and context

    ## The story: what happened and why

    ## Before → after

    ## Evidence to verify

    - `path/to/file.ts`: `symbolName` — what it proves

    ## Key decisions and trade-offs

    ## Caveats and non-goals

    ## Visual request

    ## PR review pack (required when visual_format is pr-review-pack)

    ## Section plan (optional, required for multi-page work)

    ## Accuracy check

    """
}
