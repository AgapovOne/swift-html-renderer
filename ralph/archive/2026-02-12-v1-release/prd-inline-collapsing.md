# PRD: Inline Collapsing + Root VStack Cleanup

## Introduction

Инлайн-элементы (`<b>`, `<i>`, `<code>` и др.) внутри блочных контейнеров (`<p>`, `<h1>`-`<h6>`, `<li>`, `<td>`) рендерятся как отдельные View в VStack. Визуально — столбик слов вместо абзаца.

`<p>Each <b>element</b> <i>type</i> via <code>code</code>.</p>` рендерится как 5 строк вместо одной.

Решение: схлопывать инлайн-контент в один `Text` через SwiftUI Text-конкатенацию (`+`). Дополнительно — убрать навязанные spacing/alignment из корневого VStack в HTMLView.

## Goals

- Инлайн-элементы внутри блочных контейнеров собираются в один `Text`
- Визуально `<p>Text <b>bold</b> text</p>` — единый абзац, не столбик
- Ссылки внутри collapsed-текста кликабельны через `AttributedString.link`
- Корневой контейнер HTMLView — прозрачный `Group`, не навязывает layout
- Fallback на separate views если есть блочный элемент или кастомный ViewBuilder

## User Stories

### US-001: Заменить корневой VStack на Group

**Description:** Как пользователь библиотеки, я хочу чтобы HTMLView не навязывал layout, а я сам оборачивал его в нужный контейнер (VStack, LazyVStack, ScrollView).

**Acceptance Criteria:**
- [ ] `HTMLView.body` использует `Group` вместо `VStack(alignment: .leading, spacing: 8)`
- [ ] Дети HTMLView вытекают в родительский контейнер пользователя
- [ ] Блочные элементы (div, article, section, blockquote, pre, ul, ol, figure) сами задают свой spacing и alignment внутри своих рендереров
- [ ] `swift build` собирается без ошибок
- [ ] `swift test` проходит

### US-002: Inline collapsing для `<p>` и `<h1>`-`<h6>`

**Description:** Как пользователь библиотеки, я хочу чтобы `<p>Each <b>element</b> <i>type</i></p>` рендерился как единый абзац.

**Acceptance Criteria:**
- [ ] Новый файл `InlineTextBuilder.swift` с функциями `canCollapseInline` и `buildInlineText`
- [ ] `canCollapseInline` проверяет что все дети — phrasing content (text, comment, или element с тегом из списка: b, strong, i, em, u, s, del, code, span, sub, sup, a, br)
- [ ] `buildInlineText` рекурсивно обходит детей и собирает один `Text` через конкатенацию (`+`)
- [ ] Поддержанные Text-модификаторы: `.bold()`, `.italic()`, `.underline()`, `.strikethrough()`, `.monospaced()`, `.foregroundColor()`, `.font()`, `.baselineOffset()`
- [ ] `<br>` → `Text("\n")`
- [ ] `<sub>` → `.font(.caption2).baselineOffset(-4)`
- [ ] `<sup>` → `.font(.caption2).baselineOffset(8)`
- [ ] `<span>` → контейнер без стилей, рендерит children
- [ ] Вложенные стили: `<b><i>bold italic</i></b>` — применяются оба модификатора
- [ ] В `ElementRenderer` для `p` и `h1`-`h6`: если `canCollapseInline` → `buildInlineText`, иначе → `renderChildren()` (fallback)
- [ ] Приоритет: custom ViewBuilder > inline collapsing > renderChildren fallback
- [ ] Block-level стили (`.applyStyle(config.paragraph, defaultFont: .body)`) применяются к результату `buildInlineText`
- [ ] `swift build` собирается без ошибок
- [ ] `swift test` проходит

### US-003: Ссылки в collapsed inline тексте

**Description:** Как пользователь библиотеки, я хочу чтобы `<a>` внутри параграфа были кликабельными даже в collapsed-режиме.

**Acceptance Criteria:**
- [ ] `<a href="...">` внутри collapsed текста — стилизуется (подчёркивание + цвет из `config.link`)
- [ ] Если `onLinkTap` задан — создаётся `AttributedString` с `.link = url` для сегмента ссылки
- [ ] `OpenURLAction` в environment перехватывает клики и вызывает `onLinkTap`
- [ ] Если `onLinkTap` не задан — `.link` не ставится, текст стилизованный но не кликабельный
- [ ] Если для `<a>` задан кастомный ViewBuilder (`custom.link != nil`) — `canCollapseInline` возвращает `false`, fallback на separate views
- [ ] `swift build` собирается без ошибок
- [ ] `swift test` проходит

### US-004: Inline collapsing для `<li>`, `<td>`, `<th>`, `<figcaption>`

**Description:** Как пользователь библиотеки, я хочу чтобы инлайн-контент внутри ячеек таблицы, элементов списка и figcaption тоже схлопывался.

