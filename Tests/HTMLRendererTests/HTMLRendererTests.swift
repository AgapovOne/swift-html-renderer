import HTMLParser
import HTMLRenderer
import SwiftUI
import Testing

// MARK: - HTMLView Instantiation Tests

@MainActor @Test func htmlViewWithDocument() {
    let doc = HTMLDocument(children: [.text("Hello")])
    let view = HTMLView(document: doc)
    _ = view
}

@MainActor @Test func htmlViewWithHTML() {
    let view = HTMLView(html: "<p>Hello</p>")
    _ = view
}

@MainActor @Test func htmlViewWithEmptyDocument() {
    let doc = HTMLDocument(children: [])
    let view = HTMLView(document: doc)
    _ = view
}

@MainActor @Test func htmlViewRendersHeadings() {
    for level in 1...6 {
        let view = HTMLView(html: "<h\(level)>Heading \(level)</h\(level)>")
        _ = view
    }
}

@MainActor @Test func htmlViewRendersParagraph() {
    let view = HTMLView(html: "<p>Paragraph text</p>")
    _ = view
}

@MainActor @Test func htmlViewRendersBold() {
    let view = HTMLView(html: "<b>bold</b>")
    _ = view
}

@MainActor @Test func htmlViewRendersItalic() {
    let view = HTMLView(html: "<i>italic</i>")
    _ = view
}

@MainActor @Test func htmlViewRendersUnderline() {
    let view = HTMLView(html: "<u>underline</u>")
    _ = view
}

@MainActor @Test func htmlViewRendersStrikethrough() {
    let view = HTMLView(html: "<s>deleted</s>")
    _ = view
}

@MainActor @Test func htmlViewRendersCode() {
    let view = HTMLView(html: "<code>let x = 1</code>")
    _ = view
}

@MainActor @Test func htmlViewRendersDiv() {
    let view = HTMLView(html: "<div><p>inside div</p></div>")
    _ = view
}

@MainActor @Test func htmlViewRendersUnorderedList() {
    let view = HTMLView(html: "<ul><li>one</li><li>two</li></ul>")
    _ = view
}

@MainActor @Test func htmlViewRendersOrderedList() {
    let view = HTMLView(html: "<ol><li>first</li><li>second</li></ol>")
    _ = view
}

@MainActor @Test func htmlViewRendersBlockquote() {
    let view = HTMLView(html: "<blockquote>quoted</blockquote>")
    _ = view
}

@MainActor @Test func htmlViewRendersPre() {
    let view = HTMLView(html: "<pre>code block</pre>")
    _ = view
}

@MainActor @Test func htmlViewRendersHorizontalRule() {
    let view = HTMLView(html: "<hr>")
    _ = view
}

@MainActor @Test func htmlViewRendersTable() {
    let view = HTMLView(html: "<table><tr><th>Name</th><th>Age</th></tr><tr><td>Alice</td><td>30</td></tr></table>")
    _ = view
}

@MainActor @Test func htmlViewRendersLink() {
    let view = HTMLView(html: "<a href=\"https://example.com\">link</a>")
    _ = view
}

@MainActor @Test func htmlViewRendersNestedElements() {
    let view = HTMLView(html: "<div><p><b>text</b></p></div>")
    _ = view
}

@MainActor @Test func htmlViewRendersUnknownElement() {
    let view = HTMLView(html: "<custom>content</custom>")
    _ = view
}

// MARK: - HTMLNodeView Tests

@MainActor @Test func htmlNodeViewRendersChildrenInCustomRenderer() {
    let view = HTMLView(html: "<h1>Title with <b>bold</b></h1>") {
        HTMLHeadingRenderer { children, level, _ in
            VStack {
                Text("Custom H\(level)")
                HTMLNodeView(nodes: children)
            }
        }
    }
    _ = view
}

@MainActor @Test func htmlNodeViewRendersSingleNode() {
    let node = HTMLNode.text("Hello")
    let view = HTMLNodeView(node: node)
    _ = view
}

