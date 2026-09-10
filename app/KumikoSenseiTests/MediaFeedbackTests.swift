import Foundation
import Testing
@testable import KumikoSensei

struct MediaFeedbackTests {
    @Test func appendsPerImageSectionsAndFlagsSessionAsNeedingAttention() throws {
        let root = try Fixtures.temporaryCopyOfPreviewLibrary()
        defer { try? FileManager.default.removeItem(at: root) }
        let session = try #require(LibraryScanner(root: root).scan().items.first { $0.kind == .session && $0.media.count >= 2 })
        let first = session.media[0], second = session.media[1]
        let day = Date(timeIntervalSince1970: 1_757_376_000)

        try MediaFeedback.append("Title too small", for: first, in: session, date: day)
        try MediaFeedback.append("Swap the columns", for: second, in: session, date: day)
        try MediaFeedback.append("Use the mint accent\nnot coral", for: first, in: session, date: day)

        let text = try #require(try? String(contentsOf: MediaFeedback.fileURL(for: session), encoding: .utf8))
        let title = MediaFeedback.sectionTitle(for: first, in: session)
        #expect(title.hasPrefix("media/"))
        #expect(text.components(separatedBy: "## \(title)").count == 2)
        #expect(text.contains(" — Use the mint accent not coral"))
        #expect(text.components(separatedBy: "- [ ] ").count == 4)

        let rescanned = try #require(LibraryScanner(root: root).scan().items.first { $0.id == session.id })
        #expect(rescanned.completion == .needsAttention)
        let entries = MediaFeedback.entries(for: first, in: rescanned)
        #expect(entries.count == 2)
        #expect(entries.first?.text.hasSuffix("Title too small") == true)
        #expect(entries.last?.text.hasSuffix("Use the mint accent not coral") == true)
        let allOpen = entries.allSatisfy(\.isOpen)
        #expect(allOpen)
        #expect(MediaFeedback.entries(for: second, in: rescanned).count == 1)
    }
}
