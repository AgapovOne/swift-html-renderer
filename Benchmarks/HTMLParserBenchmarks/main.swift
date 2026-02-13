import Foundation
import HTMLParser
import HTMLRenderer
import SwiftUI
import CLexbor
import SwiftSoup
import justhtml
import BonMot
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
#if canImport(Darwin)
import Darwin
#endif

struct BenchmarkResult {
    let times: [Double] // in milliseconds

    var average: Double { times.reduce(0, +) / Double(times.count) }

    var median: Double {
        let sorted = times.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    var p95: Double {
        let sorted = times.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
}

struct MemorySnapshot {
    let before: Int // bytes
    let after: Int  // bytes
    var delta: Int { after - before }
}

func currentResidentMemory() -> Int {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
        MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
    )
    let result = withUnsafeMutablePointer(to: &info) { infoPtr in
        infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rawPtr in
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rawPtr, &count)
        }
    }
    if result == KERN_SUCCESS {
        return Int(info.resident_size)
    }
    return 0
}

func durationToMs(_ duration: Duration) -> Double {
    Double(duration.components.attoseconds) / 1_000_000_000_000_000.0
        + Double(duration.components.seconds) * 1000.0
}

func benchmarkHTMLParser(html: String, warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        _ = HTMLParser.parseFragment(html)
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            _ = HTMLParser.parseFragment(html)
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func benchmarkNSAttributedString(html: String, warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()
    let data = Data(html.utf8)
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue,
    ]

    for _ in 0..<warmup {
        _ = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            _ = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func benchmarkSwiftSoup(html: String, warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        _ = try? SwiftSoup.parse(html)
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            _ = try? SwiftSoup.parse(html)
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func measureMemory(parsing html: String, withHTMLParser: Bool) -> MemorySnapshot {
    measureMemory {
        if withHTMLParser {
            for _ in 0..<10 {
                _ = HTMLParser.parseFragment(html)
            }
        } else {
            let data = Data(html.utf8)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ]
            for _ in 0..<10 {
                _ = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
            }
        }
    }
}

func measureMemory(_ work: () -> Void) -> MemorySnapshot {
    let before = currentResidentMemory()
    work()
    let after = currentResidentMemory()
    return MemorySnapshot(before: before, after: after)
}

func measureSwiftSoupMemory(parsing html: String) -> MemorySnapshot {
    measureMemory {
        for _ in 0..<10 {
            _ = try? SwiftSoup.parse(html)
        }
    }
}

func benchmarkJustHTML(html: String, warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        _ = try? JustHTML(html)
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            _ = try? JustHTML(html)
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func measureJustHTMLMemory(parsing html: String) -> MemorySnapshot {
    measureMemory {
        for _ in 0..<10 {
            _ = try? JustHTML(html)
        }
    }
}

func benchmarkLexbor(html: String, warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        if let doc = lxb_html_document_create() {
            html.withCString { cstr in
                _ = lxb_html_document_parse(doc, cstr, strlen(cstr))
            }
            lxb_html_document_destroy(doc)
        }
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            if let doc = lxb_html_document_create() {
                html.withCString { cstr in
                    _ = lxb_html_document_parse(doc, cstr, strlen(cstr))
                }
                lxb_html_document_destroy(doc)
            }
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func measureLexborMemory(parsing html: String) -> MemorySnapshot {
    measureMemory {
        for _ in 0..<10 {
            if let doc = lxb_html_document_create() {
                html.withCString { cstr in
                    _ = lxb_html_document_parse(doc, cstr, strlen(cstr))
                }
                lxb_html_document_destroy(doc)
            }
        }
    }
}

func makeBonMotXMLRules() -> [XMLStyleRule] {
    let tags = [
        "root", "h1", "h2", "h3", "p", "b", "s", "ul", "ol", "li", "a",
        "em", "strong", "code", "pre", "blockquote", "table", "thead", "tbody",
        "tr", "th", "td", "div", "section", "header", "main", "footer", "nav",
        "dl", "dt", "dd", "article", "time",
    ]
    return tags.map { .style($0, StringStyle()) }
}

func benchmarkBonMot(xml: String, rules: [XMLStyleRule], warmup: Int = 10, iterations: Int = 100) -> BenchmarkResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        _ = try? NSAttributedString.composed(ofXML: xml, rules: rules)
    }

    var times: [Double] = []
    times.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let duration = clock.measure {
            _ = try? NSAttributedString.composed(ofXML: xml, rules: rules)
        }
        times.append(durationToMs(duration))
    }

    return BenchmarkResult(times: times)
}

func measureBonMotMemory(parsing xml: String, rules: [XMLStyleRule]) -> MemorySnapshot {
    measureMemory {
        for _ in 0..<10 {
            _ = try? NSAttributedString.composed(ofXML: xml, rules: rules)
        }
    }
}

// --- Pipeline benchmark ---

struct PipelineResult {
    let parseTimes: [Double]   // ms
    let bodyTimes: [Double]    // ms
    let totalTimes: [Double]   // ms

    var parseResult: BenchmarkResult { BenchmarkResult(times: parseTimes) }
    var bodyResult: BenchmarkResult { BenchmarkResult(times: bodyTimes) }
    var totalResult: BenchmarkResult { BenchmarkResult(times: totalTimes) }
}

@MainActor
func benchmarkPipeline(html: String, warmup: Int = 10, iterations: Int = 100) -> PipelineResult {
    let clock = ContinuousClock()

    for _ in 0..<warmup {
        let doc = HTMLParser.parseFragment(html)
        let view = HTMLView(document: doc)
        _ = view.body
    }

    var parseTimes: [Double] = []
    var bodyTimes: [Double] = []
    var totalTimes: [Double] = []
    parseTimes.reserveCapacity(iterations)
    bodyTimes.reserveCapacity(iterations)
    totalTimes.reserveCapacity(iterations)

    for _ in 0..<iterations {
        let totalStart = clock.now

        let parseDuration = clock.measure {
            _ = HTMLParser.parseFragment(html)
        }
        let doc = HTMLParser.parseFragment(html)

        let bodyDuration = clock.measure {
            let view = HTMLView(document: doc)
            _ = view.body
        }

        let totalEnd = clock.now
        let totalDuration = totalEnd - totalStart

        parseTimes.append(durationToMs(parseDuration))
        bodyTimes.append(durationToMs(bodyDuration))
        totalTimes.append(durationToMs(totalDuration))
    }

    return PipelineResult(parseTimes: parseTimes, bodyTimes: bodyTimes, totalTimes: totalTimes)
}

func formatMs(_ value: Double) -> String {
    if value < 0.01 {
        String(format: "%.4fms", value)
    } else {
        String(format: "%.2fms", value)
    }
}

func formatBytes(_ bytes: Int) -> String {
    let abs = abs(bytes)
    let sign = bytes < 0 ? "-" : ""
    if abs < 1024 {
        return "\(sign)\(abs) B"
    } else if abs < 1024 * 1024 {
        return String(format: "%@%.1f KB", sign, Double(abs) / 1024.0)
    } else {
        return String(format: "%@%.1f MB", sign, Double(abs) / (1024.0 * 1024.0))
    }
}

func pad(_ string: String, to width: Int) -> String {
    if string.count >= width { return string }
    return string + String(repeating: " ", count: width - string.count)
}

func padLeft(_ string: String, to width: Int) -> String {
    if string.count >= width { return string }
    return String(repeating: " ", count: width - string.count) + string
}

func printResults(_ label: String, _ results: [(String, BenchmarkResult)]) {
    let separator = "|----------|------------|------------|------------|"
    print(separator)
    print("| \(pad("Size", to: 8)) | \(padLeft("Avg", to: 10)) | \(padLeft("Median", to: 10)) | \(padLeft("P95", to: 10)) |")
    print(separator)

    for (name, result) in results {
        print("| \(pad(name, to: 8)) | \(padLeft(formatMs(result.average), to: 10)) | \(padLeft(formatMs(result.median), to: 10)) | \(padLeft(formatMs(result.p95), to: 10)) |")
    }
    print(separator)
}

func printComparison(
    sizes: [String],
    ours: [BenchmarkResult],
    baseline: [BenchmarkResult]
) {
    let sep = "|----------|------------|------------|----------|"
    print(sep)
    print("| \(pad("Size", to: 8)) | \(padLeft("HTMLParser", to: 10)) | \(padLeft("NSAttrStr", to: 10)) | \(padLeft("Speedup", to: 8)) |")
    print(sep)

    for i in 0..<sizes.count {
        let ourMedian = ours[i].median
        let baseMedian = baseline[i].median
        let speedup = baseMedian / ourMedian
        print("| \(pad(sizes[i], to: 8)) | \(padLeft(formatMs(ourMedian), to: 10)) | \(padLeft(formatMs(baseMedian), to: 10)) | \(padLeft(String(format: "%.1fx", speedup), to: 8)) |")
    }
    print(sep)
}

// --- Report generation ---

// Parser entry: name + results per size
struct ParserBenchmarkEntry {
    let name: String
    let results: [(String, BenchmarkResult)] // (size label, result)
    let memoryResults: [(String, MemorySnapshot)] // (size label, snapshot)
    let note: String? // e.g. "XML-adapted docs"
}

struct PipelineBenchmarkEntry {
    let sizeLabel: String
    let parseResult: BenchmarkResult
    let bodyResult: BenchmarkResult
    let totalResult: BenchmarkResult
}

struct BenchmarkReport {
    let date: String
    let smallSize: Int
    let mediumSize: Int
    let largeSize: Int
    let parsers: [ParserBenchmarkEntry]
    let baselineIndex: Int // index of NSAttributedString in parsers array
    let pipelineResults: [PipelineBenchmarkEntry]

    func toMarkdown() -> String {
        var md = ""
        md += "# Benchmark Report\n\n"
        md += "Date: \(date)\n\n"
        md += "Configuration: 10 warmup + 100 measured iterations, release build\n\n"
        md += "## Document Sizes\n\n"
        md += "| Document | Size |\n"
        md += "|----------|------|\n"
        md += "| Small | \(formatBytes(smallSize)) |\n"
        md += "| Medium | \(formatBytes(mediumSize)) |\n"
        md += "| Large | \(formatBytes(largeSize)) |\n\n"

        // Individual parser results
        for parser in parsers {
            let noteStr = parser.note.map { " (\($0))" } ?? ""
            md += "## \(parser.name)\(noteStr)\n\n"
            md += "| Size | Avg | Median | P95 |\n"
            md += "|------|-----|--------|-----|\n"
            for (name, result) in parser.results {
                md += "| \(name) | \(formatMs(result.average)) | \(formatMs(result.median)) | \(formatMs(result.p95)) |\n"
            }
            md += "\n"
        }

        // Parsers Comparison table (median)
        let sizes = parsers[0].results.map { $0.0 }
        let baseline = parsers[baselineIndex]
        let hasNotes = parsers.contains { $0.note != nil }

        md += "## Parsers Comparison (median)\n\n"
        md += "| Size |"
        for parser in parsers {
            let marker = parser.note != nil ? "*" : ""
            md += " \(parser.name)\(marker) |"
        }
        md += "\n|------|"
        for _ in parsers {
            md += "------|"
        }
        md += "\n"

        for (sizeIdx, size) in sizes.enumerated() {
            md += "| \(size) |"
            for parser in parsers {
                md += " \(formatMs(parser.results[sizeIdx].1.median)) |"
            }
            md += "\n"
        }
        md += "\n"
        if hasNotes {
            for parser in parsers where parser.note != nil {
                md += "\\* **\(parser.name)**: \(parser.note!). BonMot uses Foundation XMLParser, not an HTML parser. Test documents were converted to valid XML (no HTML entities like `&mdash;`, no void elements like `<br>`, wrapped in `<root>`). Results are not directly comparable to HTML parsers.\n\n"
            }
        }

        // Speedup vs baseline
        md += "## Speedup vs \(baseline.name) (median)\n\n"
        md += "| Size |"
        for parser in parsers where parser.name != baseline.name {
            let marker = parser.note != nil ? "*" : ""
            md += " \(parser.name)\(marker) |"
        }
        md += "\n|------|"
        for parser in parsers where parser.name != baseline.name {
            _ = parser
            md += "------|"
        }
        md += "\n"

        for (sizeIdx, size) in sizes.enumerated() {
            let baseMedian = baseline.results[sizeIdx].1.median
            md += "| \(size) |"
            for parser in parsers where parser.name != baseline.name {
                let speedup = baseMedian / parser.results[sizeIdx].1.median
                md += " \(String(format: "%.1fx", speedup)) |"
            }
            md += "\n"
        }
        md += "\n"

        // Memory comparison
        md += "## Memory Comparison (resident size delta, 10 parses)\n\n"
        md += "| Size |"
        for parser in parsers {
            let marker = parser.note != nil ? "*" : ""
            md += " \(parser.name)\(marker) |"
        }
        md += "\n|------|"
        for _ in parsers {
            md += "------|"
        }
        md += "\n"

        for (sizeIdx, size) in sizes.enumerated() {
            md += "| \(size) |"
            for parser in parsers {
                md += " \(formatBytes(parser.memoryResults[sizeIdx].1.delta)) |"
            }
            md += "\n"
        }
        md += "\n"

        // Pipeline section
        if !pipelineResults.isEmpty {
            md += "## Pipeline (HTMLParser + HTMLView.body)\n\n"
            md += "| Size | Parse (median) | Body (median) | Total (median) |\n"
            md += "|------|----------------|---------------|----------------|\n"
            for entry in pipelineResults {
                md += "| \(entry.sizeLabel) | \(formatMs(entry.parseResult.median)) | \(formatMs(entry.bodyResult.median)) | \(formatMs(entry.totalResult.median)) |\n"
            }
            md += "\n"
        }

        return md
    }
}

// --- Main ---

let smallSize = TestDocuments.small.utf8.count
let mediumSize = TestDocuments.medium.utf8.count
let largeSize = TestDocuments.large.utf8.count

let documents = [
    ("Small", TestDocuments.small),
    ("Medium", TestDocuments.medium),
    ("Large", TestDocuments.large),
]

print("HTMLParser Benchmarks")
print("====================")
print()
print("Document sizes:")
print("  Small:  \(smallSize) bytes")
print("  Medium: \(mediumSize) bytes")
print("  Large:  \(largeSize) bytes")
print()
print("Configuration: 10 warmup + 100 measured iterations")
print()

// --- HTMLParser ---
print("Running HTMLParser benchmarks...")
let htmlParserResults: [(String, BenchmarkResult)] = documents.map { (label, html) in
    (label, benchmarkHTMLParser(html: html))
}
print("HTMLParser Results:")
printResults("HTMLParser", htmlParserResults)

let htmlParserMemory: [(String, MemorySnapshot)] = documents.map { (label, html) in
    (label, measureMemory(parsing: html, withHTMLParser: true))
}

// --- NSAttributedString ---
print()
print("Running NSAttributedString(html:) benchmarks...")
let nsResults: [(String, BenchmarkResult)] = documents.map { (label, html) in
    (label, benchmarkNSAttributedString(html: html))
}
print("NSAttributedString Results:")
printResults("NSAttrStr", nsResults)

let nsMemory: [(String, MemorySnapshot)] = documents.map { (label, html) in
    (label, measureMemory(parsing: html, withHTMLParser: false))
}

// --- SwiftSoup ---
print()
print("Running SwiftSoup benchmarks...")
let swiftSoupResults: [(String, BenchmarkResult)] = documents.map { (label, html) in
    (label, benchmarkSwiftSoup(html: html))
}
print("SwiftSoup Results:")
printResults("SwiftSoup", swiftSoupResults)

let swiftSoupMemory: [(String, MemorySnapshot)] = documents.map { (label, html) in
    (label, measureSwiftSoupMemory(parsing: html))
}

// --- JustHTML ---
print()
print("Running JustHTML benchmarks...")
let justHTMLResults: [(String, BenchmarkResult)] = documents.map { (label, html) in
    (label, benchmarkJustHTML(html: html))
}
print("JustHTML Results:")
printResults("JustHTML", justHTMLResults)

let justHTMLMemory: [(String, MemorySnapshot)] = documents.map { (label, html) in
    (label, measureJustHTMLMemory(parsing: html))
}

// --- BonMot (XML-adapted docs) ---
let xmlDocuments = [
    ("Small", TestDocuments.smallXML),
    ("Medium", TestDocuments.mediumXML),
    ("Large", TestDocuments.largeXML),
]

// --- BonMot (XML-adapted docs) ---
let bonMotRules = makeBonMotXMLRules()

print()
print("Running BonMot benchmarks (XML-adapted docs)...")
let bonMotResults: [(String, BenchmarkResult)] = xmlDocuments.map { (label, xml) in
    (label, benchmarkBonMot(xml: xml, rules: bonMotRules))
}
print("BonMot Results:")
printResults("BonMot", bonMotResults)

let bonMotMemory: [(String, MemorySnapshot)] = xmlDocuments.map { (label, xml) in
    (label, measureBonMotMemory(parsing: xml, rules: bonMotRules))
}

// --- Lexbor ---
print()
print("Running Lexbor benchmarks...")
let lexborResults: [(String, BenchmarkResult)] = documents.map { (label, html) in
    (label, benchmarkLexbor(html: html))
}
print("Lexbor Results:")
printResults("Lexbor", lexborResults)

let lexborMemory: [(String, MemorySnapshot)] = documents.map { (label, html) in
    (label, measureLexborMemory(parsing: html))
}

// --- Pipeline (HTMLParser + HTMLView.body) ---
print()
print("Running Pipeline benchmarks (parse + body)...")
let pipelineResults: [PipelineBenchmarkEntry] = documents.map { (label, html) in
    let result = benchmarkPipeline(html: html)
    return PipelineBenchmarkEntry(
        sizeLabel: label,
        parseResult: result.parseResult,
        bodyResult: result.bodyResult,
        totalResult: result.totalResult
    )
}

let pipeSep = "|----------|------------|------------|------------|"
print("Pipeline Results (median):")
print(pipeSep)
print("| \(pad("Size", to: 8)) | \(padLeft("Parse", to: 10)) | \(padLeft("Body", to: 10)) | \(padLeft("Total", to: 10)) |")
print(pipeSep)
for entry in pipelineResults {
    print("| \(pad(entry.sizeLabel, to: 8)) | \(padLeft(formatMs(entry.parseResult.median), to: 10)) | \(padLeft(formatMs(entry.bodyResult.median), to: 10)) | \(padLeft(formatMs(entry.totalResult.median), to: 10)) |")
}
print(pipeSep)

// --- Comparison ---
print()
print("Comparison (median times):")
printComparison(
    sizes: ["Small", "Medium", "Large"],
    ours: htmlParserResults.map { $0.1 },
    baseline: nsResults.map { $0.1 }
)

// --- Memory ---
print()
print("Memory Usage (resident size delta over 10 parses):")
let memSep = "|----------|------------|------------|------------|------------|------------|------------|"
print(memSep)
print("| \(pad("Size", to: 8)) | \(padLeft("HTMLParser", to: 10)) | \(padLeft("NSAttrStr", to: 10)) | \(padLeft("SwiftSoup", to: 10)) | \(padLeft("JustHTML", to: 10)) | \(padLeft("BonMot", to: 10)) | \(padLeft("Lexbor", to: 10)) |")
print(memSep)
for i in 0..<documents.count {
    let label = documents[i].0
    print("| \(pad(label, to: 8)) | \(padLeft(formatBytes(htmlParserMemory[i].1.delta), to: 10)) | \(padLeft(formatBytes(nsMemory[i].1.delta), to: 10)) | \(padLeft(formatBytes(swiftSoupMemory[i].1.delta), to: 10)) | \(padLeft(formatBytes(justHTMLMemory[i].1.delta), to: 10)) | \(padLeft(formatBytes(bonMotMemory[i].1.delta), to: 10)) | \(padLeft(formatBytes(lexborMemory[i].1.delta), to: 10)) |")
}
print(memSep)
print()

// --- Report ---
let parsers = [
    ParserBenchmarkEntry(name: "HTMLParser", results: htmlParserResults, memoryResults: htmlParserMemory, note: nil),
    ParserBenchmarkEntry(name: "NSAttributedString", results: nsResults, memoryResults: nsMemory, note: nil),
    ParserBenchmarkEntry(name: "SwiftSoup", results: swiftSoupResults, memoryResults: swiftSoupMemory, note: nil),
    ParserBenchmarkEntry(name: "JustHTML", results: justHTMLResults, memoryResults: justHTMLMemory, note: nil),
    ParserBenchmarkEntry(name: "BonMot", results: bonMotResults, memoryResults: bonMotMemory, note: "XML-adapted docs"),
    ParserBenchmarkEntry(name: "Lexbor", results: lexborResults, memoryResults: lexborMemory, note: nil),
]

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
let dateString = dateFormatter.string(from: Date())

let report = BenchmarkReport(
    date: dateString,
    smallSize: smallSize,
    mediumSize: mediumSize,
    largeSize: largeSize,
    parsers: parsers,
    baselineIndex: 1, // NSAttributedString
    pipelineResults: pipelineResults
)

let reportPath = "docs/BENCHMARK_RESULTS.md"
let markdown = report.toMarkdown()

do {
    try markdown.write(toFile: reportPath, atomically: true, encoding: .utf8)
    print("Report written to \(reportPath)")
} catch {
    let cwd = FileManager.default.currentDirectoryPath
    let fullPath = (cwd as NSString).appendingPathComponent(reportPath)
    do {
        try markdown.write(toFile: fullPath, atomically: true, encoding: .utf8)
        print("Report written to \(fullPath)")
    } catch {
        print("Failed to write report: \(error)")
        print()
        print("--- Markdown Report ---")
        print(markdown)
    }
}