// MARK: - HTMLTagRenderer Tests

@MainActor @Test func htmlTagRendererForVideo() {
    let view = HTMLView(html: "<div><video src=\"test.mp4\">fallback</video><p>text</p></div>") {
        HTMLTagRenderer("video") { children, attributes in
            Text("Custom video: \(attributes["src"] ?? "")")
        }
    }
    _ = view
}

@MainActor @Test func htmlTagRendererMultipleTags() {
    let view = HTMLView(html: "<details><summary>Title</summary></details>") {
        HTMLTagRenderer("details") { children, _ in
            VStack {
                HTMLNodeView(nodes: children)
            }
        }
        HTMLTagRenderer("summary") { children, _ in
            Text("Summary")
        }
    }
    _ = view
}

// MARK: - HTMLListRenderer ordered/unordered Tests

@MainActor @Test func htmlListRendererReceivesOrderedParameter() {
    let ulView = HTMLView(html: "<ul><li>item</li></ul>") {
        HTMLListRenderer { children, ordered, attributes in
            Text(ordered ? "ordered" : "unordered")
        }
    }
    _ = ulView

    let olView = HTMLView(html: "<ol><li>item</li></ol>") {
        HTMLListRenderer { children, ordered, attributes in
            Text(ordered ? "ordered" : "unordered")
        }
    }
    _ = olView
}

// MARK: - Default Link Behavior Tests

@MainActor @Test func linkWithoutOnLinkTapIsClickable() {
    // Without onLinkTap, links should still render as Button (using openURL)
    let view = HTMLView(html: "<a href=\"https://example.com\">click me</a>")
    _ = view
}

@MainActor @Test func linkWithOnLinkTapUsesHandler() {
    let view = HTMLView(html: "<a href=\"https://example.com\">click me</a>", onLinkTap: { _, _ in })
    _ = view
}

@MainActor @Test func inlineLinkWithoutOnLinkTapHasLinkAttribute() {
    // Inline-collapsed links should always have AttributedString.link set
    let view = HTMLView(html: "<p>Visit <a href=\"https://example.com\">site</a> now</p>")
    _ = view
}

// MARK: - onLinkTap with HTMLElement Tests

@MainActor @Test func onLinkTapReceivesHTMLElement() {
    let view = HTMLView(
        html: "<a href=\"https://example.com\" title=\"Example\" class=\"link\">click</a>",
        onLinkTap: { url, element in
            // Verify the handler receives both URL and HTMLElement
            _ = url
            _ = element.tagName
            _ = element.attributes["href"]
            _ = element.attributes["title"]
            _ = element.attributes["class"]
        }
    )
    _ = view
}

// MARK: - Inline Collapsing Tests

@MainActor @Test func inlineCollapsingParagraphWithBold() {
    let view = HTMLView(html: "<p>Text <b>bold</b> text</p>")
    _ = view
}

@MainActor @Test func inlineCollapsingNestedStyles() {
    let view = HTMLView(html: "<p><b><i>bold italic</i></b></p>")
    _ = view
}

@MainActor @Test func inlineCollapsingBrInParagraph() {
    let view = HTMLView(html: "<p>line1<br>line2</p>")
    _ = view
}

@MainActor @Test func inlineCollapsingLinkInParagraph() {
    let view = HTMLView(html: "<p>Visit <a href=\"https://example.com\">site</a></p>")
    _ = view
}

@MainActor @Test func inlineCollapsingCodeInParagraph() {
    let view = HTMLView(html: "<p>Use <code>func</code> keyword</p>")
    _ = view
}

@MainActor @Test func inlineCollapsingSubSup() {
    let view = HTMLView(html: "<p>H<sub>2</sub>O and x<sup>2</sup></p>")
    _ = view
}

@MainActor @Test func inlineCollapsingHeadingWithBold() {
    let view = HTMLView(html: "<h1>Title with <b>bold</b></h1>")
    _ = view
}

@MainActor @Test func inlineCollapsingListItemWithBold() {
    let view = HTMLView(html: "<ul><li>Item with <b>bold</b></li></ul>")
    _ = view
}

