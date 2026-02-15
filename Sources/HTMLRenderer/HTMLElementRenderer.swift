import HTMLParser
import SwiftUI

// MARK: - HTMLElementRenderer

@MainActor
public protocol HTMLElementRenderer: Sendable {
    associatedtype HeadingBody: View = Never
    associatedtype ParagraphBody: View = Never
    associatedtype LinkBody: View = Never
    associatedtype ListBody: View = Never
    associatedtype ListItemBody: View = Never
    associatedtype BlockquoteBody: View = Never
    associatedtype CodeBlockBody: View = Never
    associatedtype TableBody: View = Never
    associatedtype DefinitionListBody: View = Never
    associatedtype UnknownElementBody: View = Never
    associatedtype CustomTagBody: View = Never

    @ViewBuilder func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> HeadingBody
    @ViewBuilder func paragraph(children: [HTMLNode], attributes: [String: String]) -> ParagraphBody
    @ViewBuilder func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> LinkBody
    @ViewBuilder func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> ListBody
    @ViewBuilder func listItem(children: [HTMLNode], attributes: [String: String]) -> ListItemBody
    @ViewBuilder func blockquote(children: [HTMLNode], attributes: [String: String]) -> BlockquoteBody
    @ViewBuilder func codeBlock(children: [HTMLNode], attributes: [String: String]) -> CodeBlockBody
    @ViewBuilder func table(children: [HTMLNode], attributes: [String: String]) -> TableBody
    @ViewBuilder func definitionList(children: [HTMLNode], attributes: [String: String]) -> DefinitionListBody
    @ViewBuilder func unknownElement(element: HTMLElement) -> UnknownElementBody
    @ViewBuilder func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> CustomTagBody

    var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { get }
    var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { get }
    var customTagNames: Set<String> { get }
}

// MARK: - Default implementations (Never body = not overridden)

extension HTMLElementRenderer where HeadingBody == Never {
    public func heading(children: [HTMLNode], level: Int, attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where ParagraphBody == Never {
    public func paragraph(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where LinkBody == Never {
    public func link(children: [HTMLNode], href: String?, attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where ListBody == Never {
    public func list(children: [HTMLNode], ordered: Bool, attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where ListItemBody == Never {
    public func listItem(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where BlockquoteBody == Never {
    public func blockquote(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where CodeBlockBody == Never {
    public func codeBlock(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where TableBody == Never {
    public func table(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where DefinitionListBody == Never {
    public func definitionList(children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

extension HTMLElementRenderer where UnknownElementBody == Never {
    public func unknownElement(element: HTMLElement) -> Never { fatalError() }
}

extension HTMLElementRenderer where CustomTagBody == Never {
    public func customTag(name: String, children: [HTMLNode], attributes: [String: String]) -> Never { fatalError() }
}

// MARK: - Default property implementations

extension HTMLElementRenderer {
    public var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] { [:] }
    public var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)? { nil }
    public var customTagNames: Set<String> { [] }
}

// MARK: - DefaultHTMLElementRenderer

public struct DefaultHTMLElementRenderer: HTMLElementRenderer {
    public init() {}
}
