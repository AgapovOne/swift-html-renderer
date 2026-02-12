import HTMLParser
import SwiftUI

private let phrasingTags: Set<String> = [
    "b", "strong", "i", "em", "u", "s", "del",
    "code", "span", "sub", "sup", "a", "br",
]

func canCollapseInline(_ children: [HTMLNode]) -> Bool {
    children.allSatisfy { node in
        switch node {
        case .text, .comment:
            return true
        case .element(let el):
            guard phrasingTags.contains(el.tagName) else { return false }
            return canCollapseInline(el.children)
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
}

func buildInlineText(
    _ children: [HTMLNode],
    styles: InlineStyles = InlineStyles(),
    config: HTMLStyleConfiguration
) -> Text {
    children.reduce(Text("")) { result, node in
        result + buildNodeText(node, styles: styles, config: config)
    }
}

private func buildNodeText(
    _ node: HTMLNode,
    styles: InlineStyles,
    config: HTMLStyleConfiguration
) -> Text {
    switch node {
    case .text(let text):
        return applyStyles(Text(text), styles: styles)
    case .comment:
        return Text("")
    case .element(let el):
        return buildElementText(el, parentStyles: styles, config: config)
    }
}

private func buildElementText(
    _ element: HTMLElement,
    parentStyles: InlineStyles,
    config: HTMLStyleConfiguration
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
    case "br":
        return Text("\n")
    case "span":
        break
    default:
        break
    }

    return buildInlineText(element.children, styles: styles, config: config)
}

private func applyStyles(_ text: Text, styles: InlineStyles) -> Text {
    var result = text

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
