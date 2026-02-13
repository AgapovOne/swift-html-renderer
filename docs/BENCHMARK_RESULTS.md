# Benchmark Report

Date: 2026-02-13 11:12:43

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
| Small | 0.04ms | 0.04ms | 0.04ms |
| Medium | 0.25ms | 0.23ms | 0.33ms |
| Large | 2.22ms | 2.21ms | 2.31ms |

## NSAttributedString

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 1.83ms | 1.78ms | 2.32ms |
| Medium | 6.60ms | 6.44ms | 7.94ms |
| Large | 119.65ms | 119.78ms | 124.04ms |

## SwiftSoup

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.04ms | 0.04ms | 0.05ms |
| Medium | 0.28ms | 0.28ms | 0.29ms |
| Large | 5.69ms | 5.65ms | 5.89ms |

## JustHTML

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.03ms | 0.03ms | 0.03ms |
| Medium | 0.36ms | 0.36ms | 0.37ms |
| Large | 7.81ms | 7.81ms | 8.02ms |

## BonMot (XML-adapted docs)

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.09ms | 0.09ms | 0.09ms |
| Medium | 0.74ms | 0.73ms | 0.77ms |
| Large | 17.04ms | 17.03ms | 17.57ms |

## Lexbor

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.0056ms | 0.0055ms | 0.0057ms |
| Medium | 0.02ms | 0.02ms | 0.02ms |
| Large | 0.27ms | 0.27ms | 0.28ms |

## Parsers Comparison (median)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0.04ms | 1.78ms | 0.04ms | 0.03ms | 0.09ms | 0.0055ms |
| Medium | 0.23ms | 6.44ms | 0.28ms | 0.36ms | 0.73ms | 0.02ms |
| Large | 2.21ms | 119.78ms | 5.65ms | 7.81ms | 17.03ms | 0.27ms |

\* **BonMot**: XML-adapted docs. BonMot uses Foundation XMLParser, not an HTML parser. Test documents were converted to valid XML (no HTML entities like `&mdash;`, no void elements like `<br>`, wrapped in `<root>`). Results are not directly comparable to HTML parsers.

## Speedup vs NSAttributedString (median)

| Size | HTMLParser | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|
| Small | 46.0x | 44.7x | 71.0x | 20.6x | 320.7x |
| Medium | 27.4x | 23.2x | 17.9x | 8.8x | 413.0x |
| Large | 54.3x | 21.2x | 15.3x | 7.0x | 439.8x |

## Memory Comparison (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0 B | 16.0 KB | 0 B | 0 B | 0 B | 0 B |
| Medium | 0 B | 48.0 KB | 0 B | 0 B | 48.0 KB | 0 B |
| Large | 16.0 KB | -196608 B | 0 B | 16.0 KB | 960.0 KB | 0 B |

## Pipeline (HTMLParser + HTMLView.body)

| Size | Parse (median) | Body (median) | Total (median) |
|------|----------------|---------------|----------------|
| Small | 0.01ms | 0.0011ms | 0.02ms |
| Medium | 0.10ms | 0.0013ms | 0.20ms |
| Large | 2.24ms | 0.0022ms | 4.49ms |

