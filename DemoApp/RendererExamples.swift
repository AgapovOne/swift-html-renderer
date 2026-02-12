import HTMLParser
import HTMLRenderer
import SwiftUI

// MARK: - RendererExample

enum RendererExample: String, CaseIterable, Identifiable {
    case styleConfig
    case customRenderers
    case darkStyle
    case onLinkTap
    case onUnknownElement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .styleConfig: "Style Config"
        case .customRenderers: "Custom Renderers"
        case .darkStyle: "Dark Style"
        case .onLinkTap: "Link Tap Handler"
        case .onUnknownElement: "Unknown Elements"
        }
    }

    var html: String {
        switch self {
        case .styleConfig: RendererHTML.styleConfig
        case .customRenderers: RendererHTML.customRenderers
        case .darkStyle: RendererHTML.darkStyle
        case .onLinkTap: RendererHTML.onLinkTap
        case .onUnknownElement: RendererHTML.onUnknownElement
        }
    }

    @MainActor @ViewBuilder
    var renderedView: some View {
        switch self {
        case .styleConfig: Self.styleConfigView()
        case .customRenderers: Self.customRenderersView()
        case .darkStyle: Self.darkStyleView()
        case .onLinkTap: Self.onLinkTapView()
        case .onUnknownElement: Self.onUnknownElementView()
        }
    }
}

// MARK: - Style Config Example

extension RendererExample {
    @MainActor @ViewBuilder
    static func styleConfigView() -> some View {
        let config = HTMLStyleConfiguration(
            heading1: HTMLElementStyle(
                font: .system(.largeTitle, design: .serif),
                foregroundColor: .indigo
            ),
            heading2: HTMLElementStyle(
                font: .system(.title, design: .serif),
                foregroundColor: .indigo.opacity(0.8)
            ),
            paragraph: HTMLElementStyle(
                font: .system(.body, design: .serif),
                lineSpacing: 4
            ),
            code: HTMLElementStyle(
                font: .system(.body, design: .monospaced),
                foregroundColor: .orange,
                backgroundColor: .orange.opacity(0.1),
                padding: EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            ),
            preformatted: HTMLElementStyle(
                font: .system(.callout, design: .monospaced),
                foregroundColor: .mint,
                backgroundColor: .black.opacity(0.8),
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            ),
            blockquote: HTMLElementStyle(
                foregroundColor: .purple,
                padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
            ),
            link: HTMLElementStyle(foregroundColor: .orange)
        )

        HTMLView(
            html: RendererHTML.styleConfig,
            configuration: config,
            onLinkTap: { url in print("Link: \(url)") }
        )
    }
}

// MARK: - Custom Renderers Example

