import HTMLParser
import SwiftUI

// MARK: - Environment Keys

private struct OnLinkTapKey: EnvironmentKey {
    static let defaultValue: (@Sendable (URL, HTMLElement) -> Void)? = nil
}

private struct OnUnknownElementKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
}

private struct StyleConfigurationKey: EnvironmentKey {
    static let defaultValue: HTMLStyleConfiguration = .default
}

private struct CustomRenderersKey: EnvironmentKey {
    static let defaultValue: HTMLCustomRenderers = HTMLCustomRenderers()
}

extension EnvironmentValues {
    var onLinkTap: (@Sendable (URL, HTMLElement) -> Void)? {
        get { self[OnLinkTapKey.self] }
        set { self[OnLinkTapKey.self] = newValue }
    }

    var onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? {
        get { self[OnUnknownElementKey.self] }
        set { self[OnUnknownElementKey.self] = newValue }
    }

    var styleConfiguration: HTMLStyleConfiguration {
        get { self[StyleConfigurationKey.self] }
        set { self[StyleConfigurationKey.self] = newValue }
    }

    var customRenderers: HTMLCustomRenderers {
        get { self[CustomRenderersKey.self] }
        set { self[CustomRenderersKey.self] = newValue }
    }
}

// MARK: - HTMLView

