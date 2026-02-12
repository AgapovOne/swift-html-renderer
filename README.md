# SwiftHTMLRenderer

HTML5 parser for Swift. Turns HTML strings into a typed, immutable AST.

Built for rendering rich-text content from APIs, CMS, and documentation — not for rendering full web pages.

## What it does

Parses any HTML5 string (valid or broken) into a tree of Swift structs. The AST is `Equatable`, `Hashable`, `Sendable`, and safe to use from any thread.

```swift
import HTMLParser

let doc = HTMLParser.parseFragment("<p>Hello, <b>world</b>!</p>")
// doc.children == [.element(HTMLElement(tagName: "p", children: [
//     .text("Hello, "),
//     .element(HTMLElement(tagName: "b", children: [.text("world")])),
//     .text("!")
// ]))]
```

Full documents work too:

```swift
let doc = HTMLParser.parse("<html><body><h1>Title</h1></body></html>")
```

## Install

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/nicklama/swift-html-renderer", from: "0.1.0")
]
```

Then add `HTMLParser` to your target dependencies:

```swift
.target(name: "YourApp", dependencies: ["HTMLParser"])
```

Requires iOS 17+ / macOS 14+. Swift 6.2.

## API

Two methods:

```swift
// Full document — preserves <html>, <head>, <body> structure
HTMLParser.parse(_ html: String) -> HTMLDocument

// Fragment — no wrapper elements, just the content
HTMLParser.parseFragment(_ html: String) -> HTMLDocument
```

### AST types

```swift
struct HTMLDocument    // children: [HTMLNode]
enum HTMLNode         // .element(HTMLElement) | .text(String) | .comment(String)
struct HTMLElement    // tagName, attributes: [String: String], children: [HTMLNode]
```

All types are `Equatable`, `Hashable`, `Sendable`. You can also build AST manually:

```swift
let node = HTMLElement(tagName: "p", attributes: ["class": "intro"], children: [
    .text("Hello")
])
```

## Benchmarks

```bash
swift run HTMLParserBenchmarks -c release
```

Compares parse time against `NSAttributedString(html:)` on small, medium, and large HTML documents. Results are printed to console and saved to `docs/BENCHMARK_RESULTS.md`.

## How it works

Uses [Gumbo](https://codeberg.org/gumbo-parser/gumbo-parser) (Google's HTML5 parser, WHATWG spec-compliant) under the hood. Gumbo is vendored as C source — no external dependencies for you.

The parser handles all the hard parts: error recovery, implicit tags, HTML entities, void elements, whitespace normalization.

`<script>` and `<style>` elements are stripped from the AST.

## License

MIT
