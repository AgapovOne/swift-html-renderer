import SwiftUI

// MARK: - HTMLElementStyle

public struct HTMLElementStyle: Sendable {
    public var font: Font?
    public var foregroundColor: Color?
    public var backgroundColor: Color?
    public var padding: EdgeInsets?
    public var lineSpacing: CGFloat?

    public init(
        font: Font? = nil,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets? = nil,
        lineSpacing: CGFloat? = nil
    ) {
        self.font = font
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.lineSpacing = lineSpacing
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
        tableCell: HTMLElementStyle = HTMLElementStyle()
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
            padding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        ),
        blockquote: HTMLElementStyle(
            padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
        ),
        link: HTMLElementStyle(foregroundColor: .blue),
        tableHeader: HTMLElementStyle(font: .body)
    )
}
