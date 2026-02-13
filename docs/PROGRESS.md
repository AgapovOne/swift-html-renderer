# SwiftHTMLRenderer — Progress

## Реализовано

### Parser Module (2026-02-12)
- CLexbor — вендоренный C-парсер Lexbor v2.6.0
- AST типы: `HTMLDocument`, `HTMLNode`, `HTMLElement` — immutable, Equatable, Hashable, Sendable
- `HTMLParser.parse()` — полный документ
- `HTMLParser.parseFragment()` — фрагмент без html/body обёрток
- Пропуск `<script>`, `<style>`, CDATA, template
- `HTMLVisitor` protocol — произвольный обход AST с `associatedtype Result`
- Тесты: 22 sociable tests через публичный API
- Бенчмарки: 12–17x быстрее NSAttributedString(html:)

### Renderer Module (2026-02-12)
- `HTMLView` — SwiftUI view из `HTMLDocument` или HTML-строки
- Все элементы из SPEC.md: h1-h6, p, b/i/u/s, code, pre, blockquote, ul/ol, table, hr, a, div, semantic containers
- Таблицы через SwiftUI `Grid` (без colspan/rowspan)
- Ссылки через `onLinkTap` callback
- Неизвестные элементы — пропуск тега, рендеринг children (+ `onUnknownElement` callback)
- `HTMLStyleConfiguration` — шрифты, цвета, отступы для каждого элемента
- ViewBuilder closures через `@HTMLContentBuilder` — кастомные views для элементов
- Приоритет: ViewBuilder > StyleConfig > Default

### Inline Collapsing (2026-02-12)
- Inline-элементы (`<b>`, `<i>`, `<a>`, `<code>`, `<sub>`, `<sup>`, `<br>`) внутри p, h1-h6, li, td, th, figcaption схлопываются в один `Text` через `AttributedString`
- Ссылки с `onLinkTap` внутри collapsed text используют `.link` атрибут и `OpenURLAction`
- Наличие кастомного link-рендерера отключает collapsing — переключение на separate views
- Whitespace-only text nodes фильтруются в block-контексте, сохраняются в inline

### Accessibility (2026-02-12)
- Headings (h1-h6) → `.isHeader` trait
- Links с `onLinkTap` → `.isLink` trait

### Тесты (2026-02-12)
- Parser: 22 sociable tests
- Renderer: 33 теста (инстанциация, inline collapsing, accessibility, visitor, style configuration)
- Всего: 55 тестов

## Отложено на будущее

### Images (`<img>`)
Попытка реализации выявила проблемы: AsyncImage нестабилен в глубоких view-иерархиях, inline collapsing несовместим с async-загрузкой. Подробнее: `docs/FAQ.md` → «Почему `<img>` отложен на post-v1?»

### CSS
Парсинг inline/embedded CSS. Атрибут `style` сохраняется как сырая строка — пока не интерпретируется.

### Details/Summary
`<details>`, `<summary>` — раскрывающийся контент.

### colspan/rowspan
Полная поддержка таблиц со слиянием ячеек.

### Дополнительные платформы
macOS, visionOS, watchOS.

### Performance Benchmarks рендерера
Замер скорости рендеринга SwiftUI views.

### Streaming/Incremental Parsing
Парсинг по частям для больших документов.