**Acceptance Criteria:**
- [ ] `renderListItemContent` — если `canCollapseInline` → `buildInlineText`, иначе → VStack с ForEach
- [ ] Рендеринг ячеек таблицы (`td`, `th`) — аналогичная ветка
- [ ] `figcaption` — аналогичная ветка
- [ ] `swift build` собирается без ошибок
- [ ] `swift test` проходит

### US-005: Тесты inline collapsing

**Description:** Как разработчик библиотеки, я хочу покрыть inline collapsing тестами.

**Acceptance Criteria:**
- [ ] Тест: `<p>Text <b>bold</b> text</p>` — view создаётся без краша
- [ ] Тест: `<p><b><i>bold italic</i></b></p>` — вложенные инлайн-элементы
- [ ] Тест: `<p>line1<br>line2</p>` — br внутри параграфа
- [ ] Тест: `<p>Visit <a href="https://example.com">site</a></p>` — ссылка внутри параграфа
- [ ] Тест: `<p>Use <code>func</code> keyword</p>` — code внутри параграфа
- [ ] Тест: `<p>H<sub>2</sub>O and x<sup>2</sup></p>` — sub/sup
- [ ] Тест: `<h1>Title with <b>bold</b></h1>` — heading с инлайн-элементами
- [ ] Тест: `<li>Item with <b>bold</b></li>` — list item с инлайн-элементами
- [ ] `swift test` проходит

## Functional Requirements

- FR-1: Корневой контейнер в `HTMLView.body` — `Group` (прозрачный, не навязывает layout)
- FR-2: Блочные элементы сами задают свой spacing и alignment
- FR-3: `canCollapseInline` определяет можно ли схлопнуть children в один Text
- FR-4: `buildInlineText` рекурсивно собирает `Text` через конкатенацию
- FR-5: Phrasing content: b, strong, i, em, u, s, del, code, span, sub, sup, a, br
- FR-6: Стили накапливаются при вложенности: `<b><i>` → bold + italic
- FR-7: Ссылки в collapsed-режиме — `AttributedString.link` + `OpenURLAction`
- FR-8: `canCollapseInline` возвращает `false` если есть блочный элемент среди детей
- FR-9: `canCollapseInline` возвращает `false` если есть `<a>` и `custom.link != nil`
- FR-10: Приоритет: custom ViewBuilder > inline collapsing > renderChildren

## Non-Goals

- Кастомные ViewBuilder для инлайн-элементов (b, i, u, code) — отдельная итерация
- `backgroundColor`/`padding` для инлайн-элементов в collapsed-режиме (Text-модификаторы их не поддерживают)
- Inline collapsing для `<pre>` (там whitespace-sensitive контент, отдельная логика)

## Technical Considerations

### Text-конкатенация в SwiftUI

```swift
Text("Each ") + Text("element").bold() + Text(" ") + Text("type").italic()
```

Модификаторы `.bold()`, `.italic()`, `.underline()`, `.strikethrough()`, `.monospaced()`, `.foregroundColor()`, `.font()`, `.baselineOffset()` возвращают `Text` (не `some View`), поэтому совместимы с конкатенацией.

### InlineStyles — накопитель стилей

```swift
struct InlineStyles {
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var isStrikethrough = false
    var isMonospaced = false
    var isSubscript = false
    var isSuperscript = false
    var foregroundColor: Color? = nil
    var linkURL: URL? = nil
}
```

Передаётся по значению при рекурсии. Каждый тег добавляет свой флаг.

### Ссылки через AttributedString

```swift
if let url = styles.linkURL, onLinkTap != nil {
    var attributed = AttributedString(string)
    attributed.link = url
    attributed.foregroundColor = .blue  // UIColor bridge
    attributed.underlineStyle = .single
    return Text(attributed)
}
```

На родительском View:
```swift
.environment(\.openURL, OpenURLAction { url in
    onLinkTap?(url)
    return .handled
})
```

### Ограничение: backgroundColor для inline code

В collapsed-режиме `config.code.backgroundColor` и `config.code.padding` не применяются. Только font, foregroundColor, текстовые декорации. Это документированное ограничение.

### Структура файлов

```
Sources/HTMLRenderer/
  HTMLView.swift                — изменения в ElementRenderer
  InlineTextBuilder.swift       — новый файл
  HTMLStyleConfiguration.swift  — без изменений
  HTMLContentBuilder.swift      — без изменений
Tests/HTMLRendererTests/
  HTMLRendererTests.swift        — новые тесты
```

## Success Metrics

- `<p>Each <b>element</b> <i>type</i> via <code>code</code>.</p>` рендерится как единый абзац
- Все существующие тесты проходят
- `swift build` без ошибок и предупреждений
- DemoApp `Experiments.swift` визуально корректен

## Open Questions

- Нет открытых вопросов