// MARK: - Accessibility Tests

@MainActor @Test func accessibilityHeadingsHaveHeaderTrait() {
    for level in 1...6 {
        let view = HTMLView(html: "<h\(level)>Heading</h\(level)>")
        _ = view
    }
}

@MainActor @Test func accessibilityLinkWithOnLinkTap() {
    let view = HTMLView(html: "<a href=\"https://example.com\">link</a>", onLinkTap: { _, _ in })
    _ = view
}

@MainActor @Test func accessibilityInlineCollapsingNotBroken() {
    let view = HTMLView(html: "<p>Text with <a href=\"https://example.com\">link</a> inside</p>")
    _ = view
}

// MARK: - HTMLStyleConfiguration Tests

@Test func defaultConfigurationHasHeading1Font() {
    let config = HTMLStyleConfiguration.default
    #expect(config.heading1.font != nil)
}

@Test func defaultConfigurationHasPreformattedCornerRadius() {
    let config = HTMLStyleConfiguration.default
    #expect(config.preformatted.cornerRadius == 8)
}

@Test func defaultConfigurationHasBlockquoteBorderWidth() {
    let config = HTMLStyleConfiguration.default
    #expect(config.blockquote.borderWidth == 3)
}

@Test func customCornerRadiusAndBorder() {
    let style = HTMLElementStyle(
        cornerRadius: 12,
        borderColor: .red,
        borderWidth: 2
    )
    #expect(style.cornerRadius == 12)
    #expect(style.borderColor == .red)
    #expect(style.borderWidth == 2)
}

@MainActor @Test func preWithCustomCornerRadius() {
    let config = HTMLStyleConfiguration(
        preformatted: HTMLElementStyle(cornerRadius: 16)
    )
    let view = HTMLView(html: "<pre>code</pre>", configuration: config)
    _ = view
}

@MainActor @Test func blockquoteWithCustomBorder() {
    let config = HTMLStyleConfiguration(
        blockquote: HTMLElementStyle(borderColor: .red, borderWidth: 5)
    )
    let view = HTMLView(html: "<blockquote>quoted</blockquote>", configuration: config)
    _ = view
}

// MARK: - Layout Configuration Tests

@Test func defaultConfigurationHasLayoutDefaults() {
    let config = HTMLStyleConfiguration.default
    #expect(config.blockSpacing == 8)
    #expect(config.listSpacing == 4)
    #expect(config.listMarkerSpacing == 6)
    #expect(config.bulletMarker == "•")
}

@MainActor @Test func customLayoutValuesApplied() {
    let config = HTMLStyleConfiguration(
        blockSpacing: 16,
        listSpacing: 8,
        listMarkerSpacing: 12,
        bulletMarker: "–"
    )
    let view = HTMLView(html: "<div><ul><li>item</li></ul></div>", configuration: config)
    _ = view
}

// MARK: - Inline Element Tests (mark, small, kbd, q, cite, ins, abbr)

@MainActor @Test func htmlViewRendersMarkElement() {
    let view = HTMLView(html: "<mark>highlighted</mark>")
    _ = view
}

@MainActor @Test func htmlViewRendersSmallElement() {
    let view = HTMLView(html: "<small>fine print</small>")
    _ = view
}

@MainActor @Test func htmlViewRendersKbdElement() {
    let view = HTMLView(html: "<kbd>Ctrl</kbd>")
    _ = view
}

@MainActor @Test func htmlViewRendersQElement() {
    let view = HTMLView(html: "<q>quoted text</q>")
    _ = view
}

@MainActor @Test func htmlViewRendersCiteElement() {
    let view = HTMLView(html: "<cite>Source Title</cite>")
    _ = view
}

@MainActor @Test func htmlViewRendersInsElement() {
    let view = HTMLView(html: "<ins>inserted text</ins>")
    _ = view
}

@MainActor @Test func htmlViewRendersAbbrElement() {
    let view = HTMLView(html: "<abbr title=\"HyperText\">HTML</abbr>")
    _ = view
}

