import AppKit
import Foundation

enum FolderAccess {
    static let bookmarkKey = "libraryBookmark"

    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Choose the Cheatbook folder that contains sessions/ and handoffs/. The app reads it in place and never uploads it."
        panel.prompt = "Open Library"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    static func restoreBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale { try? saveBookmark(for: url) }
        return url
    }

    static func forgetBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    static func looksLikeCheatbook(_ url: URL) -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: url.appending(path: "sessions").path) || fm.fileExists(atPath: url.appending(path: "handoffs").path)
    }

    static func installSampleLibrary() throws -> URL {
        guard let source = Bundle.main.url(forResource: "PreviewLibrary", withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let fm = FileManager.default
        let support = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let destination = support.appending(path: "KumikoSensei/SampleLibrary")
        if fm.fileExists(atPath: destination.path) { try fm.removeItem(at: destination) }
        try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.copyItem(at: source, to: destination)
        return destination
    }

    static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openInEditor(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
