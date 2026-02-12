# Benchmark Report

Date: 2026-02-12 08:52:26

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
| Small | 0.09ms | 0.09ms | 0.09ms |
| Medium | 0.48ms | 0.46ms | 0.59ms |
| Large | 7.49ms | 7.50ms | 7.63ms |

## NSAttributedString(html:)

| Size | Avg | Median | P95 |
|------|-----|--------|-----|
| Small | 2.37ms | 1.56ms | 1.81ms |
| Medium | 5.84ms | 5.82ms | 6.10ms |
| Large | 107.00ms | 106.87ms | 109.92ms |

## Comparison (median)

| Size | HTMLParser | NSAttributedString | Speedup |
|------|-----------|-------------------|--------|
| Small | 0.09ms | 1.56ms | 17.4x |
| Medium | 0.46ms | 5.82ms | 12.7x |
| Large | 7.50ms | 106.87ms | 14.3x |

## Memory (resident size delta, 10 parses)

| Size | HTMLParser | NSAttributedString |
|------|-----------|-------------------|
| Small | 0 B | 32.0 KB |
| Medium | 0 B | 48.0 KB |
| Large | 32.0 KB | 64.0 KB |

