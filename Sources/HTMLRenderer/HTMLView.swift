import HTMLParser
import SwiftUI

// MARK: - Environment Keys

private struct OnLinkTapKey: EnvironmentKey {
    static let defaultValue: (@Sendable (URL) -> Void)? = nil
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
    var onLinkTap: (@Sendable (URL) -> Void)? {
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
    private let onLinkTap: (@Sendable (URL) -> Void)?
    private let onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)?
    private let customRenderers: HTMLCustomRenderers

    public init(
        document: HTMLDocument,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
    ) {
        self.document = document
        self.configuration = configuration
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = HTMLCustomRenderers()
    }

    public init(
        html: String,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil
    ) {
        self.document = HTMLParser.parseFragment(html)
        self.configuration = configuration
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = HTMLCustomRenderers()
    }

    public init(
        document: HTMLDocument,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil,
        @HTMLContentBuilder content: () -> HTMLCustomRenderers
    ) {
        self.document = document
        self.configuration = configuration
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = content()
    }

    public init(
        html: String,
        configuration: HTMLStyleConfiguration = .default,
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onUnknownElement: (@MainActor @Sendable (HTMLElement) -> AnyView)? = nil,
        @HTMLContentBuilder content: () -> HTMLCustomRenderers
    ) {
        self.document = HTMLParser.parseFragment(html)
        self.configuration = configuration
        self.onLinkTap = onLinkTap
        self.onUnknownElement = onUnknownElement
        self.customRenderers = content()
    }

    public var body: some View {
        Group {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, node in
                NodeRenderer(node: node)
            }
        }
        .environment(\.onLinkTap, onLinkTap)
        .environment(\.onUnknownElement, onUnknownElement)
        .environment(\.styleConfiguration, configuration)
        .environment(\.customRenderers, customRenderers)
        .ifLet(onLinkTap) { view, handler in
            view.environment(\.openURL, OpenURLAction { url in
                handler(url)
                return .handled
            })
        }
    }
}

// MARK: - NodeRenderer

struct NodeRenderer: View {
    let node: HTMLNode

