import HTMLParser
import SwiftUI

// MARK: - Environment Keys

private struct OnLinkTapKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (URL, HTMLElement) -> Void)? = nil
}

private struct NodeRenderClosureKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (HTMLNode, Bool) -> AnyView)? = nil
}

extension EnvironmentValues {
    var onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)? {
        get { self[OnLinkTapKey.self] }
        set { self[OnLinkTapKey.self] = newValue }
    }

    var nodeRenderClosure: (@MainActor @Sendable (HTMLNode, Bool) -> AnyView)? {
        get { self[NodeRenderClosureKey.self] }
        set { self[NodeRenderClosureKey.self] = newValue }
    }
}

// MARK: - HTMLView

public struct HTMLView<Renderer: HTMLElementRenderer>: View {
    let document: HTMLDocument
    let renderer: Renderer

    public init(
        document: HTMLDocument,
        renderer: Renderer
    ) {
        self.document = document
        self.renderer = renderer
    }

    public var body: some View {
        Group {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, node in
                _NodeRenderer<Renderer>(node: node, renderer: renderer, blockContext: true)
            }
        }
        .environment(\.nodeRenderClosure) { node, blockContext in
            AnyView(_NodeRenderer<Renderer>(node: node, renderer: renderer, blockContext: blockContext))
        }
    }
}

extension HTMLView where Renderer == DefaultHTMLElementRenderer {
    public init(
        document: HTMLDocument
    ) {
        self.document = document
        self.renderer = DefaultHTMLElementRenderer()
    }
}

// MARK: - HTMLNodeView (public, non-generic — single AnyView bridge)

public struct HTMLNodeView: View {
    private let nodes: [HTMLNode]
    @Environment(\.nodeRenderClosure) private var renderClosure

    public init(nodes: [HTMLNode]) {
        self.nodes = nodes
    }

    public init(node: HTMLNode) {
        self.nodes = [node]
    }

    public var body: some View {
        ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
            if let renderClosure {
                renderClosure(node, true)
            } else {
                _NodeRenderer<DefaultHTMLElementRenderer>(
                    node: node,
                    renderer: DefaultHTMLElementRenderer(),
                    blockContext: true
                )
            }
        }
    }
}

// MARK: - _NodeRenderer

struct _NodeRenderer<R: HTMLElementRenderer>: View {
    let node: HTMLNode
    let renderer: R
    var blockContext = false

    var body: some View {
        switch node {
        case .text(let text):
            if !blockContext || text.contains(where: { !$0.isWhitespace }) {
                Text(text)
            }
        case .comment:
            EmptyView()
        case .element(let element):
            _ElementRenderer<R>(element: element, renderer: renderer)
        }
    }
}

// MARK: - _ElementRenderer

struct _ElementRenderer<R: HTMLElementRenderer>: View {
    let element: HTMLElement
    let renderer: R

    @Environment(\.onLinkTap) private var onLinkTap
    @Environment(\.openURL) private var openURL

    var body: some View {
        if hasNamedRenderer() {
            renderNamedElement()
        } else if renderer.customTagNames.contains(element.tagName) {
            renderer.customTag(name: element.tagName, children: element.children, attributes: element.attributes)
        } else if renderer.tagInlineText[element.tagName] != nil {
            renderInlineElement()
        } else {
            renderBuiltInElement()
        }
    }

    private func hasNamedRenderer() -> Bool {
        switch element.tagName {
        case "h1", "h2", "h3", "h4", "h5", "h6": R.HeadingBody.self != Never.self
        case "p": R.ParagraphBody.self != Never.self
        case "a": R.LinkBody.self != Never.self
        case "ul", "ol": R.ListBody.self != Never.self
        case "li": R.ListItemBody.self != Never.self
        case "blockquote": R.BlockquoteBody.self != Never.self
        case "pre": R.CodeBlockBody.self != Never.self
        case "table": R.TableBody.self != Never.self
        case "dl": R.DefinitionListBody.self != Never.self
        default: false
        }
    }

