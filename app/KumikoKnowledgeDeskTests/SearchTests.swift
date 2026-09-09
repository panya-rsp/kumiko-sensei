import Testing
@testable import KumikoKnowledgeDesk

struct SearchTests {
    let index = SearchIndex(items: LibraryScanner(root: Fixtures.previewLibrary).scan().items)
    let provider = LexicalSearchProvider()

    @Test func findsByTicketAndPRIdentifier() {
        #expect(provider.search("APP-1310", in: index).first?.item.id == "handoffs/inbox/sample-cache-key-audit.md")
        #expect(provider.search("#482", in: index).first?.item.id.hasSuffix("sample-edge-swipe-review-pack") == true)
    }

    @Test func findsByEvidencePathAndSymbol() {
        let hits = provider.search("RetryPolicy.swift", in: index)
        #expect(hits.first?.item.id.hasSuffix("sample-retry-lesson") == true)
        #expect(provider.search("attachEdgeSwipe", in: index).first?.item.isPRReviewPack == true)
    }

    @Test func findsReviewGuideTextAndReturnsExcerpt() {
        let hits = provider.search("handlers.last", in: index)
        #expect(hits.count == 1)
        #expect(hits.first?.excerpt.lowercased().contains("handlers.last") == true)
    }

    @Test func requiresAllTermsAndRanksTitleFirst() {
        let cacheHits = provider.search("cache worker", in: index)
        #expect(cacheHits.count == 2)
        #expect(cacheHits.first?.item.id == "sessions/2026-08-20--sample-brief-only-no-media", "both terms in the title outrank scattered body matches")
        #expect(provider.search("cache nonexistentterm", in: index).isEmpty)
        #expect(provider.search("Retry storms", in: index).first?.matchedField == .title)
    }

    @Test func emptyQueryReturnsNothing() {
        #expect(provider.search("   ", in: index).isEmpty)
    }
}
