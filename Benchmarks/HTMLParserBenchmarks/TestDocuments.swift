import Foundation

enum TestDocuments {
    /// Small document (<1 KB): product card with basic formatting
    static let small = """
    <div class="product-card">
        <h3>MacBook Pro 14"</h3>
        <p class="price"><b>$1,999</b> <s>$2,499</s></p>
        <p>Apple M3 Pro chip, 18GB RAM, 512GB SSD.</p>
        <ul>
            <li>Up to 17 hours battery life</li>
            <li>Liquid Retina XDR display</li>
            <li>Three Thunderbolt 4 ports</li>
        </ul>
        <a href="/buy/macbook-pro" class="btn">Buy Now</a>
    </div>
    """

    /// Medium document (1-10 KB): blog article with headings, lists, links, formatting
    static let medium: String = {
        var html = """
        <article>
            <h1>Getting Started with Swift Concurrency</h1>
            <p class="meta">Published on <time datetime="2025-03-15">March 15, 2025</time> by <a href="/authors/jane">Jane Smith</a></p>

            <p>Swift concurrency transforms how we write asynchronous code. Instead of nested callbacks
            and completion handlers, we now use <code>async</code>/<code>await</code> syntax that reads
            like synchronous code.</p>

            <h2>Why Concurrency Matters</h2>
            <p>Modern apps handle <em>multiple tasks simultaneously</em>: network requests, database queries,
            file I/O, and user interactions. Without structured concurrency, managing these tasks leads to
            <strong>callback hell</strong> and race conditions.</p>

            <blockquote>
                <p>"Structured concurrency ensures that child tasks complete before their parent scope exits,
                preventing resource leaks and dangling tasks."</p>
            </blockquote>

            <h2>Key Concepts</h2>
            <ol>
                <li><strong>async/await</strong> &mdash; Mark functions as async and call them with await</li>
                <li><strong>Task</strong> &mdash; Create a unit of asynchronous work</li>
                <li><strong>Actor</strong> &mdash; Protect mutable state from data races</li>
                <li><strong>Sendable</strong> &mdash; Types safe to pass across concurrency domains</li>
                <li><strong>AsyncSequence</strong> &mdash; Iterate over values delivered asynchronously</li>
            </ol>

            <h3>Using async/await</h3>
            <p>The simplest way to start is converting a completion-handler API:</p>
            <pre><code>func fetchUser(id: Int) async throws -&gt; User {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(User.self, from: data)
        }</code></pre>

            <h3>Working with Actors</h3>
            <p>Actors serialize access to their mutable state:</p>
            <pre><code>actor ImageCache {
            private var cache: [URL: Image] = [:]

            func image(for url: URL) -&gt; Image? {
                cache[url]
            }

            func store(_ image: Image, for url: URL) {
                cache[url] = image
            }
        }</code></pre>

            <h2>Common Patterns</h2>
            <table>
                <thead>
                    <tr>
                        <th>Pattern</th>
                        <th>Use Case</th>
                        <th>API</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Sequential</td>
                        <td>Tasks depend on each other</td>
                        <td><code>await a(); await b()</code></td>
                    </tr>
                    <tr>
                        <td>Concurrent</td>
                        <td>Independent tasks</td>
                        <td><code>async let</code></td>
                    </tr>
                    <tr>
                        <td>Group</td>
                        <td>Dynamic number of tasks</td>
                        <td><code>withTaskGroup</code></td>
                    </tr>
                    <tr>
                        <td>Streaming</td>
                        <td>Continuous data flow</td>
                        <td><code>AsyncStream</code></td>
                    </tr>
                </tbody>
            </table>

            <h2>Error Handling</h2>
            <p>Async functions integrate with Swift's <code>throw</code>/<code>try</code>:</p>
            <ul>
                <li>Use <code>try await</code> for throwing async functions</li>
                <li>Task cancellation is cooperative &mdash; check <code>Task.isCancelled</code></li>
                <li><code>withTaskCancellationHandler</code> for cleanup</li>
            </ul>

            <h2>Summary</h2>
            <p>Swift concurrency provides <strong>safe</strong>, <strong>readable</strong>, and
            <strong>efficient</strong> tools for asynchronous programming. Start with
            <code>async</code>/<code>await</code>, then adopt actors and task groups as your needs grow.</p>

            <p>Further reading:</p>
            <ul>
                <li><a href="https://docs.swift.org/concurrency">Official Swift Concurrency Guide</a></li>
                <li><a href="https://developer.apple.com/wwdc">WWDC Sessions on Concurrency</a></li>
                <li><a href="https://github.com/apple/swift-evolution">Swift Evolution Proposals</a></li>
            </ul>
        </article>
        """
        return html
    }()

