import CGumbo

public enum HTMLParser {
    public static func parse(_ html: String) -> HTMLDocument {
        guard !html.isEmpty else {
            return HTMLDocument()
        }
        var options = kGumboDefaultOptions
        let output = gumbo_parse(html)!
        defer { gumbo_destroy_output(&options, output) }
        return GumboConverter.convert(output)
    }

    public static func parseFragment(_ html: String) -> HTMLDocument {
        guard !html.isEmpty else {
            return HTMLDocument()
        }
        var options = kGumboDefaultOptions
        options.fragment_context = GUMBO_TAG_BODY
        options.fragment_namespace = GUMBO_NAMESPACE_HTML
        let output = html.withCString { buffer in
            gumbo_parse_with_options(&options, buffer, html.utf8.count)!
        }
        defer { gumbo_destroy_output(&options, output) }
        return GumboConverter.convertFragment(output)
    }
}
