import Foundation

struct LibraryScanResult: Sendable {
    var items: [KnowledgeItem] = []
    var warnings: [String] = []
}

struct LibraryScanner: Sendable {
    let root: URL

    static let sessionsPath = "sessions"
    static let inboxPath = "handoffs/inbox"
    static let templatePath = "handoffs/TEMPLATE.md"
    static let mediaExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "tif", "svg", "pdf"]

    func scan() -> LibraryScanResult {
        var result = LibraryScanResult()
        let fm = FileManager.default
        let sessions = root.appending(path: LibraryScanner.sessionsPath)
        if let folders = try? fm.contentsOfDirectory(at: sessions, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for folder in folders.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where LibraryScanner.isDirectory(folder) {
                if let item = LibraryScanner.sessionItem(folder: folder, root: root) {
                    result.items.append(item)
                } else {
                    result.warnings.append("Skipped \(folder.lastPathComponent): no Markdown or media found.")
                }
            }
        } else {
            result.warnings.append("No sessions/ folder in this library yet.")
        }
        let inbox = root.appending(path: LibraryScanner.inboxPath)
        if let files = try? fm.contentsOfDirectory(at: inbox, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where file.pathExtension.lowercased() == "md" {
                if let item = LibraryScanner.inboxItem(file: file, root: root) { result.items.append(item) }
            }
        } else {
            result.warnings.append("No handoffs/inbox/ folder in this library yet.")
        }
        result.items.sort { ($0.date ?? .distantPast, $0.title) > ($1.date ?? .distantPast, $1.title) }
        return result
    }

    static func sessionItem(folder: URL, root: URL) -> KnowledgeItem? {
        let handoff = MarkdownDocument.load(folder.appending(path: "handoff.md"))
        let brief = MarkdownDocument.load(folder.appending(path: "visual-brief.md"))
        let pack = MarkdownDocument.load(folder.appending(path: "pr-review-pack.md"))
        let revisions = MarkdownDocument.load(folder.appending(path: "revisions.md"))
        let media = mediaAssets(in: folder.appending(path: "media"), root: root)
        guard handoff != nil || brief != nil || pack != nil || !media.isEmpty else { return nil }

        let slug = folder.lastPathComponent
        let docs = [handoff, brief, pack, revisions].compactMap { $0 }
        let format = handoff?.frontMatter["visual_format"] ?? brief?.frontMatter["format"]
        let isPack = pack != nil || format == "pr-review-pack"
        let status = brief?.frontMatter["status"] ?? handoff?.frontMatter["status"]
        let title = handoff?.frontMatter["title"] ?? brief?.firstHeading ?? pack?.firstHeading ?? humanize(slug)
        let takeaway = handoff?.section(titled: "One-line takeaway")?.firstParagraph
            ?? brief?.section(titled: "Core message")?.firstParagraph
            ?? pack?.section(titled: "Reviewer TL;DR")?.firstParagraph
            ?? brief.flatMap { MarkdownDocument.firstParagraph(of: $0.preamble) }
            ?? brief?.sections.first(where: { !$0.isEmpty })?.firstParagraph
        let date = date(fromSessionID: slug) ?? handoff?.frontMatter["created_at"].flatMap(parseDate) ?? modificationDate(folder)
        let artifactIndex = folder.appending(path: "artifact/index.html")
        let artifactURL = FileManager.default.fileExists(atPath: artifactIndex.path) ? artifactIndex : nil
        let hasOpenFeedback = revisions?.body.contains("- [ ] ") ?? false
        let completion: CompletionState = hasOpenFeedback ? .needsAttention : (!media.isEmpty && (status ?? "").lowercased().contains("generated")) ? .delivered : .inProgress
        let allText = docs.map(\.body).joined(separator: "\n")
        let evidenceSource = handoff?.section(titled: "Evidence") ?? brief?.sections.first { MarkdownDocument.normalizedTitle($0.title).contains("evidence") || MarkdownDocument.normalizedTitle($0.title).contains("verification") }
        let accuracy = (handoff?.section(titled: "Accuracy check")?.bullets ?? []) + (brief?.section(titled: "Exclusions").map { section in section.bullets.isEmpty ? [section.body] : section.bullets } ?? [])
        let refs = KnowledgeExtractor.pathsAndSymbols(in: allText)
        let files = [handoff, brief, pack, revisions].compactMap { $0?.url }

        return KnowledgeItem(
            id: "\(sessionsPath)/\(slug)",
            kind: .session,
            folderURL: folder,
            primaryFileURL: handoff?.url ?? brief?.url ?? pack?.url ?? folder,
            title: title,
            takeaway: takeaway,
            date: date,
            format: format,
            sourceRepo: handoff?.frontMatter["source_repo"] ?? brief?.frontMatter["source_repo"],
            status: status,
            audience: handoff?.frontMatter["audience"] ?? brief?.frontMatter["audience"],
            tags: tags(from: docs),
            isPRReviewPack: isPack,
            media: media,
            artifactURL: artifactURL,
            sourceFiles: files,
            handoff: handoff,
            visualBrief: brief,
            prReviewPack: pack,
            revisions: revisions,
            evidence: evidenceItems(from: evidenceSource),
            accuracyConstraints: accuracy.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            identifiers: KnowledgeExtractor.identifiers(in: title + "\n" + slug + "\n" + allText),
            symbols: refs.symbols,
            paths: refs.paths,
            modifiedAt: latestModification(in: folder),
            completion: completion
        )
    }

    static func inboxItem(file: URL, root: URL) -> KnowledgeItem? {
        guard let doc = MarkdownDocument.load(file) else { return nil }
        let slug = file.deletingPathExtension().lastPathComponent
        let status = doc.frontMatter["status"]
        let isQuestion = status?.lowercased() == "question" || doc.frontMatter["kind"]?.lowercased() == "question"
        let title = doc.frontMatter["title"] ?? doc.firstHeading ?? humanize(slug)
        let takeaway = doc.section(titled: "One-line takeaway")?.firstParagraph ?? doc.section(titled: "Question")?.firstParagraph ?? MarkdownDocument.firstParagraph(of: doc.preamble)
        let refs = KnowledgeExtractor.pathsAndSymbols(in: doc.body)
        let format = doc.frontMatter["visual_format"]
        let modified = modificationDate(file)
        return KnowledgeItem(
            id: "\(inboxPath)/\(file.lastPathComponent)",
            kind: .inboxHandoff,
            folderURL: file.deletingLastPathComponent(),
            primaryFileURL: file,
            title: title,
            takeaway: takeaway,
            date: doc.frontMatter["created_at"].flatMap(parseDate) ?? modified,
            format: format,
            sourceRepo: doc.frontMatter["source_repo"],
            status: status ?? "inbox",
            audience: doc.frontMatter["audience"],
            tags: tags(from: [doc]),
            isPRReviewPack: format == "pr-review-pack",
            media: [],
            artifactURL: nil,
            sourceFiles: [file],
            handoff: doc,
            visualBrief: nil,
            prReviewPack: nil,
            revisions: nil,
            evidence: evidenceItems(from: doc.section(titled: "Evidence")),
            accuracyConstraints: doc.section(titled: "Accuracy check")?.bullets ?? [],
            identifiers: KnowledgeExtractor.identifiers(in: title + "\n" + slug + "\n" + doc.body),
            symbols: refs.symbols,
            paths: refs.paths,
            modifiedAt: modified ?? Date(),
            completion: isQuestion ? .openQuestion : .needsAttention
        )
    }

    static func evidenceItems(from section: MarkdownSection?) -> [EvidenceItem] {
        guard let section else { return [] }
        let bullets = section.bullets.isEmpty ? (section.firstParagraph.map { [$0] } ?? []) : section.bullets
        return bullets.enumerated().map { index, text in
            EvidenceItem(id: index, text: text, references: MarkdownDocument.codeSpans(in: text), isUnverified: KnowledgeExtractor.isUnverified(text))
        }
    }

    static func mediaAssets(in folder: URL, root: URL) -> [MediaAsset] {
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return [] }
        var assets: [MediaAsset] = []
        for case let url as URL in enumerator where mediaExtensions.contains(url.pathExtension.lowercased()) {
            assets.append(MediaAsset(url: url, relativePath: relativePath(of: url, from: root)))
        }
        return assets.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }

    static func relativePath(of url: URL, from root: URL) -> String {
        let full = url.standardizedFileURL.path
        let base = root.standardizedFileURL.path
        return full.hasPrefix(base) ? String(full.dropFirst(base.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/")) : url.lastPathComponent
    }

    static func tags(from docs: [MarkdownDocument]) -> [String] {
        var seen = Set<String>()
        return docs.flatMap { $0.frontMatter.lists["tags"] ?? $0.frontMatter["tags"]?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [] }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    static func humanize(_ slug: String) -> String {
        var s = slug
        if let range = s.range(of: #"^\d{4}-\d{2}-\d{2}--"#, options: .regularExpression) { s.removeSubrange(range) }
        let words = s.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func date(fromSessionID id: String) -> Date? {
        guard id.count >= 10 else { return nil }
        return parseDate(String(id.prefix(10)))
    }

    static func parseDate(_ text: String) -> Date? {
        dayFormatter.date(from: text.trimmingCharacters(in: .whitespaces))
    }

    static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    static func modificationDate(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    static func latestModification(in folder: URL) -> Date {
        var latest = modificationDate(folder) ?? .distantPast
        if let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for case let url as URL in enumerator {
                if let date = modificationDate(url), date > latest { latest = date }
            }
        }
        return latest
    }
}
