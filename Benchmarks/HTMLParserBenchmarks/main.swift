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

print()
print("HTMLParser Results:")
printResults("HTMLParser", [
    ("Small", smallResult),
    ("Medium", mediumResult),
    ("Large", largeResult),
])

// NSAttributedString benchmarks
print()
print("Running NSAttributedString(html:) benchmarks...")
print("Note: NSAttributedString uses WebKit under the hood and may require main thread.")
print()
let nsSmallResult = benchmarkNSAttributedString(html: TestDocuments.small)
let nsMediumResult = benchmarkNSAttributedString(html: TestDocuments.medium)
let nsLargeResult = benchmarkNSAttributedString(html: TestDocuments.large)

print("NSAttributedString Results:")
printResults("NSAttrStr", [
    ("Small", nsSmallResult),
    ("Medium", nsMediumResult),
    ("Large", nsLargeResult),
])

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

for (label, html) in documents {
    let ourMem = measureMemory(parsing: html, withHTMLParser: true)
    let nsMem = measureMemory(parsing: html, withHTMLParser: false)
    print("| \(pad(label, to: 8)) | \(padLeft(formatBytes(ourMem.delta), to: 10)) | \(padLeft(formatBytes(nsMem.delta), to: 10)) |")
}
print(memSep)
print()
