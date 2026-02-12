# SwiftHTMLRenderer — Progress

## Реализовано

### Parser Module (2026-02-12)
- CGumbo — вендоренный C-парсер Gumbo v0.13.2 (Codeberg fork)
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
- Тесты: 22 теста (инстанциация, visitor, style configuration)

## Отложено на будущее

### Inline Collapsing
Inline-элементы (`<b>`, `<i>`, `<a>`, `<code>`) внутри блока схлопываются в один View через AttributedString. Сейчас каждый элемент — отдельный View. Оптимизация для производительности.

### Accessibility
Маппинг HTML-семантики в SwiftUI accessibility:
- Headings → accessibility heading trait
- Links → accessibility link trait
- Lists → accessibility-аннотации

### Images (`<img>`)
Async-загрузка, кеширование, placeholder, ресайз.

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
