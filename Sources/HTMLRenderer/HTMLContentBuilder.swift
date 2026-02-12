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
    let closure: @MainActor @Sendable ([HTMLNode], String?, [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], String?, [String: String]) -> Content) {
        self.closure = { children, href, attributes in
            AnyView(render(children, href, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.link = closure
    }
}

public struct HTMLListRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping ([HTMLNode], [String: String]) -> Content) {
        self.closure = { children, attributes in
            AnyView(render(children, attributes))
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

public struct HTMLImageRenderer: HTMLRendererComponent {
    let closure: @MainActor @Sendable (String?, String?, [String: String]) -> AnyView

    public init<Content: View>(@ViewBuilder render: @MainActor @Sendable @escaping (String?, String?, [String: String]) -> Content) {
        self.closure = { src, alt, attributes in
            AnyView(render(src, alt, attributes))
        }
    }

    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.image = closure
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

// MARK: - HTMLCustomRenderers

public struct HTMLCustomRenderers: Sendable {
    var heading: (@MainActor @Sendable ([HTMLNode], Int, [String: String]) -> AnyView)?
    var paragraph: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var link: (@MainActor @Sendable ([HTMLNode], String?, [String: String]) -> AnyView)?
    var list: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var listItem: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var blockquote: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var codeBlock: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?
    var image: (@MainActor @Sendable (String?, String?, [String: String]) -> AnyView)?
    var table: (@MainActor @Sendable ([HTMLNode], [String: String]) -> AnyView)?

    public init() {}

    mutating func merge(_ other: HTMLCustomRenderers) {
        if let v = other.heading { heading = v }
        if let v = other.paragraph { paragraph = v }
        if let v = other.link { link = v }
        if let v = other.list { list = v }
        if let v = other.listItem { listItem = v }
        if let v = other.blockquote { blockquote = v }
        if let v = other.codeBlock { codeBlock = v }
        if let v = other.image { image = v }
        if let v = other.table { table = v }
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
