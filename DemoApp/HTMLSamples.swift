enum Sample: String, CaseIterable, Identifiable {
    case headings
    case textFormatting
    case paragraphs
    case lists
    case nestedLists
    case tables
    case links
    case blockquotes
    case codeBlocks
    case voidElements
    case entities
    case malformedHTML
    case complexArticle
    case images
    case deepNesting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .headings: "Headings"
        case .textFormatting: "Text Formatting"
        case .paragraphs: "Paragraphs"
        case .lists: "Lists"
        case .nestedLists: "Nested Lists"
        case .tables: "Tables"
        case .links: "Links"
        case .blockquotes: "Blockquotes"
        case .codeBlocks: "Code Blocks"
        case .voidElements: "Void Elements"
        case .entities: "HTML Entities"
        case .malformedHTML: "Malformed HTML"
        case .complexArticle: "Complex Article"
        case .images: "Images"
        case .deepNesting: "Deep Nesting"
        }
    }

    var html: String {
        switch self {
        case .headings: HTML.headings
        case .textFormatting: HTML.textFormatting
        case .paragraphs: HTML.paragraphs
        case .lists: HTML.lists
        case .nestedLists: HTML.nestedLists
        case .tables: HTML.tables
        case .links: HTML.links
        case .blockquotes: HTML.blockquotes
        case .codeBlocks: HTML.codeBlocks
        case .voidElements: HTML.voidElements
        case .entities: HTML.entities
        case .malformedHTML: HTML.malformedHTML
        case .complexArticle: HTML.complexArticle
        case .images: HTML.images
        case .deepNesting: HTML.deepNesting
        }
    }
}

// MARK: - HTML Content

private enum HTML {

    static let headings = """
    <h1>Heading Level 1</h1>
    <h2>Heading Level 2</h2>
    <h3>Heading Level 3</h3>
    <h4>Heading Level 4</h4>
    <h5>Heading Level 5</h5>
    <h6>Heading Level 6</h6>
    """

    static let textFormatting = """
    <p><b>Bold text</b> and <strong>strong text</strong></p>
    <p><i>Italic text</i> and <em>emphasized text</em></p>
    <p><u>Underlined text</u></p>
    <p><s>Strikethrough</s> and <del>deleted text</del></p>
    <p><code>Inline code</code></p>
    <p>Text with <sub>subscript</sub> and <sup>superscript</sup></p>
    <p><b><i>Bold and italic</i></b></p>
    <p><b><u><i>Bold, underline, and italic</i></u></b></p>
    <p>Normal text with <b>bold <i>and italic <u>and underline</u></i></b> mixed in</p>
    """

    static let paragraphs = """
    <p>First paragraph with some text. This is a complete sentence.</p>
    <p>Second paragraph. It has <b>bold</b> and <i>italic</i> words.</p>
    <p>Third paragraph with a <a href="https://example.com">link</a> inside it.</p>
    <p>A longer paragraph to test wrapping behavior. Lorem ipsum dolor sit amet, \
    consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
    """

    static let lists = """
    <h3>Unordered List</h3>
    <ul>
        <li>First item</li>
        <li>Second item</li>
        <li>Third item with <b>bold</b></li>
    </ul>
    <h3>Ordered List</h3>
    <ol>
        <li>Step one</li>
        <li>Step two</li>
        <li>Step three</li>
    </ol>
    """

    static let nestedLists = """
    <ul>
        <li>Frontend
            <ul>
                <li>HTML</li>
                <li>CSS</li>
                <li>JavaScript
                    <ul>
                        <li>React</li>
                        <li>Vue</li>
                    </ul>
                </li>
            </ul>
        </li>
        <li>Backend
            <ul>
                <li>Swift</li>
                <li>Python</li>
            </ul>
        </li>
    </ul>
    """

    static let tables = """
    <h3>Simple Table</h3>
    <table>
        <thead>
            <tr>
                <th>Name</th>
                <th>Language</th>
                <th>Stars</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>SwiftUI</td>
                <td>Swift</td>
                <td>N/A</td>
            </tr>
            <tr>
                <td>React</td>
                <td>JavaScript</td>
                <td>220k</td>
            </tr>
            <tr>
                <td>Flutter</td>
                <td>Dart</td>
                <td>160k</td>
            </tr>
        </tbody>
    </table>
    """

    static let links = """
    <p><a href="https://apple.com">Apple</a></p>
    <p><a href="https://github.com">GitHub</a></p>
    <p>Visit <a href="https://swift.org">swift.org</a> for more info.</p>
    <p><a href="https://example.com"><b>Bold link</b></a></p>
    <p><a href="/relative">Relative URL</a></p>
    <p><a>Link without href</a></p>
    """