    var body: some View {
        switch node {
        case .text(let text):
            Text(text)
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

    var body: some View {
        switch element.tagName {
        case "h1":
            if let heading = custom.heading {
                heading(element.children, 1, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading1, defaultFont: .largeTitle)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading1, defaultFont: .largeTitle)
                    .accessibilityAddTraits(.isHeader)
            }
        case "h2":
            if let heading = custom.heading {
                heading(element.children, 2, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading2, defaultFont: .title)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading2, defaultFont: .title)
                    .accessibilityAddTraits(.isHeader)
            }
        case "h3":
            if let heading = custom.heading {
                heading(element.children, 3, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading3, defaultFont: .title2)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading3, defaultFont: .title2)
                    .accessibilityAddTraits(.isHeader)
            }
        case "h4":
            if let heading = custom.heading {
                heading(element.children, 4, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading4, defaultFont: .title3)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading4, defaultFont: .title3)
                    .accessibilityAddTraits(.isHeader)
            }
        case "h5":
            if let heading = custom.heading {
                heading(element.children, 5, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading5, defaultFont: .headline)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading5, defaultFont: .headline)
                    .accessibilityAddTraits(.isHeader)
            }
        case "h6":
            if let heading = custom.heading {
                heading(element.children, 6, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.heading6, defaultFont: .subheadline)
                    .accessibilityAddTraits(.isHeader)
            } else {
                renderChildren()
                    .applyStyle(config.heading6, defaultFont: .subheadline)
                    .accessibilityAddTraits(.isHeader)
            }
        case "p":
            if let paragraph = custom.paragraph {
                paragraph(element.children, element.attributes)
            } else if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .applyStyle(config.paragraph, defaultFont: .body)
            } else {
                renderChildren()
                    .applyStyle(config.paragraph, defaultFont: .body)
            }
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
        case "span":
            renderChildren()
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
        case "div", "article", "section", "main", "header", "footer", "nav", "aside":
            VStack(alignment: .leading, spacing: 8) {
                renderChildren()
            }
        case "blockquote":
            if let blockquote = custom.blockquote {
                blockquote(element.children, element.attributes)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    renderChildren()
                }
                .padding(.leading, config.blockquote.padding?.leading ?? 16)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .frame(width: 3)
                        .foregroundStyle(config.blockquote.foregroundColor ?? Color.accentColor)
                }
                .applyStyle(config.blockquote, skipPadding: true)
            }
        case "pre":
            if let codeBlock = custom.codeBlock {
                codeBlock(element.children, element.attributes)
            } else {
                VStack(alignment: .leading) {
                    renderChildren()
                }
                .font(config.preformatted.font ?? .system(.body, design: .monospaced))
                .padding(config.preformatted.padding.map { EdgeInsets(top: $0.top, leading: $0.leading, bottom: $0.bottom, trailing: $0.trailing) } ?? EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .background(config.preformatted.backgroundColor ?? Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .applyStyle(config.preformatted, skipFont: true, skipBackgroundColor: true, skipPadding: true)
            }
        case "hr":
            Divider()
        case "figure":
            VStack(alignment: .leading, spacing: 4) {
                renderChildren()
            }
        case "figcaption":
            if canCollapseInline(element.children, customRenderers: custom) {
                buildInlineText(element.children, config: config, onLinkTap: onLinkTap)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                renderChildren()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case "ul":
            if let list = custom.list {
                list(element.children, element.attributes)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(listItems().enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            renderListItemContent(item)
                        }
                    }
                }
            }
        case "ol":
            if let list = custom.list {
                list(element.children, element.attributes)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(listItems().enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).")
                            renderListItemContent(item)
                        }
                    }
                }
            }
        case "li":
            if let listItem = custom.listItem {
                listItem(element.children, element.attributes)
            } else {
                renderChildren()
            }
        case "table":
            if let table = custom.table {
                table(element.children, element.attributes)
            } else {
                Grid(alignment: .leading) {
                    ForEach(Array(tableRows().enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(Array(tableCells(in: row).enumerated()), id: \.offset) { _, cell in
                                if cell.tagName == "th" {
                                    if canCollapseInline(cell.children, customRenderers: custom) {
                                        buildInlineText(cell.children, config: config, onLinkTap: onLinkTap)
                                            .bold()
                                            .applyStyle(config.tableHeader)
                                    } else {
                                        VStack(alignment: .leading) {
                                            ForEach(Array(cell.children.enumerated()), id: \.offset) { _, child in
                                                NodeRenderer(node: child)
                                            }
                                        }
                                        .bold()
                                        .applyStyle(config.tableHeader)
                                    }
                                } else {
                                    if canCollapseInline(cell.children, customRenderers: custom) {
                                        buildInlineText(cell.children, config: config, onLinkTap: onLinkTap)
                                            .applyStyle(config.tableCell)
                                    } else {
                                        VStack(alignment: .leading) {
                                            ForEach(Array(cell.children.enumerated()), id: \.offset) { _, child in
                                                NodeRenderer(node: child)
                                            }
                                        }
                                        .applyStyle(config.tableCell)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case "thead", "tbody", "tfoot":
            renderChildren()
        case "tr":
            renderChildren()
        case "td", "th":
            renderChildren()
        case "img":
            if let image = custom.image {
                image(element.attributes["src"], element.attributes["alt"], element.attributes)
            } else {
                renderImage()
            }
        case "a":
            if let link = custom.link {
                link(element.children, element.attributes["href"], element.attributes)
            } else {
                renderLink()
            }
        default:
            renderUnknownElement()
        }
    }

    @ViewBuilder
    private func renderChildren() -> some View {
        ForEach(Array(element.children.enumerated()), id: \.offset) { _, child in
            NodeRenderer(node: child)
        }
    }

    @ViewBuilder
    private func renderImage() -> some View {
        let src = element.attributes["src", default: ""]
        let alt = element.attributes["alt"]
        let width = element.attributes["width"].flatMap { Double($0) }
        let height = element.attributes["height"].flatMap { Double($0) }
        let imageStyle = config.image

        if src.isEmpty {
            EmptyView()
        } else if let url = URL(string: src) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .ifLet(imageStyle.placeholderColor) { view, color in
                            view.tint(color)
                        }
                case .success(let image):
                    if let width, let height {
                        image
                            .resizable()
                            .aspectRatio(contentMode: imageStyle.contentMode ?? .fit)
                            .frame(width: width, height: height)
                    } else {
                        image
                            .resizable()
                            .aspectRatio(contentMode: imageStyle.contentMode ?? .fit)
                    }
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .ifLet(imageStyle.maxHeight) { view, maxHeight in
                view.frame(maxHeight: maxHeight)
            }
            .ifLet(imageStyle.cornerRadius) { view, radius in
                view.clipShape(RoundedRectangle(cornerRadius: radius))
            }
            .ifLet(alt) { view, alt in
                view.accessibilityLabel(alt)
            }
            .if(alt == nil) { view in
                view.accessibilityHidden(true)
            }
        } else {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func renderLink() -> some View {
        let href = element.attributes["href"]
        let url = href.flatMap { URL(string: $0) }
        let linkColor = config.link.foregroundColor ?? .blue

        if let onLinkTap, let url {
            Button {
                onLinkTap(url)
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
        } else if canCollapseInline(item.children, customRenderers: custom) {
            buildInlineText(item.children, config: config, onLinkTap: onLinkTap)
                .applyStyle(config.listItem)
        } else {
            VStack(alignment: .leading) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    NodeRenderer(node: child)
                }
            }
            .applyStyle(config.listItem)
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
        skipPadding: Bool = false
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

    @ViewBuilder
    func `if`(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
