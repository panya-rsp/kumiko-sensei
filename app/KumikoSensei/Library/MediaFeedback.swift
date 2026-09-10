import Foundation

struct MediaFeedbackEntry: Identifiable, Hashable {
    let id: Int
    let text: String
    let isOpen: Bool
}

enum MediaFeedback {
    static func fileURL(for item: KnowledgeItem) -> URL { item.folderURL.appending(path: "revisions.md") }

    static func sectionTitle(for asset: MediaAsset, in item: KnowledgeItem) -> String {
        let folder = item.folderURL.standardizedFileURL.path + "/"
        let path = asset.url.standardizedFileURL.path
        return path.hasPrefix(folder) ? String(path.dropFirst(folder.count)) : asset.relativePath
    }

    static func entries(for asset: MediaAsset, in item: KnowledgeItem) -> [MediaFeedbackEntry] {
        guard let section = item.revisions?.sections.first(where: { $0.title == sectionTitle(for: asset, in: item) }) else { return [] }
        return section.body.components(separatedBy: "\n").enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ] ") { return MediaFeedbackEntry(id: index, text: String(trimmed.dropFirst(6)), isOpen: true) }
            if trimmed.hasPrefix("- [x] ") { return MediaFeedbackEntry(id: index, text: String(trimmed.dropFirst(6)), isOpen: false) }
            return nil
        }
    }

    static func append(_ feedback: String, for asset: MediaAsset, in item: KnowledgeItem, date: Date = Date()) throws {
        let text = feedback.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        guard !text.isEmpty else { return }
        let url = fileURL(for: item)
        let heading = "## " + sectionTitle(for: asset, in: item)
        let bullet = "- [ ] \(LibraryScanner.dayFormatter.string(from: date)) — \(text)"
        var lines = ((try? String(contentsOf: url, encoding: .utf8)) ?? "# Revisions\n").components(separatedBy: "\n")
        if let start = lines.firstIndex(of: heading) {
            var end = lines[(start + 1)...].firstIndex { $0.hasPrefix("## ") } ?? lines.count
            while end > start + 1, lines[end - 1].trimmingCharacters(in: .whitespaces).isEmpty { end -= 1 }
            lines.insert(bullet, at: end)
        } else {
            while lines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { lines.removeLast() }
            lines += ["", heading, "", bullet, ""]
        }
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    static func relayCommand(root: URL, item: KnowledgeItem) -> String {
        "\"\(root.appending(path: "scripts/ask-kumiko.sh").path)\" \(item.folderURL.lastPathComponent)"
    }
}
