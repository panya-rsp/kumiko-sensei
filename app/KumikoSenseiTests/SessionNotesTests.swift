import Foundation
import Testing
@testable import KumikoSensei

struct SessionNotesTests {
    @Test func roundTripsBesideSessionAndDeletesWhenBlank() throws {
        let root = try Fixtures.temporaryCopyOfPreviewLibrary()
        defer { try? FileManager.default.removeItem(at: root) }
        let items = LibraryScanner(root: root).scan().items
        let session = try #require(items.first { $0.kind == .session })
        let inbox = try #require(items.first { $0.kind == .inboxHandoff })

        try SessionNotes.save("thinking out loud", for: session, root: root)
        #expect(SessionNotes.url(for: session, root: root) == session.folderURL.appending(path: "notes.md"))
        #expect(SessionNotes.load(for: session, root: root) == "thinking out loud")

        try SessionNotes.save("inbox thought", for: inbox, root: root)
        #expect(SessionNotes.url(for: inbox, root: root).path.contains("/handoffs/notes/"))
        #expect(SessionNotes.load(for: inbox, root: root) == "inbox thought")
        #expect(LibraryScanner(root: root).scan().items.count == items.count)

        try SessionNotes.save("  \n", for: session, root: root)
        #expect(!FileManager.default.fileExists(atPath: SessionNotes.url(for: session, root: root).path))
    }
}
