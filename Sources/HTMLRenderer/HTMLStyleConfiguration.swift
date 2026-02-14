import SwiftUI

// MARK: - HTMLElementStyle

public struct HTMLElementStyle: Sendable {
    public var font: Font?
    public var foregroundColor: Color?
    public var backgroundColor: Color?
    public var padding: EdgeInsets?
    public var lineSpacing: CGFloat?
    public var cornerRadius: CGFloat?
    public var borderColor: Color?
    public var borderWidth: CGFloat?

    public init(
        font: Font? = nil,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets? = nil,
        lineSpacing: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat? = nil
    ) {
        self.font = font
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.lineSpacing = lineSpacing
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
}

// MARK: - HTMLStyleConfiguration

public struct HTMLStyleConfiguration: Sendable {
    public var heading1: HTMLElementStyle
    public var heading2: HTMLElementStyle
    public var heading3: HTMLElementStyle
    public var heading4: HTMLElementStyle
    public var heading5: HTMLElementStyle
    public var heading6: HTMLElementStyle
    public var paragraph: HTMLElementStyle
    public var bold: HTMLElementStyle
    public var italic: HTMLElementStyle
    public var underline: HTMLElementStyle
    public var strikethrough: HTMLElementStyle
    public var code: HTMLElementStyle
    public var preformatted: HTMLElementStyle
    public var blockquote: HTMLElementStyle
    public var link: HTMLElementStyle
    public var listItem: HTMLElementStyle
    public var tableHeader: HTMLElementStyle
    public var tableCell: HTMLElementStyle
    public var mark: HTMLElementStyle
    public var small: HTMLElementStyle
    public var keyboard: HTMLElementStyle

    // Layout values
    public var blockSpacing: CGFloat
    public var listSpacing: CGFloat
    public var listMarkerSpacing: CGFloat
    public var bulletMarker: String

    public init(
        heading1: HTMLElementStyle = HTMLElementStyle(),
        heading2: HTMLElementStyle = HTMLElementStyle(),
        heading3: HTMLElementStyle = HTMLElementStyle(),
        heading4: HTMLElementStyle = HTMLElementStyle(),
        heading5: HTMLElementStyle = HTMLElementStyle(),
        heading6: HTMLElementStyle = HTMLElementStyle(),
        paragraph: HTMLElementStyle = HTMLElementStyle(),
        bold: HTMLElementStyle = HTMLElementStyle(),
        italic: HTMLElementStyle = HTMLElementStyle(),
        underline: HTMLElementStyle = HTMLElementStyle(),
        strikethrough: HTMLElementStyle = HTMLElementStyle(),
        code: HTMLElementStyle = HTMLElementStyle(),
        preformatted: HTMLElementStyle = HTMLElementStyle(),
        blockquote: HTMLElementStyle = HTMLElementStyle(),
        link: HTMLElementStyle = HTMLElementStyle(),
        listItem: HTMLElementStyle = HTMLElementStyle(),
        tableHeader: HTMLElementStyle = HTMLElementStyle(),
        tableCell: HTMLElementStyle = HTMLElementStyle(),
        mark: HTMLElementStyle = HTMLElementStyle(),
        small: HTMLElementStyle = HTMLElementStyle(),
        keyboard: HTMLElementStyle = HTMLElementStyle(),
        blockSpacing: CGFloat = 8,
        listSpacing: CGFloat = 4,
        listMarkerSpacing: CGFloat = 6,
        bulletMarker: String = "•"
    ) {
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.heading4 = heading4
        self.heading5 = heading5
        self.heading6 = heading6
        self.paragraph = paragraph
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.code = code
        self.preformatted = preformatted
        self.blockquote = blockquote
        self.link = link
        self.listItem = listItem
        self.tableHeader = tableHeader
        self.tableCell = tableCell
        self.mark = mark
        self.small = small
        self.keyboard = keyboard
        self.blockSpacing = blockSpacing
        self.listSpacing = listSpacing
        self.listMarkerSpacing = listMarkerSpacing
        self.bulletMarker = bulletMarker
    }

    public static let `default` = HTMLStyleConfiguration(
        heading1: HTMLElementStyle(font: .largeTitle),
        heading2: HTMLElementStyle(font: .title),
        heading3: HTMLElementStyle(font: .title2),
        heading4: HTMLElementStyle(font: .title3),
        heading5: HTMLElementStyle(font: .headline),
        heading6: HTMLElementStyle(font: .subheadline),
        paragraph: HTMLElementStyle(font: .body),
        code: HTMLElementStyle(font: .body),
        preformatted: HTMLElementStyle(
            font: .system(.body, design: .monospaced),
            backgroundColor: Color.gray.opacity(0.1),
            padding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
            cornerRadius: 8
        ),
        blockquote: HTMLElementStyle(
            padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0),
            borderWidth: 3
        ),
        link: HTMLElementStyle(foregroundColor: .blue),
        tableHeader: HTMLElementStyle(font: .body),
        mark: HTMLElementStyle(backgroundColor: Color.yellow.opacity(0.3)),
        small: HTMLElementStyle(font: .caption),
        keyboard: HTMLElementStyle(font: .system(.body, design: .monospaced))
    )
}
