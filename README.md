# SwiftHTMLRenderer

HTML5 parser and SwiftUI renderer for Swift. Turns HTML strings into native SwiftUI views.

Built for rich-text content from APIs, CMS, and documentation — not for rendering full web pages.

## What it does

Two independent modules:

- **HTMLParser** — parses any HTML5 string (valid or broken) into a typed, immutable AST. `Equatable`, `Hashable`, `Sendable`. Thread-safe.
- **HTMLRenderer** — renders the AST into native SwiftUI views with three levels of customization.

Use them together or separately. Parser works without Renderer. Renderer accepts manually built AST.

## Install

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/nicklama/swift-html-renderer", from: "1.0.0")
]
```

Add modules to your target:

```swift
.target(name: "YourApp", dependencies: ["HTMLParser", "HTMLRenderer"])
```

Or just the parser:

```swift
.target(name: "YourApp", dependencies: ["HTMLParser"])
```

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.2
- SPM only

## Quick Start

```swift
import HTMLRenderer

struct ContentView: View {
    let html = "<h1>Hello</h1><p>This is <b>bold</b> and <i>italic</i> text.</p>"

    var body: some View {
        ScrollView {
            HTMLView(html: html)
                .padding()
        }
    }
}
```

That's it. `HTMLView` parses the HTML and renders it with default styles.

## Customization

Three levels, from simple to full control.

### 1. Style Configuration

Adjust fonts, colors, and spacing without custom views:

```swift
var config = HTMLStyleConfiguration()
config.heading1.font = .system(.largeTitle, weight: .black)
config.heading1.foregroundColor = .indigo
config.paragraph.lineSpacing = 6
config.blockquote.foregroundColor = .orange
config.preformatted.backgroundColor = Color(.systemGray6)

HTMLView(html: myHTML, configuration: config)
```

### 2. ViewBuilder Closures

Replace the rendering of any element with a custom SwiftUI view:

```swift
HTMLView(html: myHTML) {
    HTMLHeadingRenderer { children, level, attributes in
        Text("Heading \(level)")
            .font(.title)
            .foregroundStyle(.purple)
    }

    HTMLLinkRenderer { children, href, attributes in
        if let href {
            Link(href, destination: URL(string: href)!)
        }
    }
}
```

Available renderers: `HTMLHeadingRenderer`, `HTMLParagraphRenderer`, `HTMLLinkRenderer`, `HTMLListRenderer`, `HTMLListItemRenderer`, `HTMLBlockquoteRenderer`, `HTMLCodeBlockRenderer`, `HTMLImageRenderer`, `HTMLTableRenderer`.

Priority: ViewBuilder > StyleConfig > Default.

### 3. Visitor Protocol

General-purpose AST traversal. Not tied to rendering — use for analytics, transformation, export:

```swift
struct LinkCollector: HTMLVisitor {
    func visitLink(_ element: HTMLElement, href: String?) -> [String] {
        if let href { return [href] }
        return []
    }

    func visitElement(_ element: HTMLElement) -> [String] {
        element.children.flatMap { $0.accept(visitor: self) }
    }

    func visitText(_ text: String) -> [String] { [] }
    func visitComment(_ text: String) -> [String] { [] }
    func visitHorizontalRule() -> [String] { [] }
}

let links = doc.accept(visitor: LinkCollector()).flatMap { $0 }
```

## Supported Elements

| Category | Elements |
|----------|----------|
| Headings | `h1` `h2` `h3` `h4` `h5` `h6` |
| Text | `p` `span` `b` `strong` `i` `em` `u` `s` `del` `sub` `sup` `br` |
| Code | `code` `pre` |
| Links | `a` |
| Images | `img` |
| Lists | `ul` `ol` `li` |
| Tables | `table` `thead` `tbody` `tfoot` `tr` `th` `td` |
| Containers | `div` `article` `section` `main` `header` `footer` `nav` `aside` |
| Semantic | `figure` `figcaption` `blockquote` `hr` |

Unknown tags are skipped, but their children are rendered. Use `onUnknownElement` to handle them:

```swift
HTMLView(html: myHTML, onUnknownElement: { element in
    AnyView(Text(element.tagName).foregroundStyle(.gray))
})
```

## Image Support

### Default rendering

`<img>` renders via `AsyncImage` out of the box:

- Loading state: `ProgressView`
- Error state: system icon
- `alt` attribute → `accessibilityLabel`
- `width`/`height` attributes → `.frame()`
- No dimensions → `.scaledToFit()`
- Empty or missing `src` → `EmptyView`

Style images via configuration:

```swift
var config = HTMLStyleConfiguration()
config.image.cornerRadius = 12
config.image.maxHeight = 300
config.image.contentMode = .fill
config.image.placeholderColor = .gray

HTMLView(html: myHTML, configuration: config)
```

### Custom image loader

Plug in Kingfisher, SDWebImage, or any other loader:

```swift
HTMLView(html: myHTML) {
    HTMLImageRenderer { src, alt, attributes in
        if let src, let url = URL(string: src) {
            KFImage(url)
                .resizable()
                .scaledToFit()
        }
    }
}
```

## Links

Without a handler, links render as styled text (underlined, colored) but aren't tappable.

Add `onLinkTap` to handle taps:

```swift
HTMLView(html: myHTML, onLinkTap: { url in
    UIApplication.shared.open(url)
})
```

## Parser Only

Use `HTMLParser` independently to work with the AST:

```swift
import HTMLParser

// Fragment — just the content
let doc = HTMLParser.parseFragment("<p>Hello, <b>world</b>!</p>")

// Full document — preserves <html>, <head>, <body>
let fullDoc = HTMLParser.parse("<html><body><h1>Title</h1></body></html>")
```

AST types:

```swift
struct HTMLDocument    // children: [HTMLNode]
enum HTMLNode         // .element(HTMLElement) | .text(String) | .comment(String)
struct HTMLElement    // tagName, attributes: [String: String], children: [HTMLNode]
```

All types are `Equatable`, `Hashable`, `Sendable`. Build AST manually:

```swift
let node = HTMLElement(tagName: "p", attributes: ["class": "intro"], children: [
    .text("Hello")
])
```

## Accessibility

Built-in VoiceOver support:

- `h1`–`h6` → `.isHeader` trait
- `<a>` with `onLinkTap` → `.isLink` trait
- `<img>` with `alt` → `accessibilityLabel`
- `<img>` without `alt` → hidden from VoiceOver

## How it works

Uses [Lexbor](https://github.com/nicklama/lexbor) (HTML5 spec-compliant parser) under the hood. Vendored as C source — no external dependencies.

Lexbor handles error recovery, HTML entities, void elements, implicit tags, and whitespace normalization. `<script>` and `<style>` elements are stripped from the AST.

## License

MIT
