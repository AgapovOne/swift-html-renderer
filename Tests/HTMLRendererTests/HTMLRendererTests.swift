import HTMLParser
import HTMLRenderer
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

// MARK: - HTMLStyleConfiguration Tests

@Test func defaultConfigurationHasHeading1Font() {
    let config = HTMLStyleConfiguration.default
    #expect(config.heading1.font != nil)
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
