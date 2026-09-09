import Testing
@testable import KumikoKnowledgeDesk

struct FrontMatterTests {
    @Test func parsesQuotedFieldsCommentsAndLists() {
        let text = """
        ---
        title: "Edge swipe — fix"
        visual_format: infographic # infographic | cheatsheet
        tags: [navigation, gestures]
        deliverables:
          - one
          - "two"
        empty: ""
        ---
        # Heading
        body
        """
        let fm = FrontMatter.parse(text)
        #expect(fm["title"] == "Edge swipe — fix")
        #expect(fm["visual_format"] == "infographic")
        #expect(fm.lists["tags"] == ["navigation", "gestures"])
        #expect(fm.lists["deliverables"] == ["one", "two"])
        #expect(fm["empty"] == nil)
        #expect(fm.body.hasPrefix("# Heading"))
    }

    @Test func toleratesMissingOrUnterminatedFrontMatter() {
        #expect(FrontMatter.parse("# Just markdown").body == "# Just markdown")
        let unterminated = FrontMatter.parse("---\ntitle: x\n# no end")
        #expect(unterminated.fields.isEmpty)
        #expect(unterminated.body.contains("# no end"))
    }

    @Test func handlesWindowsLineEndings() {
        let fm = FrontMatter.parse("---\r\ntitle: \"CRLF\"\r\n---\r\nbody\r\n")
        #expect(fm["title"] == "CRLF")
    }
}
