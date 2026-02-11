public struct HTMLElement: Equatable, Hashable, Sendable {
    public var tagName: String
    public var attributes: [String: String]
    public var children: [HTMLNode]

    public init(tagName: String, attributes: [String: String] = [:], children: [HTMLNode] = []) {
        self.tagName = tagName
        self.attributes = attributes
        self.children = children
    }
}
