import Foundation
import Testing
@testable import KumikoSensei

struct LibraryScannerTests {
    @Test func discoversSessionsAndInboxInPreviewLibrary() {
        let result = LibraryScanner(root: Fixtures.previewLibrary).scan()
        let ids = result.items.map(\.id)
        #expect(ids.contains("sessions/2026-08-14--sample-edge-swipe-review-pack"))
        #expect(ids.contains("sessions/2026-08-20--sample-brief-only-no-media"))
        #expect(ids.contains("sessions/2026-08-28--sample-retry-lesson"))
        #expect(ids.contains("handoffs/inbox/sample-cache-key-audit.md"))
        #expect(result.items.count == 4)
        #expect(result.items.first?.id == "handoffs/inbox/sample-cache-key-audit.md", "sorted newest first")
    }

    @Test func derivesPRReviewPackFields() {
        let result = LibraryScanner(root: Fixtures.previewLibrary).scan()
        let pack = result.items.first { $0.id.hasSuffix("sample-edge-swipe-review-pack") }!
        #expect(pack.isPRReviewPack)
        #expect(pack.title == "Edge swipe dismissed the wrong sheet on iOS")
        #expect(pack.takeaway?.hasPrefix("The edge-swipe gesture recognizer") == true)
        #expect(pack.media.map(\.relativePath) == ["sessions/2026-08-14--sample-edge-swipe-review-pack/media/v1-pr-review-pack.png"])
        #expect(pack.completion == .delivered)
        #expect(pack.repositoryName == "sample-mobile-app")
        #expect(pack.tags == ["navigation", "gestures"])
        #expect(pack.prNumber == "482")
        #expect(pack.reviewGuideSections.map(\.title) == ["Reviewer TL;DR", "What changed", "Review guide", "Implementation detail"])
        #expect(pack.relayText.contains("PR #482"))
        #expect(pack.evidence.count == 5)
        #expect(pack.evidence.last?.isUnverified == true)
        #expect(pack.accuracyConstraints.count == 3)
    }

    @Test func toleratesBriefOnlySessionWithoutMedia() {
        let result = LibraryScanner(root: Fixtures.previewLibrary).scan()
        let brief = result.items.first { $0.id.hasSuffix("sample-brief-only-no-media") }!
        #expect(brief.handoff == nil)
        #expect(brief.media.isEmpty)
        #expect(brief.title == "Cache key drift between web and worker")
        #expect(brief.takeaway?.hasPrefix("The web tier hashed cache keys") == true)
        #expect(brief.completion == .inProgress)
        #expect(brief.explanationSections.isEmpty == false)
    }

    @Test func multiPageMediaIsSortedByPage() {
        let result = LibraryScanner(root: Fixtures.previewLibrary).scan()
        let lesson = result.items.first { $0.id.hasSuffix("sample-retry-lesson") }!
        #expect(lesson.media.map(\.fileName) == ["01-problem.png", "02-mechanism.png"])
        #expect(lesson.format == "presentation")
    }

    @Test func inboxItemNeedsAttention() {
        let result = LibraryScanner(root: Fixtures.previewLibrary).scan()
        let inbox = result.items.first { $0.kind == .inboxHandoff }!
        #expect(inbox.completion == .needsAttention)
        #expect(inbox.identifiers.contains("APP-1310"))
        #expect(inbox.date == LibraryScanner.parseDate("2026-09-01"))
    }

    @Test func scanningTheRealCheatbookLibraryDoesNotCrash() {
        guard let root = Fixtures.realLibrary else { return }
        let result = LibraryScanner(root: root).scan()
        #expect(result.items.allSatisfy { !$0.title.isEmpty })
    }
}
