import HTMLParser
import SwiftUI

// MARK: - Environment Keys

private struct OnLinkTapKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (URL, HTMLElement) -> Void)? = nil
}

private struct OnUnknownElementKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
}

private struct CustomRenderersKey: EnvironmentKey {
    static let defaultValue: HTMLCustomRenderers = HTMLCustomRenderers()
}

extension EnvironmentValues {
    var onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)? {
        get { self[OnLinkTapKey.self] }
        set { self[OnLinkTapKey.self] = newValue }
    }

    var onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? {
        get { self[OnUnknownElementKey.self] }
        set { self[OnUnknownElementKey.self] = newValue }
    }

    var customRenderers: HTMLCustomRenderers {
        get { self[CustomRenderersKey.self] }
        set { self[CustomRenderersKey.self] = newValue }
    }
}

// MARK: - HTMLView

public struct HTMLView: View {
    private let document: HTMLDocument
    private let onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)?
    private let onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)?
    private let customRenderers: HTMLCustomRenderers

    public init(
        document: HTMLDocument,
        onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
    ) {
        self.document = document
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = HTMLCustomRenderers()
    }

    public init(
        document: HTMLDocument,
        onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil,
        @HTMLContentBuilder content: () -> HTMLCustomRenderers
    ) {
        self.document = document
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = content()
    }

    public var body: some View {
        Group {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, node in
                NodeRenderer(node: node, blockContext: true)
            }
        }
        .environment(\.onLinkTap, onLinkTap)
        .environment(\.onUnknownElement, onUnknownElement)
        .environment(\.customRenderers, customRenderers)
    }
}

// MARK: - HTMLNodeView

public struct HTMLNodeView: View {
    private let nodes: [HTMLNode]

    public init(nodes: [HTMLNode]) {
        self.nodes = nodes
    }

    public init(node: HTMLNode) {
        self.nodes = [node]
    }

    public var body: some View {
        ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
            NodeRenderer(node: node, blockContext: true)
        }
    }
}

// MARK: - NodeRenderer

struct NodeRenderer: View {
    let node: HTMLNode
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
            ElementRenderer(element: element)
        }
    }
}

// MARK: - ElementRenderer

struct ElementRenderer: View {
    let element: HTMLElement

    @Environment(\.onLinkTap) private var onLinkTap
    @Environment(\.onUnknownElement) private var onUnknownElement
    @Environment(\.customRenderers) private var custom
    @Environment(\.openURL) private var openURL

    var body: some View {
        // Priority: Named renderers > tagRenderers > tagInlineText > built-in > unknown
        if let namedView = renderNamedElement() {
            namedView
        } else if let tagRenderer = custom.tagRenderers[element.tagName] {
            tagRenderer(element.children, element.attributes)
        } else if custom.tagInlineText[element.tagName] != nil {
            renderInlineElement()
        } else {
            renderBuiltInElement()
        }
    }

    private func renderNamedElement() -> AnyView? {
        switch element.tagName {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            if let heading = custom.heading {
                let level = Int(String(element.tagName.last!))!
                return AnyView(heading(element.children, level, element.attributes))
            }
        case "p":
            if let paragraph = custom.paragraph {
                return AnyView(paragraph(element.children, element.attributes))
            }
        case "a":
            if let link = custom.link {
                return AnyView(link(element.children, element.attributes["href"], element.attributes))
            }
        case "ul":
            if let list = custom.list {
                return AnyView(list(element.children, false, element.attributes))
            }
        case "ol":
            if let list = custom.list {
                return AnyView(list(element.children, true, element.attributes))
            }
        case "li":
            if let listItem = custom.listItem {
                return AnyView(listItem(element.children, element.attributes))
            }
        case "blockquote":
            if let blockquote = custom.blockquote {
                return AnyView(blockquote(element.children, element.attributes))
            }
        case "pre":
            if let codeBlock = custom.codeBlock {
                return AnyView(codeBlock(element.children, element.attributes))
            }
        case "table":
            if let table = custom.table {
                return AnyView(table(element.children, element.attributes))
            }
        case "dl":
            if let definitionList = custom.definitionList {
                return AnyView(definitionList(element.children, element.attributes))
            }
        default:
            break
        }
        return nil
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

    private static let blockTags: Set<String> = [
        "div", "article", "section", "main", "header", "footer", "nav", "aside",
        "blockquote", "figure", "pre", "ul", "ol", "table", "thead", "tbody",
        "tfoot", "tr", "li", "dl", "dt", "dd",
    ]

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
        if canCollapseInline(nodes, customRenderers: custom) {
            buildInlineText(nodes, customRenderers: custom, onLinkTap: onLinkTap, baseFont: baseFont)
        } else if children != nil {
            VStack(alignment: .leading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { _, child in
                    NodeRenderer(node: child, blockContext: true)
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
            NodeRenderer(node: child, blockContext: isBlock)
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
        if let onUnknownElement {
            onUnknownElement(element)
        } else {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderListItemContent(_ item: HTMLElement) -> some View {
        if let listItem = custom.listItem {
            listItem(item.children, item.attributes)
        } else if let tagRenderer = custom.tagRenderers["li"] {
            tagRenderer(item.children, item.attributes)
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
