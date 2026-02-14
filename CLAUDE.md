# SwiftHTMLRenderer — Project Rules

## What This Is

Библиотека для парсинга HTML5 и рендеринга в SwiftUI views. Два независимых модуля: Parser и Renderer. Для rich-text контента из API, CMS, документации — не для рендеринга веб-страниц.

## Targets of library

- Скорость
- Качество (== Тестирование + расширяемый публичный интерфейс)
- Продуманное дефолтное поведение, доступное к расширению
- Простота использования

## Status

Библиотека в стадии активной разработки. Миграций нет, потому что нет пользователей. Обновления публичного интерфейса - норма, ведь мы на этапе проектирования.

## Architecture Decisions

### Parser

- **Lexbor** (v2.6.0, Apache 2.0) — HTML5-парсер. Вендорится в `Sources/CLexbor/` как C-таргет.
- Parser — обёртка: Lexbor парсит HTML, мы конвертируем результат в свой AST.
- Всё связанное с HTML-спецификацией (error recovery, entities, nesting rules) — ответственность Lexbor, не наша.

### AST

- Immutable value types (structs/enums). Не classes.
- `Equatable`, `Hashable`, `Sendable`.
- `HTMLDocument` → `[HTMLNode]`. `HTMLNode` — enum: `.element`, `.text`, `.comment`.
- `HTMLElement`: `tagName` (lowercase), `attributes: [String: String]`, `children: [HTMLNode]`.
- Boolean-атрибуты: `["disabled": "disabled"]`. `style` — сырая строка.

### Пропускаемые элементы

- `<script>`, `<style>` — пропускаются полностью с содержимым.
- CDATA, `<template>` — пропускаются.

### API

- Синхронный. Без throws. Без async. Без run loop.
- Thread-safe. Вызывается с любого потока.
- `HTMLParser.parse(_:)` — полный документ. `HTMLParser.parseFragment(_:)` — фрагмент.
- Кеширование и threading — ответственность пользователя.

### Renderer

- `HTMLView` — SwiftUI view из `HTMLDocument` или HTML-строки.
- Три уровня кастомизации: Style Config → ViewBuilder closures → Visitor protocol.
- Приоритет: ViewBuilder > StyleConfig > Default.
- Каждый элемент — отдельный View (без inline collapsing).
- Ссылки через `onLinkTap` callback. Без callback — стилизованный некликабельный текст.
- Неизвестные элементы — пропускаем тег, рендерим детей (+ `onUnknownElement` callback).
- Таблицы через SwiftUI `Grid` (без colspan/rowspan).

## Platform

- iOS 17+
- Swift 6.2, strict concurrency
- SPM only. Без CocoaPods/Carthage.

## Testing Strategy

### Sociable Tests

Стратегия: **sociable tests** (не solitary). Тестируем через публичный API, без моков.

- Вход: HTML-строка. Выход: утверждения об AST.
- Каждый тест проходит полный путь: `HTMLParser.parse()` → Lexbor → конвертер → AST.
- Lexbor и конвертер — не мокаются. Это внутренние коллабораторы, а не внешние зависимости.
- Тестируем поведение, а не реализацию. Замена Lexbor на другой парсер не должна ломать тесты.

```swift
// Правильно: тестируем через публичный API
let doc = HTMLParser.parseFragment("<p><b>bold</b></p>")
// assert на структуру doc

// Неправильно: тестируем internal конвертер напрямую
let node = LexborConverter.convert(lexborNode) // не делаем так
```

### What To Test

- Каждый поддерживаемый HTML-элемент из docs/SPEC.md (h1-h6, p, ul, ol, table, etc.).
- Фрагменты (без `<html><body>`).
- Невалидный HTML (error recovery).
- HTML entities (`&amp;`, `&#60;`, `&#x3C;`).
- Void elements (`<br>`, `<hr>`, `<img>`).
- Equatable: два одинаковых парсинга → равные AST.
- Hashable: одинаковые AST → одинаковый хеш.
- Пропускаемые элементы: `<script>`, `<style>` отсутствуют в AST.

### What NOT To Test

- Корректность Lexbor напрямую (это его тесты, не наши).
- Internal функции конвертера (тестируем только через публичный API).
- Конкретную реализацию конвертации (Lexbor-типы, C-указатели). Тесты привязаны к контракту, не к реализации.

### Benchmarks

- Отдельный SPM-пакет в `Benchmarks/`: `swift run --package-path Benchmarks -c release`.
- Три размера: small (<1 KB), medium (1-10 KB), large (50+ KB).
- Baseline: `NSAttributedString(html:)`.
- Метрики: среднее, медиана, p95 за 100 итераций. Прогрев: 10 итераций.
- `ContinuousClock` для замеров.

## Code Style

- Язык кода: English (имена типов, функций, переменных, комментарии).
- Язык документов: Russian (docs/, PRD, обсуждения).
- Минимум комментариев. Комментарий нужен только там, где код неочевиден.
- Без лишних абстракций. Три одинаковые строки лучше, чем преждевременная абстракция.

## Project Structure

```
Sources/
  CLexbor/          — Lexbor C sources (vendored, do not modify)
  HTMLParser/        — Swift parser module
  HTMLRenderer/      — SwiftUI renderer module
Tests/
  HTMLParserTests/   — Parser tests (22)
  HTMLRendererTests/ — Renderer tests (22)
Benchmarks/          — Performance benchmarks (executable target)
docs/                — SPEC.md, FAQ.md, PERFORMANCE.md, PROGRESS.md, etc.
ralph/               — Ralph PRDs and archive
```

## Documentation

Подробности — в документах:

- `docs/SPEC.md` — полная спецификация библиотеки (элементы, API, кастомизация)
- `docs/FAQ.md` — обоснования архитектурных решений
- `docs/PERFORMANCE.md` — стратегия бенчмаркинга
- `docs/PARSER_RESEARCH.md` — исследование и выбор парсера (Lexbor)
- `docs/BENCHMARK_RESULTS.md` — результаты бенчмарков
- `docs/PROGRESS.md` — прогресс и план на будущее

## Ralph

Когда работа выполняется с помощью ralph скрипта из claude, и используются prd.json, progress.txt и prd-*.md, то:
- Папка для всего - ralph/
- Предыдущие PRD положи в ralph/archive/* с названием PRD md документа
- Актуальные PRD и prd.json, progress.txt положи в ralph/
- При выполнении user story - делай коммиты по каждому user story
