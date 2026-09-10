import Foundation

enum SessionNotes {
    static func url(for item: KnowledgeItem, root: URL) -> URL {
        switch item.kind {
        case .session:
            return item.folderURL.appending(path: "notes.md")
        case .inboxHandoff:
            return root.appending(path: "handoffs/notes/\(item.primaryFileURL.deletingPathExtension().lastPathComponent).md")
        }
    }

    static func load(for item: KnowledgeItem, root: URL) -> String {
        (try? String(contentsOf: url(for: item, root: root), encoding: .utf8)) ?? ""
    }

    static func save(_ text: String, for item: KnowledgeItem, root: URL) throws {
        let target = url(for: item, root: root)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? FileManager.default.removeItem(at: target)
            return
        }
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: target, atomically: true, encoding: .utf8)
    }
}
