import HTMLParser
import SwiftUI

// MARK: - HTMLRendererComponent

public protocol HTMLRendererComponent {
    func apply(to renderers: inout HTMLCustomRenderers)
}

// MARK: - Marker Types

public struct HTMLHeadingRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], Int, [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], Int, [String: String]) -> Content) {
        self.closure = { children, level, attributes in
            AnyView(render(children, level, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.heading = closure
    }
}

public struct HTMLParagraphRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.paragraph = closure
    }
}

public struct HTMLLinkRenderer: HTMLRendererComponent {
    let closure: (@MainActor @Sendable ([HTMLNode], String?, [String: String]) -> AnyView)?
    let inlineTextClosure: (@Sendable (Text, URL?, [String: String]) -> Text)?

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], String?, [String: String]) -> Content) {
        self.closure = { children, href, attributes in
            AnyView(render(children, href, attributes))
        }
        self.inlineTextClosure = nil
    }

    public init<Content: View>(
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], String?, [String: String]) -> Content,
        inlineText: @Sendable @escaping (Text, URL?, [String: String]) -> Text
    ) {
        self.closure = { children, href, attributes in
            AnyView(render(children, href, attributes))
        }
        self.inlineTextClosure = inlineText
    }

    public init(
        inlineText: @Sendable @escaping (Text, URL?, [String: String]) -> Text
    ) {
        self.closure = nil
        self.inlineTextClosure = inlineText
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        if let closure { renderers.link = closure }
        if let inlineTextClosure { renderers.linkInlineText = inlineTextClosure }
    }
}

public struct HTMLListRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], Bool, [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], Bool, [String: String]) -> Content) {
        self.closure = { children, ordered, attributes in
            AnyView(render(children, ordered, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.list = closure
    }
}

public struct HTMLListItemRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.listItem = closure
    }
}

public struct HTMLBlockquoteRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.blockquote = closure
    }
}

public struct HTMLCodeBlockRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.codeBlock = closure
    }
}

public struct HTMLTableRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.table = closure
    }
}

public struct HTMLDefinitionListRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.definitionList = closure
    }
}

public struct HTMLTagRenderer: HTMLRendererComponent {
    let tagName: String
    let closure: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    let inlineTextClosure: (@Sendable (Text, [String: String]) -> Text)?

    public init<Content: View>(_ tagName: String, @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.tagName = tagName.lowercased()
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
        self.inlineTextClosure = nil
    }

    public init<Content: View>(
        _ tagName: String,
        @ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content,
        inlineText: @Sendable @escaping (Text, [String: String]) -> Text
    ) {
        self.tagName = tagName.lowercased()
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
        }
        self.inlineTextClosure = inlineText
    }

    public init(
        _ tagName: String,
        inlineText: @Sendable @escaping (Text, [String: String]) -> Text
    ) {
        self.tagName = tagName.lowercased()
        self.closure = nil
        self.inlineTextClosure = inlineText
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        if let closure { renderers.tagRenderers[tagName] = closure }
        if let inlineTextClosure { renderers.tagInlineText[tagName] = inlineTextClosure }
    }
}

// MARK: - HTMLCustomRenderers

public struct HTMLCustomRenderers: Sendable {
    var heading: (@MainActor @Sendable ([HTMLNode], Int, [String: String]) -> AnyView)?
    var paragraph: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var link: (@MainActor @Sendable ([HTMLNode], String?, [String: String]) -> AnyView)?
    var list: (@MainActor @Sendable ([HTMLNode], Bool, [String: String]) -> AnyView)?
    var listItem: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var blockquote: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var codeBlock: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var table: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var definitionList: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var tagRenderers: [String: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView] = [:]
    var linkInlineText: (@Sendable (Text, URL?, [String: String]) -> Text)?
    var tagInlineText: [String: @Sendable (Text, [String: String]) -> Text] = [:]

    public init() {}

    mutating func merge(_ other: HTMLCustomRenderers) {
        if let v = other.heading { heading = v }
        if let v = other.paragraph { paragraph = v }
        if let v = other.link { link = v }
        if let v = other.list { list = v }
        if let v = other.listItem { listItem = v }
        if let v = other.blockquote { blockquote = v }
        if let v = other.codeBlock { codeBlock = v }
        if let v = other.table { table = v }
        if let v = other.definitionList { definitionList = v }
        for (tag, renderer) in other.tagRenderers {
            tagRenderers[tag] = renderer
        }
        if let v = other.linkInlineText { linkInlineText = v }
        for (tag, renderer) in other.tagInlineText {
            tagInlineText[tag] = renderer
        }
    }
}

// MARK: - HTMLContentBuilder

@resultBuilder
public struct HTMLContentBuilder {
    public static func buildBlock(_ components: HTMLRendererComponent...) -> HTMLCustomRenderers {
        var renderers = HTMLCustomRenderers()
        for component in components {
            component.apply(to: &renderers)
        }
        return renderers
    }
}
