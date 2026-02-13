import HTMLParser
import HTMLRenderer
import SwiftUI

// MARK: - Benchmark Result Model

struct BenchmarkEntry: Identifiable {
    let id = UUID()
    let sizeLabel: String
    let parseMedian: Double   // ms
    let layoutMedian: Double  // ms
    var totalMedian: Double { parseMedian + layoutMedian }
}

// MARK: - Benchmark Runner

@MainActor
final class BenchmarkRunner: ObservableObject {
    @Published var results: [BenchmarkEntry] = []
    @Published var isRunning = false
    @Published var currentStep = ""

    let warmup = 10
    let iterations = 100

    func run() {
        guard !isRunning else { return }
        isRunning = true
        results = []

        let documents: [(String, String)] = [
            ("Small", BenchmarkDocuments.small),
            ("Medium", BenchmarkDocuments.medium),
            ("Large", BenchmarkDocuments.large),
        ]

        // Run on background then hop back for layout measurement
        Task {
            for (label, html) in documents {
                currentStep = "Benchmarking \(label)..."
                let entry = benchmarkDocument(label: label, html: html)
                results.append(entry)
            }
            currentStep = ""
            isRunning = false
        }
    }

    private func benchmarkDocument(label: String, html: String) -> BenchmarkEntry {
        let clock = ContinuousClock()

        // Warmup
        for _ in 0..<warmup {
            let doc = HTMLParser.parseFragment(html)
            let view = HTMLView(document: doc)
            let _ = measureLayout(view: view)
        }

        // Measure
        var parseTimes: [Double] = []
        var layoutTimes: [Double] = []
        parseTimes.reserveCapacity(iterations)
        layoutTimes.reserveCapacity(iterations)

        for _ in 0..<iterations {
            // Parse
            var doc: HTMLDocument!
            let parseDuration = clock.measure {
                doc = HTMLParser.parseFragment(html)
            }

            // Layout via hosting controller
            let view = HTMLView(document: doc)
            let layoutDuration = clock.measure {
                let _ = measureLayout(view: view)
            }

            parseTimes.append(durationToMs(parseDuration))
            layoutTimes.append(durationToMs(layoutDuration))
        }

        let parseMedian = median(parseTimes)
        let layoutMedian = median(layoutTimes)

        return BenchmarkEntry(
            sizeLabel: label,
            parseMedian: parseMedian,
            layoutMedian: layoutMedian
        )
    }

    private func measureLayout(view: HTMLView) -> CGSize {
        #if os(iOS) || os(tvOS) || os(visionOS)
        let hc = UIHostingController(rootView: view)
        return hc.sizeThatFits(in: CGSize(width: 375, height: CGFloat.infinity))
        #elseif os(macOS)
        let hv = NSHostingView(rootView: view)
        return hv.fittingSize
        #endif
    }

    private func durationToMs(_ duration: Duration) -> Double {
        Double(duration.components.attoseconds) / 1_000_000_000_000_000.0
            + Double(duration.components.seconds) * 1000.0
    }

    private func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }
}

// MARK: - Benchmark View

struct BenchmarkView: View {
    @StateObject private var runner = BenchmarkRunner()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                if !runner.results.isEmpty {
                    resultsSection
                }
            }
            .padding(24)
        }
        .navigationTitle("Benchmarks")
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline Benchmark")
                .font(.headline)
            Text("Measures HTMLParser.parseFragment() + UIHostingController.sizeThatFits() for three document sizes. \(runner.warmup) warmup + \(runner.iterations) iterations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { runner.run() }) {
                HStack {
                    if runner.isRunning {
                        ProgressView()
                            .controlSize(.small)
                        Text(runner.currentStep)
                    } else {
                        Image(systemName: "play.fill")
                        Text("Run Benchmarks")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(runner.isRunning)
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Results (median)")
                .font(.headline)

            // Table header
            HStack {
                Text("Size")
                    .frame(width: 70, alignment: .leading)
                Text("Parse")
                    .frame(width: 80, alignment: .trailing)
                Text("Layout")
                    .frame(width: 80, alignment: .trailing)
                Text("Total")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)

            Divider()

            ForEach(runner.results) { entry in
                HStack {
                    Text(entry.sizeLabel)
                        .frame(width: 70, alignment: .leading)
                    Text(formatMs(entry.parseMedian))
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(.blue)
                    Text(formatMs(entry.layoutMedian))
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(.orange)
                    Text(formatMs(entry.totalMedian))
                        .frame(width: 80, alignment: .trailing)
                        .fontWeight(.semibold)
                }
                .font(.system(.body, design: .monospaced))
            }

            Divider()

            // Document sizes info
            VStack(alignment: .leading, spacing: 4) {
                Text("Document sizes")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Small: \(BenchmarkDocuments.small.utf8.count) bytes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Medium: \(BenchmarkDocuments.medium.utf8.count) bytes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Large: \(BenchmarkDocuments.large.utf8.count) bytes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatMs(_ value: Double) -> String {
        if value < 0.01 {
            String(format: "%.4fms", value)
        } else {
            String(format: "%.2fms", value)
        }
    }
}

#Preview {
    NavigationStack {
        BenchmarkView()
    }
}