public struct HTMLView: View {
    private let document: HTMLDocument
    private let configuration: HTMLStyleConfiguration
    private let onLinkTap: (@Sendable (URL, HTMLElement) -> Void)?
    private let onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)?
    private let customRenderers: HTMLCustomRenderers

    public init(
        document: HTMLDocument,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL, HTMLElement) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
    ) {
        self.document = document
        self.configuration = configuration
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = HTMLCustomRenderers()
    }

    public init(
        document: HTMLDocument,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL, HTMLElement) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil,
        @HTMLContentBuilder content: () -> HTMLCustomRenderers
    ) {
        self.document = document
        self.configuration = configuration
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
        .environment(\.styleConfiguration, configuration)
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
    @Environment(\.styleConfiguration) private var config
    @Environment(\.customRenderers) private var custom
    @Environment(\.openURL) private var openURL

    var body: some View {
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
            if let link = custom.link {
                link(element.children, element.attributes["href"], element.attributes)
            } else {
                renderLink()
            }
        default:
            if let tagRenderer = custom.tagRenderers[element.tagName] {
                tagRenderer(element.children, element.attributes)
            } else {
                renderUnknownElement()
            }
        }
    }

    private static let blockTags: Set<String> = [
        "div", "article", "section", "main", "header", "footer", "nav", "aside",
        "blockquote", "figure", "pre", "ul", "ol", "table", "thead", "tbody",
        "tfoot", "tr", "li", "dl", "dt", "dd",
    ]

    private func headingStyle(for level: Int) -> (HTMLElementStyle, Font) {
        switch level {
        case 1: (config.heading1, .largeTitle)
        case 2: (config.heading2, .title)
        case 3: (config.heading3, .title2)
        case 4: (config.heading4, .title3)
        case 5: (config.heading5, .headline)
        default: (config.heading6, .subheadline)
        }
    }

    @ViewBuilder
    private func renderHeading(level: Int) -> some View {
        if let heading = custom.heading {
            heading(element.children, level, element.attributes)
        } else {
            let (style, defaultFont) = headingStyle(for: level)
            renderWithInlineCollapsing(style: style, defaultFont: defaultFont, baseFont: defaultFont)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private func renderInlineElement() -> some View {
        switch element.tagName {
        case "b", "strong":
            renderChildren().bold()
                .applyStyle(config.bold)
        case "i", "em":
            renderChildren().italic()
                .applyStyle(config.italic)
        case "u":
            renderChildren().underline()
                .applyStyle(config.underline)
        case "s", "del":
            renderChildren().strikethrough()
                .applyStyle(config.strikethrough)
        case "code":
            renderChildren().monospaced()
                .applyStyle(config.code)
        case "span", "abbr":
            renderChildren()
        case "mark":
            renderChildren()
                .applyStyle(config.mark)
        case "small":
            renderChildren()
                .applyStyle(config.small)
        case "kbd":
            renderChildren()
                .applyStyle(config.keyboard, skipFont: true)
                .font(config.keyboard.font ?? .system(.body, design: .monospaced))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray, lineWidth: 1)
                )
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
        if let paragraph = custom.paragraph {
            paragraph(element.children, element.attributes)
        } else {
            renderWithInlineCollapsing(style: config.paragraph, defaultFont: .body)
        }
    }

    @ViewBuilder
    private func renderBlockContainer() -> some View {
        VStack(alignment: .leading, spacing: config.blockSpacing) {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderBlockquote() -> some View {
        if let blockquote = custom.blockquote {
            blockquote(element.children, element.attributes)
        } else {
            VStack(alignment: .leading, spacing: config.blockSpacing) {
                renderChildren()
            }
            .padding(.leading, config.blockquote.padding?.leading ?? 16)
            .overlay(alignment: .leading) {
                Rectangle()
                    .frame(width: config.blockquote.borderWidth ?? 3)
                    .foregroundStyle(config.blockquote.borderColor ?? config.blockquote.foregroundColor ?? Color.accentColor)
            }
            .applyStyle(config.blockquote, skipPadding: true, skipBorderWidth: true)
        }
    }

    @ViewBuilder
    private func renderPreformatted() -> some View {
        if let codeBlock = custom.codeBlock {
            codeBlock(element.children, element.attributes)
        } else {
            VStack(alignment: .leading) {
                renderChildren()
            }
            .font(config.preformatted.font ?? .system(.body, design: .monospaced))
            .padding(config.preformatted.padding.map { EdgeInsets(top: $0.top, leading: $0.leading, bottom: $0.bottom, trailing: $0.trailing) } ?? EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .background(config.preformatted.backgroundColor ?? Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: config.preformatted.cornerRadius ?? 8))
            .applyStyle(config.preformatted, skipFont: true, skipBackgroundColor: true, skipPadding: true, skipCornerRadius: true)
        }
    }

    @ViewBuilder
    private func renderFigcaption() -> some View {
        renderWithInlineCollapsing()
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func renderUnorderedList() -> some View {
        if let list = custom.list {
            list(element.children, false, element.attributes)
        } else {
            VStack(alignment: .leading, spacing: config.listSpacing) {
                ForEach(Array(listItems().enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: config.listMarkerSpacing) {
                        Text(config.bulletMarker)
                        renderListItemContent(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func renderOrderedList() -> some View {
        if let list = custom.list {
            list(element.children, true, element.attributes)
        } else {
            VStack(alignment: .leading, spacing: config.listSpacing) {
                ForEach(Array(listItems().enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: config.listMarkerSpacing) {
                        Text("\(index + 1).")
                        renderListItemContent(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func renderListItem() -> some View {
        if let listItem = custom.listItem {
            listItem(element.children, element.attributes)
        } else {
            renderChildren()
        }
    }

    @ViewBuilder
    private func renderTableDefault() -> some View {
        if let table = custom.table {
            table(element.children, element.attributes)
        } else {
            Grid(alignment: .leading) {
                ForEach(Array(tableRows().enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(tableCells(in: row).enumerated()), id: \.offset) { _, cell in
                            if cell.tagName == "th" {
                                renderWithInlineCollapsing(cell.children, style: config.tableHeader)
                                    .bold()
                            } else {
                                renderWithInlineCollapsing(cell.children, style: config.tableCell)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func renderDefinitionList() -> some View {
        if let definitionList = custom.definitionList {
            definitionList(element.children, element.attributes)
        } else {
            VStack(alignment: .leading, spacing: config.blockSpacing) {
                renderChildren()
            }
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
        style: HTMLElementStyle? = nil,
        defaultFont: Font? = nil,
        baseFont: Font = .body
    ) -> some View {
        let nodes = children ?? element.children
        if canCollapseInline(nodes, customRenderers: custom) {
            buildInlineText(nodes, config: config, customRenderers: custom, onLinkTap: onLinkTap, baseFont: baseFont)
                .ifLet(style) { view, style in view.applyStyle(style, defaultFont: defaultFont) }
        } else if children != nil {
            VStack(alignment: .leading) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { _, child in
                    NodeRenderer(node: child, blockContext: true)
                }
            }
            .ifLet(style) { view, style in view.applyStyle(style, defaultFont: defaultFont) }
        } else {
            renderChildren()
                .ifLet(style) { view, style in view.applyStyle(style, defaultFont: defaultFont) }
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
        let linkColor = config.link.foregroundColor ?? .blue

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
                    .foregroundStyle(linkColor)
            }
            .buttonStyle(.plain)
            .applyStyle(config.link, skipForegroundColor: true)
            .accessibilityAddTraits(.isLink)
        } else {
            renderChildren()
                .underline()
                .foregroundStyle(linkColor)
                .applyStyle(config.link, skipForegroundColor: true)
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
        } else {
            renderWithInlineCollapsing(item.children, style: config.listItem)
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

// MARK: - Style Application

extension View {
    @ViewBuilder
    func applyStyle(
        _ style: HTMLElementStyle,
        defaultFont: Font? = nil,
        skipFont: Bool = false,
        skipForegroundColor: Bool = false,
        skipBackgroundColor: Bool = false,
        skipPadding: Bool = false,
        skipCornerRadius: Bool = false,
        skipBorderWidth: Bool = false
    ) -> some View {
        self
            .ifLet(!skipFont ? (style.font ?? defaultFont) : defaultFont) { view, font in
                view.font(font)
            }
            .ifLet(!skipForegroundColor ? style.foregroundColor : nil) { view, color in
                view.foregroundStyle(color)
            }
            .ifLet(!skipBackgroundColor ? style.backgroundColor : nil) { view, color in
                view.background(color)
            }
            .ifLet(!skipPadding ? style.padding : nil) { view, padding in
                view.padding(padding)
            }
            .ifLet(style.lineSpacing) { view, spacing in
                view.lineSpacing(spacing)
            }
            .ifLet(!skipCornerRadius ? style.cornerRadius : nil) { view, radius in
                view.clipShape(RoundedRectangle(cornerRadius: radius))
            }
            .ifLet(!skipBorderWidth ? style.borderWidth : nil) { view, width in
                view.overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius ?? 0)
                        .stroke(style.borderColor ?? style.foregroundColor ?? Color.accentColor, lineWidth: width)
                )
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
