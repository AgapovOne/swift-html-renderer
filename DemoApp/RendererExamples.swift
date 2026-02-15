import HTMLParser
import HTMLRenderer
import SwiftUI

// MARK: - RendererExample

enum RendererExample: String, CaseIterable, Identifiable {
    case customRenderers
    case onLinkTap
    case onUnknownElement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .customRenderers: "Custom Renderers"
        case .onLinkTap: "Link Tap Handler"
        case .onUnknownElement: "Unknown Elements"
        }
    }

    var html: String {
        switch self {
        case .customRenderers: RendererHTML.customRenderers
        case .onLinkTap: RendererHTML.onLinkTap
        case .onUnknownElement: RendererHTML.onUnknownElement
        }
    }

    @MainActor @ViewBuilder
    var renderedView: some View {
        switch self {
        case .customRenderers: Self.customRenderersView()
        case .onLinkTap: Self.onLinkTapView()
        case .onUnknownElement: Self.onUnknownElementView()
        }
    }
}

// MARK: - Custom Renderers Example

extension RendererExample {
    @MainActor @ViewBuilder
    static func customRenderersView() -> some View {
        HTMLView(
            document: HTMLParser.parseFragment(RendererHTML.customRenderers),
            onLinkTap: { url, _ in print("Link: \(url)") }
        )
        .htmlHeading { children, level, _ in
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.blue.gradient)
                    .frame(width: 4)
                VStack(alignment: .leading) {
                    Text("H\(level)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                    HTMLNodeView(nodes: children)
                }
            }
            .padding(.vertical, 4)
        }
        .htmlBlockquote { children, _ in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HTMLNodeView(nodes: children)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.yellow.opacity(0.4), lineWidth: 1)
            )
        }
        .htmlCodeBlock { children, _ in
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                    Text("Code")
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.green.opacity(0.7))
                .padding(.bottom, 4)

                HTMLNodeView(nodes: children)
            }
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(.green)
            .padding(12)
            .background(.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .htmlLink(
            render: { children, href, _ in
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                    HTMLNodeView(nodes: children)
                }
                .foregroundStyle(.blue)
                .underline()
            },
            inlineText: { text, url, attrs in
                Text(Image(systemName: "link")).foregroundColor(.blue) + Text(" ") +
                text.foregroundColor(.blue).underline()
            }
        )
    }
}

// MARK: - Link Tap Handler Example

extension RendererExample {
    struct LinkTapDemoView: View {
        @State private var tappedURL: String = "Tap a link below"

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(tappedURL)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HTMLView(document: HTMLParser.parseFragment(RendererHTML.onLinkTap), onLinkTap: { [self] url, _  in
                    tappedURL = "Tapped: \(url.absoluteString)"
                })
            }
        }
    }

    @MainActor @ViewBuilder
    static func onLinkTapView() -> some View {
        LinkTapDemoView()
    }
}

// MARK: - Unknown Element Example

extension RendererExample {
    @MainActor @ViewBuilder
    static func onUnknownElementView() -> some View {
        HTMLView(document: HTMLParser.parseFragment(RendererHTML.onUnknownElement))
            .htmlUnknownElement { element in
                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        "Unknown: <\(element.tagName)>",
                        systemImage: "questionmark.diamond"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)

                    HTMLNodeView(nodes: element.children)
                }
                .padding(8)
                .background(.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
    }
}

// MARK: - HTML for Renderer Examples

private enum RendererHTML {

    static let customRenderers = """
    <h1>Custom Renderers</h1>
    <h2>View Modifiers</h2>
    <p>Each element type can have a custom renderer via view modifiers.</p>
    <p>This example overrides headings, blockquotes, code blocks, and links.</p>
    <blockquote><p>Blockquotes get a yellow card-style background.</p></blockquote>
    <pre><code>HTMLView(document: doc)
        .htmlHeading { children, level, _ in
            // custom heading view
        }</code></pre>
    <p>Check <a href="https://example.com">the API reference</a> for all modifier types.</p>
    """

    static let onLinkTap = """
    <h2>Link Tap Handler</h2>
    <p>Pass <code>onLinkTap</code> to make links interactive.</p>
    <p>Try these links:</p>
    <ul>
        <li><a href="https://apple.com">Apple</a></li>
        <li><a href="https://swift.org">Swift</a></li>
        <li><a href="https://github.com">GitHub</a></li>
    </ul>
    <p>Without <code>onLinkTap</code>, links render as styled but non-clickable text.</p>
    """

    static let onUnknownElement = """
    <h2>Unknown Element Handling</h2>
    <p>Standard elements render normally:</p>
    <ul>
        <li>Paragraphs, lists, headings — all work</li>
    </ul>
    <p>But custom or non-standard elements trigger <code>.htmlUnknownElement</code>:</p>
    <callout>This is inside a custom callout tag.</callout>
    <warning>This is a warning element with <b>bold</b> text.</warning>
    <note>A note element — the modifier renders them with an indicator.</note>
    <p>Without the modifier, unknown tags are invisible — only children render.</p>
    """
}
