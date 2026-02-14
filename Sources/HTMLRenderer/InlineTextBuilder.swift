import HTMLParser
import SwiftUI

private let phrasingTags: Set<String> = [
    "b", "strong", "i", "em", "u", "s", "del",
    "code", "span", "sub", "sup", "a", "br",
    "mark", "small", "kbd", "q", "cite", "ins", "abbr",
]

func canCollapseInline(_ children: [HTMLNode], customRenderers: HTMLCustomRenderers = HTMLCustomRenderers()) -> Bool {
    if customRenderers.link != nil && customRenderers.linkInlineText == nil {
        let hasLink = containsTag("a", in: children)
        if hasLink { return false }
    }

    return children.allSatisfy { node in
        switch node {
        case .text, .comment:
            return true
        case .element(let el):
            // 1. tagInlineText — explicitly inline (highest priority)
            if customRenderers.tagInlineText[el.tagName] != nil {
                return canCollapseInline(el.children, customRenderers: customRenderers)
            }
            // 2. tagRenderers — explicitly block (blocks collapsing)
            if customRenderers.tagRenderers[el.tagName] != nil {
                return false
            }
            // 3. Built-in phrasing tags
            if phrasingTags.contains(el.tagName) {
                return canCollapseInline(el.children, customRenderers: customRenderers)
            }
            return false
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
    customRenderers: HTMLCustomRenderers = HTMLCustomRenderers(),
    onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)? = nil,
    baseFont: Font = .body
) -> Text {
    children.reduce(Text("")) { result, node in
        result + buildNodeText(node, styles: styles, customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont)
    }
}

private func buildNodeText(
    _ node: HTMLNode,
    styles: InlineStyles,
    customRenderers: HTMLCustomRenderers,
    onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)?,
    baseFont: Font
) -> Text {
    switch node {
    case .text(let text):
        return applyStyles(text, styles: styles, baseFont: baseFont)
    case .comment:
        return Text("")
    case .element(let el):
        return buildElementText(el, parentStyles: styles, customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont)
    }
}

private func buildElementText(
    _ element: HTMLElement,
    parentStyles: InlineStyles,
    customRenderers: HTMLCustomRenderers,
    onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)?,
    baseFont: Font
) -> Text {
    // Custom inline override — priority for all tags except <a>
    // (<a> is handled separately due to linkInlineText)
    if element.tagName != "a",
       let tagInline = customRenderers.tagInlineText[element.tagName] {
        let childText = buildInlineText(
            element.children, styles: parentStyles,
            customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont
        )
        return tagInline(childText, element.attributes)
    }

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
        if let inlineText = customRenderers.linkInlineText {
            var linkStyles = parentStyles
            if let href = element.attributes["href"], let url = URL(string: href) {
                linkStyles.linkURL = url
            }
            let childText = buildInlineText(
                element.children, styles: linkStyles,
                customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont
            )
            let url = element.attributes["href"].flatMap { URL(string: $0) }
            return inlineText(childText, url, element.attributes)
        }
        styles.underline = true
        styles.foregroundColor = .blue
        if let href = element.attributes["href"], let url = URL(string: href) {
            styles.linkURL = url
        }
    case "br":
        return Text("\n")
    case "span", "abbr":
        break
    case "mark":
        styles.bold = true
        styles.foregroundColor = styles.foregroundColor ?? Color.orange
    case "small":
        return buildInlineText(element.children, styles: styles, customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: .caption2)
    case "kbd":
        styles.monospaced = true
    case "q":
        let inner = buildInlineText(element.children, styles: styles, customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont)
        return Text("\u{201C}") + inner + Text("\u{201D}")
    case "cite":
        styles.italic = true
    case "ins":
        styles.underline = true
    default:
        break
    }

    return buildInlineText(element.children, styles: styles, customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont)
}

private func applyStyles(_ text: String, styles: InlineStyles, baseFont: Font = .body) -> Text {
    if styles.linkURL != nil {
        var attrStr = AttributedString(text)
        attrStr.link = styles.linkURL
        if styles.bold {
            attrStr.font = baseFont.bold()
        }
        if styles.italic {
            attrStr.font = (attrStr.font ?? baseFont).italic()
        }
        if styles.underline {
            attrStr.underlineStyle = .single
        }
        if styles.strikethrough {
            attrStr.strikethroughStyle = .single
        }
        if styles.monospaced {
            attrStr.font = baseFont.monospaced()
        }
        if styles.isSubscript {
            attrStr.font = .caption2
            attrStr.baselineOffset = -4
        }
        if styles.isSuperscript {
            attrStr.font = .caption2
            attrStr.baselineOffset = 8
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
        result = result.foregroundStyle(color)
    }

    return result
}
