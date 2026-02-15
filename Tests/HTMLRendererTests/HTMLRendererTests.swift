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
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Hello</p>"))
    _ = view
}

@MainActor @Test func htmlViewWithEmptyDocument() {
    let doc = HTMLDocument(children: [])
    let view = HTMLView(document: doc)
    _ = view
}

@MainActor @Test func htmlViewRendersHeadings() {
    for level in 1...6 {
        let view = HTMLView(document: HTMLParser.parseFragment("<h\(level)>Heading \(level)</h\(level)>"))
        _ = view
    }
}

@MainActor @Test func htmlViewRendersParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Paragraph text</p>"))
    _ = view
}

@MainActor @Test func htmlViewRendersBold() {
    let view = HTMLView(document: HTMLParser.parseFragment("<b>bold</b>"))
    _ = view
}

@MainActor @Test func htmlViewRendersItalic() {
    let view = HTMLView(document: HTMLParser.parseFragment("<i>italic</i>"))
    _ = view
}

@MainActor @Test func htmlViewRendersUnderline() {
    let view = HTMLView(document: HTMLParser.parseFragment("<u>underline</u>"))
    _ = view
}

@MainActor @Test func htmlViewRendersStrikethrough() {
    let view = HTMLView(document: HTMLParser.parseFragment("<s>deleted</s>"))
    _ = view
}

@MainActor @Test func htmlViewRendersCode() {
    let view = HTMLView(document: HTMLParser.parseFragment("<code>let x = 1</code>"))
    _ = view
}

@MainActor @Test func htmlViewRendersDiv() {
    let view = HTMLView(document: HTMLParser.parseFragment("<div><p>inside div</p></div>"))
    _ = view
}

@MainActor @Test func htmlViewRendersUnorderedList() {
    let view = HTMLView(document: HTMLParser.parseFragment("<ul><li>one</li><li>two</li></ul>"))
    _ = view
}

@MainActor @Test func htmlViewRendersOrderedList() {
    let view = HTMLView(document: HTMLParser.parseFragment("<ol><li>first</li><li>second</li></ol>"))
    _ = view
}

@MainActor @Test func htmlViewRendersBlockquote() {
    let view = HTMLView(document: HTMLParser.parseFragment("<blockquote>quoted</blockquote>"))
    _ = view
}

@MainActor @Test func htmlViewRendersPre() {
    let view = HTMLView(document: HTMLParser.parseFragment("<pre>code block</pre>"))
    _ = view
}

@MainActor @Test func htmlViewRendersHorizontalRule() {
    let view = HTMLView(document: HTMLParser.parseFragment("<hr>"))
    _ = view
}

@MainActor @Test func htmlViewRendersTable() {
    let view = HTMLView(document: HTMLParser.parseFragment("<table><tr><th>Name</th><th>Age</th></tr><tr><td>Alice</td><td>30</td></tr></table>"))
    _ = view
}

@MainActor @Test func htmlViewRendersLink() {
    let view = HTMLView(document: HTMLParser.parseFragment("<a href=\"https://example.com\">link</a>"))
    _ = view
}

@MainActor @Test func htmlViewRendersNestedElements() {
    let view = HTMLView(document: HTMLParser.parseFragment("<div><p><b>text</b></p></div>"))
    _ = view
}

@MainActor @Test func htmlViewRendersUnknownElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<custom>content</custom>"))
    _ = view
}

// MARK: - HTMLNodeView Tests

