# Benchmark Report

Date: 2026-02-12 23:33:50

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
| Small | 0.06ms | 0.06ms | 0.07ms |
| Medium | 0.50ms | 0.47ms | 0.65ms |
| Large | 8.04ms | 8.02ms | 8.27ms |

## NSAttributedString(html:)

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 2.82ms | 1.78ms | 2.14ms |
| Medium | 6.80ms | 6.78ms | 7.27ms |
| Large | 119.91ms | 118.30ms | 127.87ms |

## Comparison (median)

| Size | HTMLParser | NSAttributedString | Speedup |
|------|-----------|-------------------|--------|
| Small | 0.06ms | 1.78ms | 29.0x |
| Medium | 0.47ms | 6.78ms | 14.5x |
| Large | 8.02ms | 118.30ms | 14.8x |

## Memory (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString |
|------|-----------|-------------------|
| Small | 0 B | 64.0 KB |
| Medium | 0 B | 48.0 KB |
| Large | 112.0 KB | 160.0 KB |

