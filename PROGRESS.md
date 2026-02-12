# SwiftHTMLRenderer — Progress

## Реализовано

### Parser Module
- CGumbo — вендоренный C-парсер Gumbo v0.13.2 (Codeberg fork)
- AST типы: `HTMLDocument`, `HTMLNode`, `HTMLElement` — immutable, Equatable, Hashable, Sendable
- `HTMLParser.parse()` — полный документ
- `HTMLParser.parseFragment()` — фрагмент без html/body обёрток
- Пропуск `<script>`, `<style>`, CDATA, template
- Тесты: sociable tests через публичный API
- Бенчмарки: сравнение с NSAttributedString(html:)

## В работе

### Renderer Module (PRD: `scripts/ralph/prd-renderer-module.md`)
- `HTMLView` — SwiftUI view из AST
- Дефолтный рендеринг всех элементов из SPEC.md
- Style Configuration — шрифты, цвета, отступы
- ViewBuilder closures — кастомные views для элементов
- Visitor protocol — произвольный обход AST
- Таблицы через SwiftUI Grid
- Ссылки через callback

## Отложено на будущее

### Inline Collapsing
Inline-элементы (`<b>`, `<i>`, `<a>`, `<code>` и др.) внутри блока схлопываются в один View через AttributedString. Сейчас каждый элемент — отдельный View. Оптимизация для производительности при большом количестве inline-элементов.

### Accessibility
Базовый маппинг HTML-семантики в SwiftUI accessibility:
- Headings → accessibility heading trait
- Links → accessibility link trait
- Lists → accessibility-аннотации

### Images (`<img>`)
Async-загрузка, кеширование, placeholder, ресайз. Отдельная фича.

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
