import HTMLParser
import SwiftUI

// MARK: - Heading Override

public struct _HeadingOverride<Base: HTMLElementRenderer, H: View>: HTMLElementRenderer {
    public typealias HeadingBody = H
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], Int, [String: String]) -> H

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> H {
        render(children, level, attributes)
    }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - Paragraph Override

public struct _ParagraphOverride<Base: HTMLElementRenderer, P: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = P
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> P

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> P { render(children, attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - Link Override

public struct _LinkOverride<Base: HTMLElementRenderer, L: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = L
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], String?, [String: String]) -> L
    let _linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)?

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> L { render(children, href, attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { _linkInlineText ?? base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - List Override

public struct _ListOverride<Base: HTMLElementRenderer, L: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = L
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], Bool, [String: String]) -> L

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> L { render(children, ordered, attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - ListItem Override

public struct _ListItemOverride<Base: HTMLElementRenderer, LI: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = LI
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> LI

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> LI { render(children, attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - Blockquote Override

public struct _BlockquoteOverride<Base: HTMLElementRenderer, B: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = B
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> B

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> B { render(children, attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - CodeBlock Override

public struct _CodeBlockOverride<Base: HTMLElementRenderer, C: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = C
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> C

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> C { render(children, attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - Table Override

public struct _TableOverride<Base: HTMLElementRenderer, T: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = T
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> T

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> T { render(children, attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - DefinitionList Override

public struct _DefinitionListOverride<Base: HTMLElementRenderer, D: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = D
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable ([HTMLNode], [String: String]) -> D

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> D { render(children, attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - UnknownElement Override

public struct _UnknownElementOverride<Base: HTMLElementRenderer, U: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = U
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let render: @MainActor @Sendable (HTMLElement) -> U

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> U { render(element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - CustomTag Override (for named custom tags like "video", "details")

public struct _TagOverride<Base: HTMLElementRenderer, T: View>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = T

    let base: Base
    let tagName: String
    let render: @MainActor @Sendable (String, [HTMLNode], [String: String]) -> T
    let _tagInlineText: [String: @Sendable (Text, [String: String]) -> Text]

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> T { render(name, children, attributes) }

    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] {
        base.tagInlineText.merging(_tagInlineText) { _, new in new }
    }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames.union([tagName]) }
}

// MARK: - TagInlineText Override (inline-only tag override, no block view)

public struct _TagInlineTextOverride<Base: HTMLElementRenderer>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let tagName: String
    let inlineText: @Sendable (Text, [String: String]) -> Text

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }

    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] {
        base.tagInlineText.merging([tagName: inlineText]) { _, new in new }
    }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { base.linkInlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - LinkInlineText Override

public struct _LinkInlineTextOverride<Base: HTMLElementRenderer>: HTMLElementRenderer {
    public typealias HeadingBody = Base.HeadingBody
    public typealias ParagraphBody = Base.ParagraphBody
    public typealias LinkBody = Base.LinkBody
    public typealias ListBody = Base.ListBody
    public typealias ListItemBody = Base.ListItemBody
    public typealias BlockquoteBody = Base.BlockquoteBody
    public typealias CodeBlockBody = Base.CodeBlockBody
    public typealias TableBody = Base.TableBody
    public typealias DefinitionListBody = Base.DefinitionListBody
    public typealias UnknownElementBody = Base.UnknownElementBody
    public typealias CustomTagBody = Base.CustomTagBody

    let base: Base
    let inlineText: @Sendable (Text, URL?, [String: String]) -> Text

    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Base.HeadingBody { base.heading(children: children, level: level, attributes: attributes) }
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Base.ParagraphBody { base.paragraph(children: children, attributes: attributes) }
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Base.LinkBody { base.link(children: children, href: href, attributes: attributes) }
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Base.ListBody { base.list(children: children, ordered: ordered, attributes: attributes) }
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Base.ListItemBody { base.listItem(children: children, attributes: attributes) }
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Base.BlockquoteBody { base.blockquote(children: children, attributes: attributes) }
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Base.CodeBlockBody { base.codeBlock(children: children, attributes: attributes) }
    public func table(children: [HTMLNode], attributes: [String: String]) -> Base.TableBody { base.table(children: children, attributes: attributes) }
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Base.DefinitionListBody { base.definitionList(children: children, attributes: attributes) }
    public func unknownElement(element: HTMLElement) -> Base.UnknownElementBody { base.unknownElement(element: element) }
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Base.CustomTagBody { base.customTag(name: name, children: children, attributes: attributes) }
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { base.tagInlineText }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { inlineText }
    public var customTagNames: Set<String> { base.customTagNames }
}

// MARK: - View Modifiers on HTMLView

extension HTMLView {
    public func htmlHeading<H: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], Int, [String: String]) -> H
    ) -> HTMLView<_HeadingOverride<Renderer, H>> {
        HTMLView<_HeadingOverride<Renderer, H>>(
            document: document,

            renderer: _HeadingOverride(base: renderer, render: render)
        )
    }

    public func htmlParagraph<P: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> P
    ) -> HTMLView<_ParagraphOverride<Renderer, P>> {
        HTMLView<_ParagraphOverride<Renderer, P>>(
            document: document,

            renderer: _ParagraphOverride(base: renderer, render: render)
        )
    }

    public func htmlLink<L: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], String?, [String: String]) -> L
    ) -> HTMLView<_LinkOverride<Renderer, L>> {
        HTMLView<_LinkOverride<Renderer, L>>(
            document: document,

            renderer: _LinkOverride(base: renderer, render: render, _linkInlineText: nil)
        )
    }

    public func htmlLink<L: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], String?, [String: String]) -> L,
        inlineText: @Sendable @escaping (Text, URL?, [String: String]) -> Text
    ) -> HTMLView<_LinkOverride<Renderer, L>> {
        HTMLView<_LinkOverride<Renderer, L>>(
            document: document,

            renderer: _LinkOverride(base: renderer, render: render, _linkInlineText: inlineText)
        )
    }

    public func htmlLinkInlineText(
        render: @Sendable @escaping (Text, URL?, [String: String]) -> Text
    ) -> HTMLView<_LinkInlineTextOverride<Renderer>> {
        HTMLView<_LinkInlineTextOverride<Renderer>>(
            document: document,

            renderer: _LinkInlineTextOverride(base: renderer, inlineText: render)
        )
    }

    public func htmlList<L: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], Bool, [String: String]) -> L
    ) -> HTMLView<_ListOverride<Renderer, L>> {
        HTMLView<_ListOverride<Renderer, L>>(
            document: document,

            renderer: _ListOverride(base: renderer, render: render)
        )
    }

    public func htmlListItem<LI: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> LI
    ) -> HTMLView<_ListItemOverride<Renderer, LI>> {
        HTMLView<_ListItemOverride<Renderer, LI>>(
            document: document,

            renderer: _ListItemOverride(base: renderer, render: render)
        )
    }

    public func htmlBlockquote<B: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> B
    ) -> HTMLView<_BlockquoteOverride<Renderer, B>> {
        HTMLView<_BlockquoteOverride<Renderer, B>>(
            document: document,

            renderer: _BlockquoteOverride(base: renderer, render: render)
        )
    }

    public func htmlCodeBlock<C: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> C
    ) -> HTMLView<_CodeBlockOverride<Renderer, C>> {
        HTMLView<_CodeBlockOverride<Renderer, C>>(
            document: document,

            renderer: _CodeBlockOverride(base: renderer, render: render)
        )
    }

    public func htmlTable<T: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> T
    ) -> HTMLView<_TableOverride<Renderer, T>> {
        HTMLView<_TableOverride<Renderer, T>>(
            document: document,

            renderer: _TableOverride(base: renderer, render: render)
        )
    }

    public func htmlDefinitionList<D: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> D
    ) -> HTMLView<_DefinitionListOverride<Renderer, D>> {
        HTMLView<_DefinitionListOverride<Renderer, D>>(
            document: document,

            renderer: _DefinitionListOverride(base: renderer, render: render)
        )
    }

    public func htmlUnknownElement<U: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping (HTMLElement) -> U
    ) -> HTMLView<_UnknownElementOverride<Renderer, U>> {
        HTMLView<_UnknownElementOverride<Renderer, U>>(
            document: document,

            renderer: _UnknownElementOverride(base: renderer, render: render)
        )
    }

    public func htmlTag<T: View>(
        _ name: String,
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> T
    ) -> HTMLView<_TagOverride<Renderer, T>> {
        let lowered = name.lowercased()
        return HTMLView<_TagOverride<Renderer, T>>(
            document: document,

            renderer: _TagOverride(
                base: renderer,
                tagName: lowered,
                render: { _, children, attrs in render(children, attrs) },
                _tagInlineText: [:]
            )
        )
    }

    public func htmlTag<T: View>(
        _ name: String,
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> T,
        inlineText: @Sendable @escaping (Text, [String: String]) -> Text
    ) -> HTMLView<_TagOverride<Renderer, T>> {
        let lowered = name.lowercased()
        return HTMLView<_TagOverride<Renderer, T>>(
            document: document,

            renderer: _TagOverride(
                base: renderer,
                tagName: lowered,
                render: { _, children, attrs in render(children, attrs) },
                _tagInlineText: [lowered: inlineText]
            )
        )
    }

    public func htmlTagInlineText(
        _ name: String,
        render: @Sendable @escaping (Text, [String: String]) -> Text
    ) -> HTMLView<_TagInlineTextOverride<Renderer>> {
        HTMLView<_TagInlineTextOverride<Renderer>>(
            document: document,

            renderer: _TagInlineTextOverride(base: renderer, tagName: name.lowercased(), inlineText: render)
        )
    }

    public func htmlSkipTag(_ name: String) -> HTMLView<_TagOverride<Renderer, HTMLNodeView>> {
        let lowered = name.lowercased()
        return HTMLView<_TagOverride<Renderer, HTMLNodeView>>(
            document: document,

            renderer: _TagOverride(
                base: renderer,
                tagName: lowered,
                render: { _, children, _ in HTMLNodeView(nodes: children) },
                _tagInlineText: [:]
            )
        )
    }
}
