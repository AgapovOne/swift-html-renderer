# Benchmark Report

Date: 2026-02-13 14:38:29

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
| Small | 0.02ms | 0.02ms | 0.03ms |
| Medium | 0.17ms | 0.16ms | 0.25ms |
| Large | 2.27ms | 2.31ms | 2.40ms |

## NSAttributedString

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 1.72ms | 1.67ms | 2.05ms |
| Medium | 6.52ms | 6.36ms | 8.12ms |
| Large | 118.20ms | 118.01ms | 122.77ms |

## SwiftSoup

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.04ms | 0.04ms | 0.04ms |
| Medium | 0.27ms | 0.27ms | 0.29ms |
| Large | 5.61ms | 5.61ms | 5.73ms |

## JustHTML

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.02ms | 0.02ms | 0.02ms |
| Medium | 0.36ms | 0.36ms | 0.37ms |
| Large | 7.69ms | 7.70ms | 7.92ms |

## BonMot (XML-adapted docs)

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.09ms | 0.09ms | 0.10ms |
| Medium | 0.78ms | 0.74ms | 0.82ms |
| Large | 16.67ms | 16.62ms | 17.42ms |

## Lexbor

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.0057ms | 0.0059ms | 0.0060ms |
| Medium | 0.02ms | 0.02ms | 0.02ms |
| Large | 0.28ms | 0.27ms | 0.30ms |

## Parsers Comparison (median)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0.02ms | 1.67ms | 0.04ms | 0.02ms | 0.09ms | 0.0059ms |
| Medium | 0.16ms | 6.36ms | 0.27ms | 0.36ms | 0.74ms | 0.02ms |
| Large | 2.31ms | 118.01ms | 5.61ms | 7.70ms | 16.62ms | 0.27ms |

\* **BonMot**: XML-adapted docs. BonMot uses Foundation XMLParser, not an HTML parser. Test documents were converted to valid XML (no HTML entities like `&mdash;`, no void elements like `<br>`, wrapped in `<root>`). Results are not directly comparable to HTML parsers.

## Speedup vs NSAttributedString (median)

| Size | HTMLParser | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|
| Small | 107.4x | 42.4x | 68.7x | 18.1x | 285.6x |
| Medium | 38.7x | 23.3x | 17.7x | 8.6x | 394.5x |
| Large | 51.1x | 21.0x | 15.3x | 7.1x | 433.2x |

## Memory Comparison (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString | SwiftSoup | JustHTML | BonMot* | Lexbor |
|------|------|------|------|------|------|------|
| Small | 0 B | 32.0 KB | 0 B | 0 B | 0 B | 0 B |
| Medium | 0 B | 16.0 KB | 0 B | 0 B | 48.0 KB | 0 B |
| Large | 32.0 KB | 224.0 KB | 0 B | 0 B | 960.0 KB | 0 B |

## Pipeline (HTMLParser + HTMLView.body)

| Size | Parse (median) | Body (median) | Total (median) |
|------|----------------|---------------|----------------|
| Small | 0.01ms | 0.0011ms | 0.02ms |
| Medium | 0.10ms | 0.0012ms | 0.20ms |
| Large | 2.21ms | 0.0024ms | 4.45ms |