    /// Large document (50+ KB): long technical documentation with tables, lists, mixed content
    static let large: String = {
        var sections: [String] = []

        // Generate 20 sections of varied content to reach 50+ KB
        let sectionTopics = [
            ("Installation", "Setting up the framework in your project"),
            ("Configuration", "Configuring the framework for your environment"),
            ("Authentication", "Managing user authentication and sessions"),
            ("Data Models", "Defining and working with data models"),
            ("Networking", "Making network requests and handling responses"),
            ("Caching", "Implementing efficient data caching strategies"),
            ("Error Handling", "Handling errors and edge cases gracefully"),
            ("Testing", "Writing unit and integration tests"),
            ("Performance", "Optimizing for speed and memory usage"),
            ("Accessibility", "Making your app accessible to all users"),
            ("Localization", "Supporting multiple languages and regions"),
            ("Security", "Securing user data and communications"),
            ("Analytics", "Tracking user behavior and app metrics"),
            ("Push Notifications", "Implementing push notification support"),
            ("Background Tasks", "Running tasks in the background"),
            ("File Management", "Working with the file system"),
            ("Database", "Local database operations and migrations"),
            ("UI Components", "Building reusable UI components"),
            ("Navigation", "Implementing app navigation patterns"),
            ("Deployment", "Preparing and deploying your application"),
        ]

        for (i, (title, subtitle)) in sectionTopics.enumerated() {
            let sectionNum = i + 1
            var section = """
            <section id="section-\(sectionNum)">
                <h2>\(sectionNum). \(title)</h2>
                <p class="subtitle"><em>\(subtitle)</em></p>

                <p>This section covers the essential aspects of \(title.lowercased()) in your application.
                Understanding these concepts helps you build robust, maintainable software that scales
                with your user base and feature requirements.</p>

                <h3>\(sectionNum).1 Overview</h3>
                <p>The \(title.lowercased()) module provides a comprehensive set of tools and APIs
                for managing \(subtitle.lowercased()). It integrates with the core framework
                and follows established patterns for consistency.</p>

                <div class="info-box">
                    <p><strong>Note:</strong> Before proceeding, ensure you have completed the
                    <a href="#section-1">Installation</a> steps and have a working development environment.</p>
                </div>

                <h3>\(sectionNum).2 Getting Started</h3>
                <p>To begin using the \(title.lowercased()) features:</p>
                <ol>
                    <li>Import the required module: <code>import Framework\(title.replacingOccurrences(of: " ", with: ""))</code></li>
                    <li>Initialize the configuration object with your project settings</li>
                    <li>Register any required delegates or observers</li>
                    <li>Call the <code>setup()</code> method before using any APIs</li>
                    <li>Verify initialization succeeded by checking the <code>isReady</code> property</li>
                </ol>

                <pre><code>import Framework\(title.replacingOccurrences(of: " ", with: ""))

            let config = \(title.replacingOccurrences(of: " ", with: ""))Config(
                apiKey: "your-api-key",
                environment: .production,
                logLevel: .warning
            )

            try await \(title.replacingOccurrences(of: " ", with: ""))Manager.shared.configure(with: config)
            assert(\(title.replacingOccurrences(of: " ", with: ""))Manager.shared.isReady)</code></pre>

                <h3>\(sectionNum).3 API Reference</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Method</th>
                            <th>Parameters</th>
                            <th>Return Type</th>
                            <th>Description</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><code>configure(with:)</code></td>
                            <td><code>Config</code></td>
                            <td><code>Void</code></td>
                            <td>Initialize with configuration</td>
                        </tr>
                        <tr>
                            <td><code>reset()</code></td>
                            <td>None</td>
                            <td><code>Void</code></td>
                            <td>Reset to default state</td>
                        </tr>
                        <tr>
                            <td><code>status()</code></td>
                            <td>None</td>
                            <td><code>Status</code></td>
                            <td>Get current status</td>
                        </tr>
                        <tr>
                            <td><code>validate()</code></td>
                            <td>None</td>
                            <td><code>Bool</code></td>
                            <td>Validate current configuration</td>
                        </tr>
                        <tr>
                            <td><code>export(format:)</code></td>
                            <td><code>ExportFormat</code></td>
                            <td><code>Data</code></td>
                            <td>Export data in specified format</td>
                        </tr>
                    </tbody>
                </table>

                <h3>\(sectionNum).4 Best Practices</h3>
                <ul>
                    <li>Always initialize the module <strong>before</strong> accessing any APIs</li>
                    <li>Use <code>async/await</code> for all asynchronous operations</li>
                    <li>Handle errors with <code>do/catch</code> blocks and provide user feedback</li>
                    <li>Cache results when appropriate to reduce network calls</li>
                    <li>Follow the <a href="#section-12">Security</a> guidelines for sensitive data</li>
                    <li>Write tests for all critical paths (see <a href="#section-8">Testing</a>)</li>
                </ul>

                <h3>\(sectionNum).5 Troubleshooting</h3>
                <dl>
                    <dt><strong>Error: Module not initialized</strong></dt>
                    <dd>Call <code>configure(with:)</code> before using any APIs. Check that your API key is valid.</dd>
                    <dt><strong>Error: Network timeout</strong></dt>
                    <dd>Verify your internet connection. Increase timeout in <code>Config.networkTimeout</code>.</dd>
                    <dt><strong>Error: Invalid configuration</strong></dt>
                    <dd>Ensure all required fields are set. Call <code>validate()</code> to check.</dd>
                </dl>
            </section>

            """
            sections.append(section)
        }

        return """
        <html>
        <head><title>Framework Documentation v2.0</title></head>
        <body>
            <header>
                <h1>Framework Documentation</h1>
                <p>Version 2.0 &mdash; Last updated: March 2025</p>
                <nav>
                    <ul>
                        \(sectionTopics.enumerated().map { "<li><a href=\"#section-\($0.offset + 1)\">\($0.element.0)</a></li>" }.joined(separator: "\n                        "))
                    </ul>
                </nav>
            </header>
            <main>
                \(sections.joined())
            </main>
            <footer>
                <p>&copy; 2025 Framework Team. All rights reserved.</p>
                <p>Licensed under <a href="/license">MIT License</a>.</p>
            </footer>
        </body>
        </html>
        """
    }()
}
