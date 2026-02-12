import HTMLParser
import SwiftUI

private let phrasingTags: Set<String> = [
    "b", "strong", "i", "em", "u", "s", "del",
    "code", "span", "sub", "sup", "a", "br",
]

func canCollapseInline(_ children: [HTMLNode], customRenderers: HTMLCustomRenderers = HTMLCustomRenderers()) -> Bool {
    if customRenderers.link != nil {
        let hasLink = containsTag("a", in: children)
        if hasLink { return false }
    }

    return children.allSatisfy { node in
        switch node {
        case .text, .comment:
            return true
        case .element(let el):
            guard phrasingTags.contains(el.tagName) else { return false }
            return canCollapseInline(el.children, customRenderers: customRenderers)
        }
    }
}

private func containsTag(_ tag: String, in children: [HTMLNode]) -> Bool {
    children.contains { node in
        switch node {
        case .text, .comment:
            return false
        case .element(let el):
            return el.tagName == tag || containsTag(tag, in: el.children)
        }
    }
}

struct InlineStyles {
    var bold = false
    var italic = false
    var underline = false
    var strikethrough = false
    var monospaced = false
    var isSubscript = false
    var isSuperscript = false
    var foregroundColor: Color?
    var linkURL: URL?
}

func buildInlineText(
    _ children: [HTMLNode],
    styles: InlineStyles = InlineStyles(),
    config: HTMLStyleConfiguration,
    onLinkTap: (@Sendable (URL) -> Void)? = nil
) -> Text {
    children.reduce(Text("")) { result, node in
        result + buildNodeText(node, styles: styles, config: config, onLinkTap: onLinkTap)
    }
}

private func buildNodeText(
    _ node: HTMLNode,
    styles: InlineStyles,
    config: HTMLStyleConfiguration,
    onLinkTap: (@Sendable (URL) -> Void)?
) -> Text {
    switch node {
    case .text(let text):
        return applyStyles(text, styles: styles)
    case .comment:
        return Text("")
    case .element(let el):
        return buildElementText(el, parentStyles: styles, config: config, onLinkTap: onLinkTap)
    }
}

private func buildElementText(
    _ element: HTMLElement,
    parentStyles: InlineStyles,
    config: HTMLStyleConfiguration,
    onLinkTap: (@Sendable (URL) -> Void)?
) -> Text {
    var styles = parentStyles

    switch element.tagName {
    case "b", "strong":
        styles.bold = true
    case "i", "em":
        styles.italic = true
    case "u":
        styles.underline = true
    case "s", "del":
        styles.strikethrough = true
    case "code":
        styles.monospaced = true
    case "sub":
        styles.isSubscript = true
    case "sup":
        styles.isSuperscript = true
    case "a":
        styles.underline = true
        styles.foregroundColor = config.link.foregroundColor ?? .blue
        if onLinkTap != nil, let href = element.attributes["href"], let url = URL(string: href) {
            styles.linkURL = url
        }
    case "br":
        return Text("\n")
    case "span":
        break
    default:
        break
    }

    return buildInlineText(element.children, styles: styles, config: config, onLinkTap: onLinkTap)
}

private func applyStyles(_ text: String, styles: InlineStyles) -> Text {
    if styles.linkURL != nil {
        var attrStr = AttributedString(text)
        attrStr.link = styles.linkURL
        if styles.bold {
            attrStr.font = .body.bold()
        }
        if styles.italic {
            attrStr.font = (attrStr.font ?? .body).italic()
        }
        if styles.underline {
            attrStr.underlineStyle = .single
        }
        if styles.strikethrough {
            attrStr.strikethroughStyle = .single
        }
        if styles.monospaced {
            attrStr.font = .body.monospaced()
        }
        if let color = styles.foregroundColor {
            attrStr.foregroundColor = color
        }
        return Text(attrStr)
    }

    var result = Text(text)

    if styles.bold {
        result = result.bold()
    }
    if styles.italic {
        result = result.italic()
    }
    if styles.underline {
        result = result.underline()
    }
    if styles.strikethrough {
        result = result.strikethrough()
    }
    if styles.monospaced {
        result = result.monospaced()
    }
    if styles.isSubscript {
        result = result.font(.caption2).baselineOffset(-4)
    }
    if styles.isSuperscript {
        result = result.font(.caption2).baselineOffset(8)
    }
    if let color = styles.foregroundColor {
        result = result.foregroundColor(color)
    }

    return result
}
