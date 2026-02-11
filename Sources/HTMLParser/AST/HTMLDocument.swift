public struct HTMLDocument: Equatable, Hashable, Sendable {
    public var children: [HTMLNode]

    public init(children: [HTMLNode] = []) {
        self.children = children
    }
}
