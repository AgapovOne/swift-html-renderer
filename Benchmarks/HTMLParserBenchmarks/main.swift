import Foundation
import HTMLParser
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

func measureMemory(parsing html: String, withHTMLParser: Bool) -> MemorySnapshot {
    let before = currentResidentMemory()
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
    let after = currentResidentMemory()
    return MemorySnapshot(before: before, after: after)
}

func formatMs(_ value: Double) -> String {
    if value < 0.01 {
        String(format: "%.4fms", value)
    } else {
        String(format: "%.2fms", value)
    }
}

func formatBytes(_ bytes: Int) -> String {
    if bytes < 1024 {
        return "\(bytes) B"
    } else if bytes < 1024 * 1024 {
        return String(format: "%.1f KB", Double(bytes) / 1024.0)
    } else {
        return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
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

struct BenchmarkReport {
    let date: String
    let smallSize: Int
    let mediumSize: Int
    let largeSize: Int
    let parserResults: [(String, BenchmarkResult)]
    let nsResults: [(String, BenchmarkResult)]
    let memoryResults: [(String, MemorySnapshot, MemorySnapshot)] // label, ours, ns

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

        md += "## HTMLParser\n\n"
        md += "| Size | Avg | Median | P95 |\n"
        md += "|------|-----|--------|-----|\n"
        for (name, result) in parserResults {
            md += "| \(name) | \(formatMs(result.average)) | \(formatMs(result.median)) | \(formatMs(result.p95)) |\n"
        }
        md += "\n"

        md += "## NSAttributedString(html:)\n\n"
        md += "| Size | Avg | Median | P95 |\n"
        md += "|------|-----|--------|-----|\n"
        for (name, result) in nsResults {
            md += "| \(name) | \(formatMs(result.average)) | \(formatMs(result.median)) | \(formatMs(result.p95)) |\n"
        }
        md += "\n"

        md += "## Comparison (median)\n\n"
        md += "| Size | HTMLParser | NSAttributedString | Speedup |\n"
        md += "|------|-----------|-------------------|--------|\n"
        for i in 0..<parserResults.count {
            let ourMedian = parserResults[i].1.median
            let nsMedian = nsResults[i].1.median
            let speedup = nsMedian / ourMedian
            md += "| \(parserResults[i].0) | \(formatMs(ourMedian)) | \(formatMs(nsMedian)) | \(String(format: "%.1fx", speedup)) |\n"
        }
        md += "\n"

        md += "## Memory (resident size delta, 10 parses)\n\n"
        md += "| Size | HTMLParser | NSAttributedString |\n"
        md += "|------|-----------|-------------------|\n"
        for (label, ours, ns) in memoryResults {
            md += "| \(label) | \(formatBytes(ours.delta)) | \(formatBytes(ns.delta)) |\n"
        }
        md += "\n"

        return md
    }
}

// --- Main ---

let smallSize = TestDocuments.small.utf8.count
let mediumSize = TestDocuments.medium.utf8.count
let largeSize = TestDocuments.large.utf8.count

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

// HTMLParser benchmarks
print("Running HTMLParser benchmarks...")
let smallResult = benchmarkHTMLParser(html: TestDocuments.small)
let mediumResult = benchmarkHTMLParser(html: TestDocuments.medium)
let largeResult = benchmarkHTMLParser(html: TestDocuments.large)

let parserResults = [
    ("Small", smallResult),
    ("Medium", mediumResult),
    ("Large", largeResult),
]

print()
print("HTMLParser Results:")
printResults("HTMLParser", parserResults)

// NSAttributedString benchmarks
print()
print("Running NSAttributedString(html:) benchmarks...")
print("Note: NSAttributedString uses WebKit under the hood and may require main thread.")
print()
let nsSmallResult = benchmarkNSAttributedString(html: TestDocuments.small)
let nsMediumResult = benchmarkNSAttributedString(html: TestDocuments.medium)
let nsLargeResult = benchmarkNSAttributedString(html: TestDocuments.large)

let nsResults = [
    ("Small", nsSmallResult),
    ("Medium", nsMediumResult),
    ("Large", nsLargeResult),
]

print("NSAttributedString Results:")
printResults("NSAttrStr", nsResults)

// Side-by-side comparison
print()
print("Comparison (median times):")
printComparison(
    sizes: ["Small", "Medium", "Large"],
    ours: [smallResult, mediumResult, largeResult],
    baseline: [nsSmallResult, nsMediumResult, nsLargeResult]
)

// Memory measurement
print()
print("Memory Usage (resident size delta over 10 parses):")
let memSep = "|----------|------------|------------|"
print(memSep)
print("| \(pad("Size", to: 8)) | \(padLeft("HTMLParser", to: 10)) | \(padLeft("NSAttrStr", to: 10)) |")
print(memSep)

let documents = [
    ("Small", TestDocuments.small),
    ("Medium", TestDocuments.medium),
    ("Large", TestDocuments.large),
]

var memoryResults: [(String, MemorySnapshot, MemorySnapshot)] = []
for (label, html) in documents {
    let ourMem = measureMemory(parsing: html, withHTMLParser: true)
    let nsMem = measureMemory(parsing: html, withHTMLParser: false)
    memoryResults.append((label, ourMem, nsMem))
    print("| \(pad(label, to: 8)) | \(padLeft(formatBytes(ourMem.delta), to: 10)) | \(padLeft(formatBytes(nsMem.delta), to: 10)) |")
}
print(memSep)
print()

// Write markdown report
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
let dateString = dateFormatter.string(from: Date())

let report = BenchmarkReport(
    date: dateString,
    smallSize: smallSize,
    mediumSize: mediumSize,
    largeSize: largeSize,
    parserResults: parserResults,
    nsResults: nsResults,
    memoryResults: memoryResults
)

let reportPath = "docs/BENCHMARK_RESULTS.md"
let markdown = report.toMarkdown()

do {
    try markdown.write(toFile: reportPath, atomically: true, encoding: .utf8)
    print("Report written to \(reportPath)")
} catch {
    // Try writing relative to the working directory with full path construction
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