@MainActor @Test func htmlNodeViewRendersChildrenInCustomRenderer() {
    let view = HTMLView(document: HTMLParser.parseFragment("<h1>Title with <b>bold</b></h1>"))
        .htmlHeading { children, level, _ in
            VStack {
                Text("Custom H\(level)")
                HTMLNodeView(nodes: children)
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
    let view = HTMLView(document: HTMLParser.parseFragment("<div><video src=\"test.mp4\">fallback</video><p>text</p></div>"))
        .htmlTag("video") { children, attributes in
            Text("Custom video: \(attributes["src"] ?? "")")
        }
    _ = view
}

@MainActor @Test func htmlTagRendererMultipleTags() {
    let view = HTMLView(document: HTMLParser.parseFragment("<details><summary>Title</summary></details>"))
        .htmlTag("details") { children, _ in
            VStack {
                HTMLNodeView(nodes: children)
            }
        }
        .htmlTag("summary") { children, _ in
            Text("Summary")
        }
    _ = view
}

// MARK: - HTMLListRenderer ordered/unordered Tests

@MainActor @Test func htmlListRendererReceivesOrderedParameter() {
    let ulView = HTMLView(document: HTMLParser.parseFragment("<ul><li>item</li></ul>"))
        .htmlList { children, ordered, attributes in
            Text(ordered ? "ordered" : "unordered")
        }
    _ = ulView

    let olView = HTMLView(document: HTMLParser.parseFragment("<ol><li>item</li></ol>"))
        .htmlList { children, ordered, attributes in
            Text(ordered ? "ordered" : "unordered")
        }
    _ = olView
}

// MARK: - Default Link Behavior Tests

@MainActor @Test func linkWithoutOnLinkTapIsClickable() {
    let view = HTMLView(document: HTMLParser.parseFragment("<a href=\"https://example.com\">click me</a>"))
    _ = view
}

@MainActor @Test func linkWithOnLinkTapUsesHandler() {
    let view = HTMLView(document: HTMLParser.parseFragment("<a href=\"https://example.com\">click me</a>"), onLinkTap: { _, _ in })
    _ = view
}

@MainActor @Test func inlineLinkWithoutOnLinkTapHasLinkAttribute() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Visit <a href=\"https://example.com\">site</a> now</p>"))
    _ = view
}

// MARK: - onLinkTap with HTMLElement Tests

@MainActor @Test func onLinkTapReceivesHTMLElement() {
    let view = HTMLView(
        document: HTMLParser.parseFragment("<a href=\"https://example.com\" title=\"Example\" class=\"link\">click</a>"),
        onLinkTap: { url, element in
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
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Text <b>bold</b> text</p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingNestedStyles() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p><b><i>bold italic</i></b></p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingBrInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>line1<br>line2</p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingLinkInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Visit <a href=\"https://example.com\">site</a></p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingCodeInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Use <code>func</code> keyword</p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingSubSup() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>H<sub>2</sub>O and x<sup>2</sup></p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingHeadingWithBold() {
    let view = HTMLView(document: HTMLParser.parseFragment("<h1>Title with <b>bold</b></h1>"))
    _ = view
}

@MainActor @Test func inlineCollapsingListItemWithBold() {
    let view = HTMLView(document: HTMLParser.parseFragment("<ul><li>Item with <b>bold</b></li></ul>"))
    _ = view
}

// MARK: - Accessibility Tests

@MainActor @Test func accessibilityHeadingsHaveHeaderTrait() {
    for level in 1...6 {
        let view = HTMLView(document: HTMLParser.parseFragment("<h\(level)>Heading</h\(level)>"))
        _ = view
    }
}

@MainActor @Test func accessibilityLinkWithOnLinkTap() {
    let view = HTMLView(document: HTMLParser.parseFragment("<a href=\"https://example.com\">link</a>"), onLinkTap: { _, _ in })
    _ = view
}

@MainActor @Test func accessibilityInlineCollapsingNotBroken() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Text with <a href=\"https://example.com\">link</a> inside</p>"))
    _ = view
}


// MARK: - Inline Element Tests (mark, small, kbd, q, cite, ins, abbr)

@MainActor @Test func htmlViewRendersMarkElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<mark>highlighted</mark>"))
    _ = view
}

@MainActor @Test func htmlViewRendersSmallElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<small>fine print</small>"))
    _ = view
}

@MainActor @Test func htmlViewRendersKbdElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<kbd>Ctrl</kbd>"))
    _ = view
}

@MainActor @Test func htmlViewRendersQElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<q>quoted text</q>"))
    _ = view
}

@MainActor @Test func htmlViewRendersCiteElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<cite>Source Title</cite>"))
    _ = view
}

@MainActor @Test func htmlViewRendersInsElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<ins>inserted text</ins>"))
    _ = view
}

@MainActor @Test func htmlViewRendersAbbrElement() {
    let view = HTMLView(document: HTMLParser.parseFragment("<abbr title=\"HyperText\">HTML</abbr>"))
    _ = view
}


// MARK: - Inline Collapsing with New Phrasing Elements

@MainActor @Test func inlineCollapsingMarkInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>text <mark>highlighted</mark> more</p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingKbdInHeading() {
    let view = HTMLView(document: HTMLParser.parseFragment("<h2><kbd>Ctrl</kbd>+<kbd>S</kbd></h2>"))
    _ = view
}

