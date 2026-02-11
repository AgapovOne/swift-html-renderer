import CGumbo

enum GumboConverter {
    static func convert(_ output: UnsafeMutablePointer<GumboOutput>) -> HTMLDocument {
        let rootNode = output.pointee.document.pointee
        let children = convertChildren(rootNode.v.document.children)
        return HTMLDocument(children: children)
    }

    static func convertFragment(_ output: UnsafeMutablePointer<GumboOutput>) -> HTMLDocument {
        guard let root = output.pointee.root else {
            return HTMLDocument()
        }
        let bodyChildren = findBodyChildren(root)
        return HTMLDocument(children: bodyChildren)
    }

    private static func findBodyChildren(_ root: UnsafeMutablePointer<GumboNode>) -> [HTMLNode] {
        let node = root.pointee
        guard node.type == GUMBO_NODE_ELEMENT else { return [] }
        let element = node.v.element
        // Root is <html>, find <body> among its children
        for i in 0..<Int(element.children.length) {
            guard let rawPointer = element.children.data[i] else { continue }
            let childPointer = rawPointer.assumingMemoryBound(to: GumboNode.self)
            let child = childPointer.pointee
            if child.type == GUMBO_NODE_ELEMENT && child.v.element.tag == GUMBO_TAG_BODY {
                return convertChildren(child.v.element.children)
            }
        }
        // Fallback: convert root children directly
        return convertChildren(element.children)
    }

    private static func convertChildren(_ vector: GumboVector) -> [HTMLNode] {
        var nodes: [HTMLNode] = []
        for i in 0..<Int(vector.length) {
            guard let rawPointer = vector.data[i] else { continue }
            let nodePointer = rawPointer.assumingMemoryBound(to: GumboNode.self)
            if let node = convertNode(nodePointer) {
                nodes.append(node)
            }
        }
        return nodes
    }

    private static func convertNode(_ nodePointer: UnsafePointer<GumboNode>) -> HTMLNode? {
        let node = nodePointer.pointee
        switch node.type {
        case GUMBO_NODE_DOCUMENT:
            // Recurse into document children, flattening them
            return nil

        case GUMBO_NODE_ELEMENT:
            return convertElement(node)

        case GUMBO_NODE_TEXT, GUMBO_NODE_WHITESPACE:
            let text = String(cString: node.v.text.text)
            return .text(text)

        case GUMBO_NODE_COMMENT:
            let text = String(cString: node.v.text.text)
            return .comment(text)

        case GUMBO_NODE_CDATA, GUMBO_NODE_TEMPLATE:
            return nil

        default:
            return nil
        }
    }

    private static func convertElement(_ node: GumboNode) -> HTMLNode? {
        let element = node.v.element
        let tagName = resolveTagName(element)

        if tagName == "script" || tagName == "style" {
            return nil
        }

        let attributes = convertAttributes(element.attributes)
        let children = convertChildren(element.children)
        return .element(HTMLElement(tagName: tagName, attributes: attributes, children: children))
    }

    private static func resolveTagName(_ element: GumboElement) -> String {
        if element.tag == GUMBO_TAG_UNKNOWN {
            var originalTag = element.original_tag
            gumbo_tag_from_original_text(&originalTag)
            if originalTag.data != nil && originalTag.length > 0 {
                let name = originalTag.data.withMemoryRebound(
                    to: UInt8.self, capacity: originalTag.length
                ) { pointer in
                    String(decoding: UnsafeBufferPointer(start: pointer, count: originalTag.length), as: UTF8.self)
                }
                return name.lowercased()
            }
            return ""
        }
        return String(cString: gumbo_normalized_tagname(element.tag))
    }

    private static func convertAttributes(_ vector: GumboVector) -> [String: String] {
        var attributes: [String: String] = [:]
        for i in 0..<Int(vector.length) {
            guard let rawPointer = vector.data[i] else { continue }
            let attr = rawPointer.assumingMemoryBound(to: GumboAttribute.self).pointee
            let name = String(cString: attr.name)
            let value: String
            if attr.value != nil {
                let v = String(cString: attr.value)
                value = v.isEmpty ? name : v
            } else {
                value = name
            }
            attributes[name] = value
        }
        return attributes
    }
}