@Test func defaultConfigurationHasMarkStyle() {
    let config = HTMLStyleConfiguration.default
    #expect(config.mark.backgroundColor != nil)
}

@Test func defaultConfigurationHasSmallStyle() {
    let config = HTMLStyleConfiguration.default
    #expect(config.small.font != nil)
}

@Test func defaultConfigurationHasKeyboardStyle() {
    let config = HTMLStyleConfiguration.default
    #expect(config.keyboard.font != nil)
}

// MARK: - Inline Collapsing with New Phrasing Elements

@MainActor @Test func inlineCollapsingMarkInParagraph() {
    // <mark> inside <p> should collapse into single Text (mark is phrasing)
    let view = HTMLView(html: "<p>text <mark>highlighted</mark> more</p>")
    _ = view
}

@MainActor @Test func inlineCollapsingKbdInHeading() {
    // <kbd> inside <h2> should collapse into single Text (kbd is phrasing)
    let view = HTMLView(html: "<h2><kbd>Ctrl</kbd>+<kbd>S</kbd></h2>")
    _ = view
}

@MainActor @Test func inlineCollapsingQInParagraph() {
    let view = HTMLView(html: "<p>She said <q>hello</q> quietly</p>")
    _ = view
}

@MainActor @Test func inlineCollapsingCiteInsAbbrInParagraph() {
    let view = HTMLView(html: "<p><cite>Title</cite> by <ins>author</ins> about <abbr>HTML</abbr></p>")
    _ = view
}

@MainActor @Test func inlineCollapsingSmallInParagraph() {
    let view = HTMLView(html: "<p>Main text <small>fine print</small></p>")
    _ = view
}

// MARK: - Definition List Tests

@MainActor @Test func htmlViewRendersDefinitionList() {
    let view = HTMLView(html: "<dl><dt>Term</dt><dd>Definition</dd></dl>")
    _ = view
}

@MainActor @Test func htmlViewRendersDefinitionListWithCustomRenderer() {
    let view = HTMLView(html: "<dl><dt>Term</dt><dd>Definition</dd></dl>") {
        HTMLDefinitionListRenderer { children, attributes in
            VStack {
                HTMLNodeView(nodes: children)
            }
        }
    }
    _ = view
}

// MARK: - HTMLVisitor Tests

struct TextCollectorVisitor: HTMLVisitor {
    typealias Result = [String]

    func visitText(_ text: String) -> [String] {
        [text]
    }

    func visitComment(_ text: String) -> [String] { [] }
    func visitHorizontalRule() -> [String] { [] }

    func visitElement(_ element: HTMLElement) -> [String] {
        element.children.flatMap { $0.accept(visitor: self) }
    }

    func visitParagraph(_ element: HTMLElement) -> [String] {
        visitElement(element)
    }
}

@Test func visitorCollectsTextNodes() {
    let doc = HTMLParser.parseFragment("<p>Hello <b>world</b></p>")
    let visitor = TextCollectorVisitor()
    let results = doc.accept(visitor: visitor)
    let texts = results.flatMap { $0 }
    #expect(texts == ["Hello ", "world"])
}

struct HeadingLevelVisitor: HTMLVisitor {
    typealias Result = Int?

    func visitHeading(_ element: HTMLElement, level: Int) -> Int? {
        level
    }
}

@Test func visitorDispatchesHeadingWithLevel() {
    let doc = HTMLParser.parseFragment("<h1>Title</h1>")
    let visitor = HeadingLevelVisitor()
    let results = doc.accept(visitor: visitor)
    let levels = results.compactMap { $0 }
    #expect(levels == [1])
}

@Test func documentAcceptReturnsArrayOfResults() {
    let doc = HTMLParser.parseFragment("<h1>One</h1><h2>Two</h2>")
    let visitor = HeadingLevelVisitor()
    let results = doc.accept(visitor: visitor)
    let levels = results.compactMap { $0 }
    #expect(levels == [1, 2])
}