extension RendererExample {
    @MainActor @ViewBuilder
    static func customRenderersView() -> some View {
        HTMLView(
            html: RendererHTML.customRenderers,
            onLinkTap: { url in print("Link: \(url)") }
        ) {
            HTMLHeadingRenderer { children, level, _ in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue.gradient)
                        .frame(width: 4)
                    VStack(alignment: .leading) {
                        Text("H\(level)")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .textCase(.uppercase)
                        ForEach(Array(children.enumerated()), id: \.offset) { _, node in
                            NodeView(node: node)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            HTMLBlockquoteRenderer { children, _ in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(children.enumerated()), id: \.offset) { _, node in
                            NodeView(node: node)
                        }
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

            HTMLCodeBlockRenderer { children, _ in
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

                    ForEach(Array(children.enumerated()), id: \.offset) { _, node in
                        NodeView(node: node)
                    }
                }
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.green)
                .padding(12)
                .background(.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HTMLLinkRenderer { children, href, _ in
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                    ForEach(Array(children.enumerated()), id: \.offset) { _, node in
                        NodeView(node: node)
                    }
                }
                .foregroundStyle(.blue)
                .underline()
            }
        }
    }
}

// MARK: - Dark Style Example

extension RendererExample {
    @MainActor @ViewBuilder
    static func darkStyleView() -> some View {
        let config = HTMLStyleConfiguration(
            heading1: HTMLElementStyle(
                font: .system(.largeTitle, design: .rounded, weight: .bold),
                foregroundColor: .white
            ),
            heading2: HTMLElementStyle(
                font: .system(.title, design: .rounded, weight: .semibold),
                foregroundColor: .white.opacity(0.9)
            ),
            paragraph: HTMLElementStyle(
                font: .system(.body),
                foregroundColor: .white.opacity(0.85),
                lineSpacing: 3
            ),
            bold: HTMLElementStyle(foregroundColor: .white),
            italic: HTMLElementStyle(foregroundColor: .white.opacity(0.9)),
            code: HTMLElementStyle(
                font: .system(.body, design: .monospaced),
                foregroundColor: .cyan,
                backgroundColor: .white.opacity(0.1),
                padding: EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            ),
            preformatted: HTMLElementStyle(
                font: .system(.callout, design: .monospaced),
                foregroundColor: .cyan.opacity(0.9),
                backgroundColor: .black.opacity(0.4),
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            ),
            blockquote: HTMLElementStyle(
                foregroundColor: .white.opacity(0.7),
                padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
            ),
            link: HTMLElementStyle(foregroundColor: .cyan),
            listItem: HTMLElementStyle(foregroundColor: .white.opacity(0.85)),
            tableHeader: HTMLElementStyle(foregroundColor: .white),
            tableCell: HTMLElementStyle(foregroundColor: .white.opacity(0.85))
        )

        HTMLView(
            html: RendererHTML.darkStyle,
            configuration: config,
            onLinkTap: { url in print("Link: \(url)") }
        )
        .padding(20)
        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

                HTMLView(html: RendererHTML.onLinkTap, onLinkTap: { [self] url in
                    MainActor.assumeIsolated {
                        tappedURL = "Tapped: \(url.absoluteString)"
                    }
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
        HTMLView(
            html: RendererHTML.onUnknownElement,
            onUnknownElement: { element in
                AnyView(
                    VStack(alignment: .leading, spacing: 4) {
                        Label(
                            "Unknown: <\(element.tagName)>",
                            systemImage: "questionmark.diamond"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)

                        ForEach(Array(element.children.enumerated()), id: \.offset) { _, child in
                            NodeView(node: child)
                        }
                    }
                    .padding(8)
                    .background(.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                )
            }
        )
    }
}

// MARK: - NodeView helper

struct NodeView: View {
    let node: HTMLNode

    var body: some View {
        switch node {
        case .text(let text):
            Text(text)
        case .element(let el):
            ForEach(Array(el.children.enumerated()), id: \.offset) { _, child in
                NodeView(node: child)
            }
        case .comment:
            EmptyView()
        }
    }
}

// MARK: - HTML for Renderer Examples

private enum RendererHTML {

    static let styleConfig = """
    <h1>Serif Typography</h1>
    <h2>Style Configuration</h2>
    <p>This example uses a custom <code>HTMLStyleConfiguration</code> with serif fonts, \
    indigo headings, and orange accents for code and links.</p>
    <blockquote><p>Style configs change fonts, colors, padding, and spacing — \
    without custom view builders.</p></blockquote>
    <pre><code>let config = HTMLStyleConfiguration(
        heading1: HTMLElementStyle(font: .serif, foregroundColor: .indigo)
    )</code></pre>
    <p>Visit <a href="https://example.com">the docs</a> for details.</p>
    """

    static let customRenderers = """
    <h1>Custom Renderers</h1>
    <h2>ViewBuilder Closures</h2>
    <p>Each element type can have a custom renderer via <code>@HTMLContentBuilder</code>.</p>
    <p>This example overrides headings, blockquotes, code blocks, and links.</p>
    <blockquote><p>Blockquotes get a yellow card-style background.</p></blockquote>
    <pre><code>HTMLView(html: content) {
        HTMLHeadingRenderer { children, level, _ in
            // custom heading view
        }
    }</code></pre>
    <p>Check <a href="https://example.com">the API reference</a> for all renderer types.</p>
    """

    static let darkStyle = """
    <h1>Dark Theme</h1>
    <h2>Style Configuration Only</h2>
    <p>No custom renderers needed. Just a <code>HTMLStyleConfiguration</code> with \
    light text on a dark background.</p>
    <ul>
        <li>White headings with rounded font</li>
        <li>Cyan code and links</li>
        <li>Muted body text</li>
    </ul>
    <blockquote><p>Works with the default renderer — only colors and fonts change.</p></blockquote>
    <pre><code>HTMLView(html: content, configuration: darkConfig)</code></pre>
    <p>Combine with <a href="https://example.com">custom renderers</a> for full control.</p>
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
    <p>But custom or non-standard elements trigger <code>onUnknownElement</code>:</p>
    <callout>This is inside a custom callout tag.</callout>
    <warning>This is a warning element with <b>bold</b> text.</warning>
    <note>A note element — the callback renders them with an indicator.</note>
    <p>Without the callback, unknown tags are invisible — only children render.</p>
    """
}
