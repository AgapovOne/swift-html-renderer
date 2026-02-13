import Foundation

enum BenchmarkDocuments {
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

    /// Medium document (1-10 KB): blog article
    static let medium: String = {
        var html = """
        <article>
            <h1>Getting Started with Swift Concurrency</h1>
            <p>Published on <time>March 15, 2025</time> by <a href="/authors/jane">Jane Smith</a></p>
            <p>Swift concurrency transforms how we write asynchronous code. Instead of nested callbacks
            and completion handlers, we now use <code>async</code>/<code>await</code> syntax.</p>
            <h2>Why Concurrency Matters</h2>
            <p>Modern apps need to handle multiple tasks simultaneously:</p>
            <ul>
                <li>Network requests to REST APIs</li>
                <li>Database queries and Core Data operations</li>
                <li>Image processing and transformations</li>
                <li>User interface updates on the main thread</li>
            </ul>
            <h2>Async/Await Basics</h2>
            <p>The <code>async</code> keyword marks a function that can suspend:</p>
            <pre><code>func fetchUser(id: Int) async throws -> User {
                let url = URL(string: "https://api.example.com/users/\\(id)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                return try JSONDecoder().decode(User.self, from: data)
            }</code></pre>
            <h2>Structured Concurrency</h2>
            <p>Swift provides <b>task groups</b> for parallel execution:</p>
            <pre><code>func fetchAllUsers(ids: [Int]) async throws -> [User] {
                try await withThrowingTaskGroup(of: User.self) { group in
                    for id in ids { group.addTask { try await fetchUser(id: id) } }
                    return try await group.reduce(into: []) { $0.append($1) }
                }
            }</code></pre>
            <h2>Actors</h2>
            <p>Actors protect mutable state from data races:</p>
            <pre><code>actor UserCache {
                private var cache: [Int: User] = [:]
                func user(for id: Int) -> User? { cache[id] }
                func store(_ user: User) { cache[user.id] = user }
            }</code></pre>
            <blockquote><p>Actors are reference types like classes, but with built-in synchronization.</p></blockquote>
            <h2>Summary</h2>
            <p>Swift concurrency brings:</p>
            <ol>
                <li><b>Readability</b> &mdash; async/await reads like synchronous code</li>
                <li><b>Safety</b> &mdash; the compiler prevents data races</li>
                <li><b>Performance</b> &mdash; lightweight tasks instead of heavy threads</li>
            </ol>
            <p>For more details, check the <a href="https://swift.org/concurrency">official documentation</a>.</p>
        </article>
        """
        // Duplicate to reach ~5 KB
        html += html
        return html
    }()

    /// Large document (50+ KB): generated content
    static let large: String = {
        var sections: [String] = []
        for i in 1...50 {
            sections.append("""
            <section>
                <h2>Section \(i): Performance Analysis</h2>
                <p>This section covers the <b>performance metrics</b> for component \(i).
                We measured <i>throughput</i>, <code>latency</code>, and memory usage.</p>
                <table>
                    <thead><tr><th>Metric</th><th>Value</th><th>Target</th><th>Status</th></tr></thead>
                    <tbody>
                        <tr><td>Throughput</td><td>\(1000 + i * 50) req/s</td><td>1000 req/s</td><td>Pass</td></tr>
                        <tr><td>P99 Latency</td><td>\(10 + i)ms</td><td>50ms</td><td>Pass</td></tr>
                        <tr><td>Memory</td><td>\(64 + i * 2)MB</td><td>256MB</td><td>Pass</td></tr>
                    </tbody>
                </table>
                <ul>
                    <li>Optimization \(i).1: Cache warming reduced cold start by <b>40%</b></li>
                    <li>Optimization \(i).2: Connection pooling improved throughput by <b>25%</b></li>
                    <li>Optimization \(i).3: Batch processing reduced latency by <b>15%</b></li>
                </ul>
                <blockquote><p>Component \(i) meets all performance targets for production deployment.</p></blockquote>
            </section>
            """)
        }
        return "<article>\(sections.joined(separator: "\n"))</article>"
    }()
}