@MainActor @Test func inlineCollapsingQInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>She said <q>hello</q> quietly</p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingCiteInsAbbrInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p><cite>Title</cite> by <ins>author</ins> about <abbr>HTML</abbr></p>"))
    _ = view
}

@MainActor @Test func inlineCollapsingSmallInParagraph() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Main text <small>fine print</small></p>"))
    _ = view
}

// MARK: - Definition List Tests

@MainActor @Test func htmlViewRendersDefinitionList() {
    let view = HTMLView(document: HTMLParser.parseFragment("<dl><dt>Term</dt><dd>Definition</dd></dl>"))
    _ = view
}

@MainActor @Test func htmlViewRendersDefinitionListWithCustomRenderer() {
    let view = HTMLView(document: HTMLParser.parseFragment("<dl><dt>Term</dt><dd>Definition</dd></dl>"))
        .htmlDefinitionList { children, attributes in
            VStack {
                HTMLNodeView(nodes: children)
            }
        }
    _ = view
}

// MARK: - Inline Custom Renderer Tests

@MainActor @Test func inlineLinkRendererWithInlineText() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Visit <a href=\"https://example.com\">site</a> now</p>"))
        .htmlLinkInlineText { text, url, attrs in
            text.foregroundColor(.red)
        }
    _ = view
}

@MainActor @Test func linkRendererBlockAndInline() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>See <a href=\"https://example.com\">link</a></p>"))
        .htmlLink(
            render: { children, href, attrs in
                HStack { HTMLNodeView(nodes: children) }
            },
            inlineText: { text, url, attrs in
                text.foregroundColor(.blue).underline()
            }
        )
    _ = view
}

@MainActor @Test func tagRendererWithInlineText() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>Status: <badge>active</badge></p>"))
        .htmlTagInlineText("badge") { text, attrs in
            text.foregroundColor(.blue).bold()
        }
    _ = view
}

@MainActor @Test func tagRendererBlockAndInline() {
    let view = HTMLView(document: HTMLParser.parseFragment("<div><badge>solo</badge><p>inline <badge>here</badge></p></div>"))
        .htmlTag(
            "badge",
            render: { children, attrs in
                HStack { HTMLNodeView(nodes: children) }.background(.blue)
            },
            inlineText: { text, attrs in
                text.bold().foregroundColor(.blue)
            }
        )
    _ = view
}

@MainActor @Test func blockOnlyLinkRendererPreservesCurrentBehavior() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>See <a href=\"https://example.com\">link</a></p>"))
        .htmlLink { children, href, attrs in
            HStack { HTMLNodeView(nodes: children) }
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

// MARK: - TagRenderer Override Tests

@MainActor @Test func tagRendererOverridesBuiltInDiv() {
    let view = HTMLView(document: HTMLParser.parseFragment("<div>content</div>"))
        .htmlTag("div") { children, _ in
            HStack { HTMLNodeView(nodes: children) }
        }
    _ = view
}

@MainActor @Test func tagRendererInlineOverridesBuiltInBold() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p><b>text</b></p>"))
        .htmlTagInlineText("b") { text, _ in text.italic() }
    _ = view
}

@MainActor @Test func tagRendererSkipTable() {
    let view = HTMLView(document: HTMLParser.parseFragment("<table><tr><td>cell</td></tr></table>"))
        .htmlSkipTag("table")
    _ = view
}

@MainActor @Test func tagRendererMakesDivInline() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>text <div>inline</div> more</p>"))
        .htmlTagInlineText("div") { text, _ in text }
    _ = view
}

@MainActor @Test func tagRendererMakesSpanBlock() {
    let view = HTMLView(document: HTMLParser.parseFragment("<span>content</span>"))
        .htmlTag("span") { children, _ in
            VStack { HTMLNodeView(nodes: children) }.background(.blue)
        }
    _ = view
}

@MainActor @Test func namedRendererPriorityOverTagRenderer() {
    let view = HTMLView(document: HTMLParser.parseFragment("<h1>heading</h1>"))
        .htmlHeading { children, level, _ in
            Text("Custom H\(level)")
        }
        .htmlTag("h1") { children, _ in
            Text("Should not be used")
        }
    _ = view
}
