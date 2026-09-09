import Testing
@testable import KumikoSensei

struct MarkdownDocumentTests {
    let sample = """
    ---
    title: "T"
    ---

    # One-line takeaway

    <!-- The single idea. -->

    A `replace` that lands on the route beneath it creates two entries.

    ## Evidence to verify

    - `src/util/router/history.ts`: `push`/`replace` — keeps `idx`
    - Not yet done: the manual walk on a dev build.

    ## Before → after (details)

    ```
    # not a heading
    ```

    | Site | Verdict |
    |---|---|
    | `A.tsx:1` | Safe |
    """

    @Test func splitsSectionsAndIgnoresHeadingsInsideFences() {
        let doc = MarkdownDocument(text: sample)
        #expect(doc.sections.map(\.title) == ["One-line takeaway", "Evidence to verify", "Before → after (details)"])
        #expect(doc.section(titled: "before -> after")?.body.contains("# not a heading") == true)
    }

    @Test func takeawaySkipsComments() {
        let doc = MarkdownDocument(text: sample)
        #expect(doc.section(titled: "One-line takeaway")?.firstParagraph == "A `replace` that lands on the route beneath it creates two entries.")
    }

    @Test func extractsBulletsCodeSpansAndVerificationState() {
        let doc = MarkdownDocument(text: sample)
        let evidence = LibraryScanner.evidenceItems(from: doc.section(titled: "Evidence"))
        #expect(evidence.count == 2)
        #expect(evidence[0].references == ["src/util/router/history.ts", "push", "replace", "idx"])
        #expect(evidence[0].isUnverified == false)
        #expect(evidence[1].isUnverified == true)
    }

    @Test func extractsIdentifiersPathsAndSymbols() {
        let text = "TECH-47948 fixed in PR #482 at 6fd2d8c; see `src/pages/X.tsx:82`, `nav.replace`, `exit()` and `?tab=listing`."
        let ids = KnowledgeExtractor.identifiers(in: text)
        #expect(ids.contains("TECH-47948"))
        #expect(ids.contains("PR #482"))
        #expect(ids.contains("6fd2d8c"))
        let refs = KnowledgeExtractor.pathsAndSymbols(in: text)
        #expect(refs.paths == ["src/pages/X.tsx:82"])
        #expect(refs.symbols == ["nav.replace", "exit()"])
        #expect(KnowledgeExtractor.prNumber(in: text) == "482")
    }

    @Test func blockParserHandlesTablesListsAndCode() {
        let blocks = MarkdownBlock.parse(sample)
        #expect(blocks.contains { if case .table(let header, let rows) = $0 { return header == ["Site", "Verdict"] && rows.count == 1 } else { return false } })
        #expect(blocks.contains { if case .code(_, let code) = $0 { return code == "# not a heading" } else { return false } })
        #expect(blocks.contains { if case .bullets(let items) = $0 { return items.count == 2 } else { return false } })
    }
}
