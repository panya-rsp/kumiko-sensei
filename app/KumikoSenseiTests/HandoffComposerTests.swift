import Foundation
import Testing
@testable import KumikoSensei

struct HandoffComposerTests {
    @Test func slugify() {
        #expect(HandoffComposer.slugify("Edge Swipe: Fix #2!") == "edge-swipe-fix-2")
        #expect(HandoffComposer.isValidSlug("edge-swipe-fix"))
        #expect(!HandoffComposer.isValidSlug("Edge--swipe"))
    }

    @Test func writesTemplateCompatiblePRReviewPackHandoff() throws {
        let root = try Fixtures.temporaryCopyOfPreviewLibrary()
        defer { try? FileManager.default.removeItem(at: root) }
        var draft = HandoffDraft()
        draft.title = "Composer test"
        draft.slug = "composer-test"
        draft.sourceRepo = "sample-repo"
        draft.takeaway = "One sentence."
        draft.evidence = "src/a.swift: `foo()`\n- already bulleted"
        draft.format = .prReviewPack
        draft.reviewerTakeaway = "Problem, decision, outcome."
        draft.reviewFocus = "src/a.swift"
        let url = try HandoffComposer(root: root).write(draft)
        #expect(url.lastPathComponent == "composer-test.md")
        let doc = MarkdownDocument.load(url)!
        #expect(doc.frontMatter["title"] == "Composer test")
        #expect(doc.frontMatter["visual_format"] == "pr-review-pack")
        #expect(doc.frontMatter["created_at"]?.count == 10)
        #expect(doc.section(titled: "One-line takeaway")?.firstParagraph == "One sentence.")
        #expect(doc.section(titled: "Evidence")?.bullets == ["src/a.swift: `foo()`", "already bulleted"])
        #expect(doc.section(titled: "Reviewer takeaway")?.firstParagraph == "Problem, decision, outcome.")
        let scanned = LibraryScanner(root: root).scan().items.first { $0.id == "handoffs/inbox/composer-test.md" }
        #expect(scanned?.isPRReviewPack == true)
        #expect(throws: HandoffComposer.ComposerError.self) { try HandoffComposer(root: root).write(draft) }
    }

    @Test func writesAskKumikoQuestionDraft() throws {
        let root = try Fixtures.temporaryCopyOfPreviewLibrary()
        defer { try? FileManager.default.removeItem(at: root) }
        let items = LibraryScanner(root: root).scan().items.filter { $0.isPRReviewPack }
        let draft = try HandoffComposer(root: root).writeQuestion("Why did the registry call handlers.last?", about: items)
        #expect(draft.fileURL.lastPathComponent.hasPrefix("ask-kumiko--why-did-the-registry"))
        #expect(draft.prompt.contains(draft.fileURL.lastPathComponent))
        let scanned = LibraryScanner(root: root).scan().items.first { $0.primaryFileURL == draft.fileURL }
        #expect(scanned?.completion == .openQuestion)
        #expect(scanned?.takeaway == "Why did the registry call handlers.last?")
    }
}
