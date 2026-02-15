# SwiftHTMLRenderer — Progress

## Реализовано

### Парсинг
- Парсер вынесен в отдельную библиотеку [swift-lexbor](https://github.com/AgapovOne/swift-lexbor)
- Рендерер импортирует `HTMLParser` из swift-lexbor (типы: `HTMLDocument`, `HTMLNode`, `HTMLElement`, `HTMLVisitor`)

### Рендеринг
- `HTMLView` — SwiftUI view из `HTMLDocument`
- `HTMLNodeView` — рендеринг отдельных nodes (для использования в кастомных рендерерах)
- Все элементы из SPEC.md: h1-h6, p, b/i/u/s, code, pre, blockquote, ul/ol, dl/dt/dd, table, hr, a, div, semantic containers
- Phrasing-элементы: mark, small, kbd, q, cite, ins, abbr
- Таблицы через SwiftUI `Grid` (без colspan/rowspan)
- Ссылки кликабельны всегда — через `onLinkTap` callback или `OpenURLAction`
- Неизвестные элементы — пропуск тега, рендеринг children

### Inline collapsing
- Phrasing content внутри блочных элементов схлопывается в один `Text` через `AttributedString`
- Ссылки внутри collapsed text используют `.link` атрибут и `OpenURLAction`
- Кастомный link block renderer отключает collapsing
- Inline-only кастомизации (tagInlineText, linkInlineText) сохраняют collapsing
- Whitespace-only text nodes фильтруются в block-контексте, сохраняются в inline

### Кастомизация
- Named renderers: heading, paragraph, link, list, listItem, blockquote, codeBlock, table, definitionList, unknownElement
- Tag-based renderers: htmlTag (block), htmlTagInlineText (inline), htmlTag с block + inline
- htmlSkipTag — пропуск тега
- Link inline text — кастомизация ссылок внутри inline collapsing
- Приоритет: named > tag block > tag inline > built-in > unknown
- Visitor protocol (из swift-lexbor) для обхода AST

### Accessibility
- Headings (h1-h6) → `.isHeader` trait
- Links с URL → `.isLink` trait

### Тесты
- ~65 тестов: инстанциация, inline collapsing, accessibility, visitor, named renderers, tag overrides, skip, приоритеты

## Запланировано

### Images (`<img>`)
AsyncImage нестабилен в глубоких view-иерархиях, inline collapsing несовместим с async-загрузкой. Подробнее: `docs/FAQ.md` → «Почему `<img>` отложен на post-v1?»

### Details/Summary
`<details>`, `<summary>` — раскрывающийся контент.

### CSS
Парсинг inline/embedded CSS. Атрибут `style` сохраняется как сырая строка — пока не интерпретируется.

### colspan/rowspan
Полная поддержка таблиц со слиянием ячеек.

### Дополнительные платформы
macOS, visionOS, watchOS.

### Performance benchmarks
Замер скорости рендеринга SwiftUI views.

## Известные ограничения

### Environment closures invalidation

`onLinkTap` и `nodeRenderClosure` хранятся в Environment как closures, которые не `Equatable`. При обновлении parent view SwiftUI инвалидирует все дочерние views, потому что не может доказать, что значение не изменилось. Для документа с 200 узлами — 200 views пересчитываются при каждом обновлении parent.

Для решения нужно определить, поддерживаем ли динамические closures (пользователь меняет `onLinkTap` между рендерами). Если нет — reference wrapper + `@State`. Если да — нужен механизм обновления.

### ForEach с \.offset

`ForEach(Array(children.enumerated()), id: \.offset)` — позиционный ID. `Array(enumerated())` аллоцируется при каждом вызове body. AST immutable, массивы не меняются, аллокация на 5-20 элементах — наносекунды. Пересмотреть, если AST станет мутируемым.

### AnyView в nodeRenderClosure

`nodeRenderClosure` возвращает `AnyView` для передачи рендеринга через Environment. Стирает тип, SwiftUI не оптимизирует diff. Используется только при рендеринге nodes из кастомных рендереров. Дефолтный путь — без AnyView.

### Пересчёт listItems/tableRows/tableCells

`compactMap`/`flatMap` при каждом вызове body. Immutable arrays, фильтрация 3-10 элементов — наносекунды.

### canCollapseInline без мемоизации

Рекурсивный обход при каждом рендере блочного элемента. Типичная глубина 2-4 уровня. Кэширование требует external state. Проблема только на патологическом HTML (100+ уровней вложенности).
