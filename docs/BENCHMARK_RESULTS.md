# Benchmark Report

Date: 2026-02-13 10:36:15

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
| Small | 0.04ms | 0.03ms | 0.09ms |
| Medium | 0.23ms | 0.23ms | 0.30ms |
| Large | 2.25ms | 2.24ms | 2.33ms |

## NSAttributedString

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 1.70ms | 1.64ms | 2.02ms |
| Medium | 6.59ms | 6.57ms | 7.21ms |
| Large | 120.11ms | 119.45ms | 126.99ms |

## SwiftSoup

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 0.04ms | 0.04ms | 0.05ms |
| Medium | 0.29ms | 0.28ms | 0.35ms |
| Large | 5.99ms | 5.98ms | 6.35ms |

## Parsers Comparison (median)

| Size | HTMLParser | NSAttributedString | SwiftSoup |
|------|------|------|------|
| Small | 0.03ms | 1.64ms | 0.04ms |
| Medium | 0.23ms | 6.57ms | 0.28ms |
| Large | 2.24ms | 119.45ms | 5.98ms |

## Speedup vs NSAttributedString (median)

| Size | HTMLParser | SwiftSoup |
|------|------|------|
| Small | 49.4x | 40.5x |
| Medium | 28.0x | 23.4x |
| Large | 53.4x | 20.0x |

## Memory Comparison (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString | SwiftSoup |
|------|------|------|------|
| Small | 0 B | 32.0 KB | 0 B |
| Medium | 0 B | 16.0 KB | 0 B |
| Large | 32.0 KB | 192.0 KB | 0 B |

