# Benchmark Report

Date: 2026-02-13 16:17:45

Configuration: 10 warmup + 100 measured iterations, release build

## Document Sizes

| Document | Size |
|----------|------|
| Small | 371 B |
| Medium | 3.9 KB |
| Large | 82.6 KB |

## HTMLParser

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.0083ms | 0.0082ms | 0.0090ms |
| Medium | 0.03ms | 0.03ms | 0.03ms |
| Large | 0.55ms | 0.54ms | 0.63ms |

## NSAttributedString

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 1.87ms | 1.85ms | 2.21ms |
| Medium | 7.69ms | 7.36ms | 8.45ms |
| Large | 121.98ms | 120.87ms | 131.54ms |

## SwiftSoup

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.04ms | 0.04ms | 0.05ms |
| Medium | 0.29ms | 0.28ms | 0.36ms |
| Large | 5.97ms | 5.80ms | 6.72ms |

## JustHTML

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.03ms | 0.03ms | 0.03ms |
| Medium | 0.37ms | 0.37ms | 0.40ms |
| Large | 7.82ms | 7.79ms | 8.11ms |

## BonMot (XML-adapted docs)

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.20ms | 0.10ms | 0.72ms |
| Medium | 0.77ms | 0.76ms | 0.85ms |
| Large | 17.71ms | 17.52ms | 18.67ms |

## Lexbor

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.0056ms | 0.0056ms | 0.0057ms |
| Medium | 0.02ms | 0.02ms | 0.02ms |
| Large | 0.27ms | 0.27ms | 0.30ms |

## Parsers Comparison (median)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0.0082ms | 1.85ms | 0.04ms | 0.03ms | 0.10ms | 0.0056ms |
| Medium | 0.03ms | 7.36ms | 0.28ms | 0.37ms | 0.76ms | 0.02ms |
| Large | 0.54ms | 120.87ms | 5.80ms | 7.79ms | 17.52ms | 0.27ms |

\* **BonMot**: XML-adapted docs. BonMot uses Foundation XMLParser, not an HTML parser. Test documents were converted to valid XML (no HTML entities like `&mdash;`, no void elements like `<br>`, wrapped in `<root>`). Results are not directly comparable to HTML parsers.

## Speedup vs NSAttributedString (median)

| Size | HTMLParser | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|
| Small | 225.4x | 45.5x | 70.9x | 19.3x | 328.9x |
| Medium | 254.4x | 26.3x | 20.1x | 9.6x | 473.5x |
| Large | 222.7x | 20.9x | 15.5x | 6.9x | 449.4x |

## Memory Comparison (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0 B | 32.0 KB | 0 B | 0 B | 0 B | 0 B |
| Medium | 0 B | 48.0 KB | 0 B | 0 B | 48.0 KB | 0 B |
| Large | 96.0 KB | 208.0 KB | 0 B | 16.0 KB | 960.0 KB | 16.0 KB |

## Pipeline (HTMLParser + HTMLView.body)

| Size | Parse (median) | Body (median) | Total (median) |
|------|----------------|---------------|----------------|
| Small | 0.0075ms | 0.0013ms | 0.02ms |
| Medium | 0.03ms | 0.0013ms | 0.06ms |
| Large | 0.53ms | 0.0018ms | 1.07ms |