    static let blockquotes = """
    <blockquote>
        <p>Simple blockquote with one paragraph.</p>
    </blockquote>
    <blockquote>
        <p>First paragraph of a multi-paragraph quote.</p>
        <p>Second paragraph with <b>formatting</b>.</p>
    </blockquote>
    <blockquote>
        <p>Nested quote:</p>
        <blockquote>
            <p>This is the inner quote.</p>
        </blockquote>
    </blockquote>
    """

    static let codeBlocks = """
    <p>Inline: <code>let x = 42</code></p>
    <pre><code>func greet(name: String) -> String {
        return "Hello, \\(name)!"
    }</code></pre>
    <pre><code>struct ContentView: View {
        var body: some View {
            Text("Hello, world!")
                .padding()
        }
    }</code></pre>
    """

    static let voidElements = """
    <p>Line one<br>Line two<br>Line three</p>
    <hr>
    <p>Text after horizontal rule</p>
    <hr>
    <p>Another section</p>
    """

    static let entities = """
    <p>Ampersand: &amp;</p>
    <p>Less than: &lt; Greater than: &gt;</p>
    <p>Quote: &quot; Apostrophe: &apos;</p>
    <p>Non-breaking space: &nbsp;between&nbsp;words</p>
    <p>Numeric: &#60; &#62;</p>
    <p>Hex: &#x3C; &#x3E;</p>
    <p>Em dash: &mdash; En dash: &ndash;</p>
    <p>Copyright: &copy; Registered: &reg; Trademark: &trade;</p>
    """

    static let malformedHTML = """
    <p>Unclosed paragraph
    <p>Next paragraph (implicit close)</p>
    <b>Bold without close
    <p>After unclosed bold</p>
    <div><p>Div closes before p</div></p>
    <ul><li>Item without closing li<li>Next item</ul>
    <p>Mixed <b><i>nesting</b></i></p>
    <p>   Extra   whitespace   everywhere   </p>
    <p></p>
    <p>After empty paragraph</p>
    """

    static let complexArticle = """
    <article>
        <h1>Building a SwiftUI HTML Renderer</h1>
        <p>A guide to parsing and rendering HTML in SwiftUI apps.</p>

        <h2>Architecture</h2>
        <p>The library has two modules:</p>
        <ol>
            <li><b>HTMLParser</b> — parses HTML into an AST</li>
            <li><b>HTMLRenderer</b> — renders the AST as SwiftUI views</li>
        </ol>

        <h2>Supported Elements</h2>
        <table>
            <thead>
                <tr><th>Category</th><th>Elements</th></tr>
            </thead>
            <tbody>
                <tr><td>Headings</td><td>h1-h6</td></tr>
                <tr><td>Text</td><td>b, i, u, s, code</td></tr>
                <tr><td>Block</td><td>p, div, blockquote, pre</td></tr>
                <tr><td>Lists</td><td>ul, ol, li</td></tr>
            </tbody>
        </table>

        <h2>Example</h2>
        <pre><code>HTMLView(html: "&lt;p&gt;Hello&lt;/p&gt;")</code></pre>

        <blockquote>
            <p><b>Note:</b> This library is for rich-text content, not for rendering web pages.</p>
        </blockquote>

        <hr>
        <p>Learn more at <a href="https://github.com">GitHub</a>.</p>
    </article>
    """

    static let images = """
    <h2>Images</h2>

    <h3>Basic Image</h3>
    <img src="https://picsum.photos/600/300" alt="Random landscape photo">

    <h3>Image with Dimensions</h3>
    <img src="https://picsum.photos/200/200" alt="Small square photo" width="200" height="200">

    <h3>Figure with Caption</h3>
    <figure>
        <img src="https://picsum.photos/seed/demo/600/400" alt="Demo photo">
        <figcaption>A random photo from <b>Lorem Picsum</b></figcaption>
    </figure>

    <h3>Image in Article Context</h3>
    <p>Here is a paragraph before the image.</p>
    <img src="https://picsum.photos/seed/article/600/250" alt="Article header image">
    <p>And a paragraph after the image.</p>

    <h3>Missing Image</h3>
    <img src="https://invalid.example/broken.jpg" alt="This image will fail to load">

    <h3>No Source</h3>
    <img alt="Image with no src attribute">
    """

    static let deepNesting = """
    <div>
        <div>
            <div>
                <div>
                    <p><b><i><u>Four levels deep with formatting</u></i></b></p>
                </div>
            </div>
        </div>
    </div>
    <section>
        <article>
            <header>
                <h2>Nested Sections</h2>
            </header>
            <main>
                <p>Content in deeply nested semantic HTML.</p>
                <aside>
                    <p><i>Side note inside main inside article inside section.</i></p>
                </aside>
            </main>
            <footer>
                <p>Footer of the article.</p>
            </footer>
        </article>
    </section>
    """
}