    @ViewBuilder
    private func renderNamedElement() -> some View {
        switch element.tagName {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            let level = Int(String(element.tagName.last!))!
            renderer.heading(children: element.children, level: level, attributes: element.attributes)
        case "p":
            renderer.paragraph(children: element.children, attributes: element.attributes)
        case "a":
            renderer.link(children: element.children, href: element.attributes["href"], attributes: element.attributes)
        case "ul":
            renderer.list(children: element.children, ordered: false, attributes: element.attributes)
        case "ol":
            renderer.list(children: element.children, ordered: true, attributes: element.attributes)
        case "li":
            renderer.listItem(children: element.children, attributes: element.attributes)
        case "blockquote":
            renderer.blockquote(children: element.children, attributes: element.attributes)
        case "pre":
            renderer.codeBlock(children: element.children, attributes: element.attributes)
        case "table":
            renderer.table(children: element.children, attributes: element.attributes)
        case "dl":
            renderer.definitionList(children: element.children, attributes: element.attributes)
        default:
            EmptyView()
        }
    }

    private static var blockTags: Set<String> {
        [
            "div", "article", "section", "main", "header", "footer", "nav", "aside",
            "blockquote", "figure", "pre", "ul", "ol", "table", "thead", "tbody",
            "tfoot", "tr", "li", "dl", "dt", "dd",
        ]
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: .largeTitle
        case 2: .title
        case 3: .title2
        case 4: .title3
        case 5: .headline
        default: .subheadline
        }
    }

    @ViewBuilder
    private func renderBuiltInElement() -> some View {
        switch element.tagName {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            let level = Int(String(element.tagName.last!))!
            renderHeading(level: level)
        case "p":
            renderParagraph()
        case "b", "strong", "i", "em", "u", "s", "del", "code",
             "span", "abbr", "mark", "small", "kbd", "q", "cite", "ins",
             "br", "sub", "sup":
            renderInlineElement()
        case "div", "article", "section", "main", "header", "footer", "nav", "aside":
            renderBlockContainer()
        case "blockquote":
            renderBlockquote()
        case "pre":
            renderPreformatted()
        case "hr":
            Divider()
        case "figure":
            renderBlockContainer()
        case "figcaption":
            renderFigcaption()
        case "ul":
            renderUnorderedList()
        case "ol":
            renderOrderedList()
        case "li":
            renderListItem()
        case "table":
            renderTableDefault()
        case "thead", "tbody", "tfoot", "tr", "td", "th":
            renderChildren()
        case "dl":
            renderDefinitionList()
        case "dt":
            renderDefinitionTerm()
        case "dd":
            renderDefinitionDescription()
        case "a":
            renderLink()
        default:
            renderUnknownElement()
        }
    }

    @ViewBuilder
    private func renderHeading(level: Int) -> some View {
        let font = headingFont(for: level)
        renderWithInlineCollapsing(baseFont: font)
            .font(font)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func renderInlineElement() -> some View {
        switch element.tagName {
        case "b", "strong":
            renderChildren().bold()
        case "i", "em":
            renderChildren().italic()
        case "u":
            renderChildren().underline()
        case "s", "del":
            renderChildren().strikethrough()
        case "code":
            renderChildren().monospaced()
        case "span", "abbr":
            renderChildren()
        case "mark":
            renderChildren()
                .background(Color.yellow.opacity(0.3))
        case "small":
            renderChildren()
                .font(.caption)
        case "kbd":
            renderChildren()
                .font(.system(.body, design: .monospaced))
                .padding(EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3))
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray, lineWidth: 1)
                }
        case "q":
            HStack(spacing: 0) {
                Text("\u{201C}")
                renderChildren()
                Text("\u{201D}")
            }
        case "cite":
            renderChildren().italic()
        case "ins":
            renderChildren().underline()
        case "br":
            Text("\n")
        case "sub":
            renderChildren()
                .font(.caption2)
                .baselineOffset(-4)
        case "sup":
            renderChildren()
                .font(.caption2)
                .baselineOffset(8)
        default:
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderParagraph() -> some View {
        renderWithInlineCollapsing()
    }

    @ViewBuilder
    private func renderBlockContainer() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderBlockquote() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            renderChildren()
        }
        .padding(.leading, 16)
        .overlay(alignment: .leading) {
            Rectangle()
                .frame(width: 3)
                .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private func renderPreformatted() -> some View {
        VStack(alignment: .leading) {
            renderChildren()
        }
        .font(.system(.body, design: .monospaced))
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func renderFigcaption() -> some View {
        renderWithInlineCollapsing()
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func renderUnorderedList() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(listItems().enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 6) {
                    Text("\u{2022}")
                    renderListItemContent(item)
                }
            }
        }
    }

    @ViewBuilder
    private func renderOrderedList() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(listItems().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 6) {
                    Text(ListNumberFormat.decimal.format(index))
                    renderListItemContent(item)
                }
            }
        }
    }

    @ViewBuilder
    private func renderListItem() -> some View {
        renderChildren()
    }

    @ViewBuilder
    private func renderTableDefault() -> some View {
        Grid(alignment: .leading) {
            ForEach(Array(tableRows().enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(tableCells(in: row).enumerated()), id: \.offset) { _, cell in
                        if cell.tagName == "th" {
                            renderWithInlineCollapsing(cell.children)
                                .bold()
                        } else {
                            renderWithInlineCollapsing(cell.children)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func renderDefinitionList() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderDefinitionTerm() -> some View {
        renderWithInlineCollapsing()
            .bold()
    }

    @ViewBuilder
    private func renderDefinitionDescription() -> some View {
        renderWithInlineCollapsing()
            .padding(.leading, 16)
    }

    @ViewBuilder
    private func renderWithInlineCollapsing(
        _ children: [HTMLNode]? = nil,
        baseFont: Font = .body
    ) -> some View {
        let nodes = children ?? element.children
        let tagInline = renderer.tagInlineText
        let linkInline = renderer.linkInlineText
        let hasCustomLink = R.LinkBody.self != Never.self
        let customTags = renderer.customTagNames
        if canCollapseInline(nodes, tagInlineText: tagInline, customTagNames: customTags, hasCustomLink: hasCustomLink, hasLinkInlineText: linkInline != nil) {
            buildInlineText(nodes, tagInlineText: tagInline, linkInlineText: linkInline, baseFont: baseFont)
        } else if children != nil {
            VStack(alignment: .leading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { _, child in
                    _NodeRenderer<R>(node: child, renderer: renderer, blockContext: true)
                }
            }
        } else {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderChildren() -> some View {
        let isBlock = Self.blockTags.contains(element.tagName)
        ForEach(Array(element.children.enumerated()), id: \.offset) { _, child in
            _NodeRenderer<R>(node: child, renderer: renderer, blockContext: isBlock)
        }
    }

    @ViewBuilder
    private func renderLink() -> some View {
        let href = element.attributes["href"]
        let url = href.flatMap { URL(string: $0) }

        if let url {
            Button {
                if let onLinkTap {
                    onLinkTap(url, element)
                } else {
                    openURL(url)
                }
            } label: {
                renderChildren()
                    .underline()
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isLink)
        } else {
            renderChildren()
                .underline()
                .foregroundStyle(Color.blue)
        }
    }

    @ViewBuilder
    private func renderUnknownElement() -> some View {
        if R.UnknownElementBody.self != Never.self {
            renderer.unknownElement(element: element)
        } else {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderListItemContent(_ item: HTMLElement) -> some View {
        if R.ListItemBody.self != Never.self {
            renderer.listItem(children: item.children, attributes: item.attributes)
        } else if renderer.customTagNames.contains("li") {
            renderer.customTag(name: "li", children: item.children, attributes: item.attributes)
        } else {
            renderWithInlineCollapsing(item.children)
        }
    }

    private func listItems() -> [HTMLElement] {
        element.children.compactMap { node in
            if case .element(let el) = node, el.tagName == "li" {
                return el
            }
            return nil
        }
    }

    private func tableRows() -> [HTMLElement] {
        element.children.flatMap { node -> [HTMLElement] in
            guard case .element(let el) = node else { return [] }
            if el.tagName == "tr" {
                return [el]
            }
            if el.tagName == "thead" || el.tagName == "tbody" || el.tagName == "tfoot" {
                return el.children.compactMap { child in
                    if case .element(let childEl) = child, childEl.tagName == "tr" {
                        return childEl
                    }
                    return nil
                }
            }
            return []
        }
    }

    private func tableCells(in row: HTMLElement) -> [HTMLElement] {
        row.children.compactMap { node in
            if case .element(let el) = node, el.tagName == "td" || el.tagName == "th" {
                return el
            }
            return nil
        }
    }
}


// MARK: - onLinkTap View Modifier

extension View {
    public func onLinkTap(
        _ handler: @MainActor @Sendable @escaping (URL, HTMLElement) -> Void
    ) -> some View {
        environment(\.onLinkTap, handler)
    }
}

extension View {
    @ViewBuilder
    func ifLet<T>(_ value: T?, @ViewBuilder transform: (Self, T) -> some View) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}
