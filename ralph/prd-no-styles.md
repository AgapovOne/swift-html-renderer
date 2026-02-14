# PRD: Удаление стилей и расширение HTMLTagRenderer

## Введение

Библиотека дублирует SwiftUI: `HTMLElementStyle` с 8 свойствами (font, foregroundColor, backgroundColor, padding, lineSpacing, cornerRadius, borderColor, borderWidth) — урезанная копия SwiftUI модификаторов. `HTMLStyleConfiguration` хранит 20 стилей для каждого типа элемента + 5 layout-значений. `applyStyle()` разворачивает эти свойства в цепочку `.font().foregroundStyle().background()...`.

ViewBuilder closures строго мощнее: любой SwiftUI модификатор, анимации, кастомные лейауты — без ограничений. Стили — лишний слой абстракции.

Вторая проблема: `HTMLTagRenderer` работает только для неизвестных тегов. Встроенные теги (`div`, `b`, `table`) перехватываются хардкод-switch раньше, чем проверяется `custom.tagRenderers`. Пользователь не может переопределить поведение встроенного тега.

## Цели

- Удалить `HTMLElementStyle`, `HTMLStyleConfiguration`, `applyStyle()`
- Захардкодить дефолтный рендеринг прямо в функциях рендеринга
- Расширить `HTMLTagRenderer`: переопределять встроенные теги (не только unknown)
- Добавить skip-механизм через `HTMLTagRenderer`
- Сохранить обратную совместимость ContentBuilder API
- AnyView скрыт от публичного API (внутри — допустим)

## Не в скоупе

- Публичная структура InlineStyles — остаётся internal
- Вложенные TagMap / множественные конфигурации
- `<a>` как block-тег (только inline, block через HTMLLinkRenderer)
- Бенчмарки

## User Stories

### US-001: Удалить HTMLElementStyle и applyStyle()

**Описание:** Удалить `HTMLElementStyle`, extension `applyStyle()` и все их использования.

**Контекст:**

Удалить из `HTMLStyleConfiguration.swift`:
- `HTMLElementStyle` struct (строки 60-89)

Удалить из `HTMLView.swift`:
- Extension `View.applyStyle()` (строки 556-593)
- Все 17 вызовов `applyStyle()` в рендеринг-функциях

Вместо `applyStyle()` — прямые SwiftUI модификаторы в каждой рендеринг-функции (см. US-003).

**Acceptance Criteria:**
- [ ] `HTMLElementStyle` struct удалён
- [ ] `applyStyle()` extension удалён
- [ ] Нет компиляционных ошибок от удаления
- [ ] Typecheck проходит

---

### US-002: Удалить HTMLStyleConfiguration и environment

**Описание:** Удалить `HTMLStyleConfiguration`, environment key, параметр `configuration` из `HTMLView.init`.

**Контекст:**

Удалить из `HTMLStyleConfiguration.swift`:
- `HTMLStyleConfiguration` struct целиком (строки 93-210)

Удалить из `HTMLView.swift`:
- `StyleConfigurationKey` environment key (строки 14-16)
- `EnvironmentValues.styleConfiguration` (строки 33-36)
- `@Environment(\.styleConfiguration) private var config` из `ElementRenderer` (строка 140)
- Параметр `configuration: HTMLStyleConfiguration = .default` из обоих `HTMLView.init` (строки 55, 68)
- `private let configuration: HTMLStyleConfiguration` (строка 48)
- `.environment(\.styleConfiguration, configuration)` (строка 88)

`ListNumberFormat` enum оставить — используется в захардкоженном рендеринге списков.

**Acceptance Criteria:**
- [ ] `HTMLStyleConfiguration` struct удалён
- [ ] Environment key и property удалены
- [ ] `HTMLView.init` без параметра `configuration`
- [ ] `ListNumberFormat` сохранён
- [ ] Typecheck проходит

---

### US-003: Захардкодить дефолтный рендеринг

**Описание:** Заменить все обращения к `config.*` на хардкод SwiftUI модификаторов.

**Контекст:**

Таблица замен:

| Элемент | Было | Стало |
|---------|------|-------|
| h1 | `config.heading1` → applyStyle | `.font(.largeTitle)` |
| h2 | `config.heading2` → applyStyle | `.font(.title)` |
| h3 | `config.heading3` → applyStyle | `.font(.title2)` |
| h4 | `config.heading4` → applyStyle | `.font(.title3)` |
| h5 | `config.heading5` → applyStyle | `.font(.headline)` |
| h6 | `config.heading6` → applyStyle | `.font(.subheadline)` |
| p | `config.paragraph` → applyStyle | `.font(.body)` (или без модификатора — body по дефолту) |
| b/strong | `.applyStyle(config.bold)` | ничего (`.bold()` уже есть) |
| i/em | `.applyStyle(config.italic)` | ничего (`.italic()` уже есть) |
| u | `.applyStyle(config.underline)` | ничего (`.underline()` уже есть) |
| s/del | `.applyStyle(config.strikethrough)` | ничего |
| code | `.applyStyle(config.code)` | ничего (`.monospaced()` уже есть) |
| mark | `.applyStyle(config.mark)` | `.background(Color.yellow.opacity(0.3))` |
| small | `.applyStyle(config.small)` | `.font(.caption)` |
| kbd | сложная логика с config | `.font(.system(.body, design: .monospaced)).padding(EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3)).overlay { RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1) }` |
| blockquote | config + applyStyle | `.padding(.leading, 16).overlay(alignment: .leading) { Rectangle().frame(width: 3).foregroundStyle(Color.accentColor) }` |
| pre | config + applyStyle | `.font(.system(.body, design: .monospaced)).padding(8).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))` |
| link | `config.link.foregroundColor` | `.foregroundStyle(.blue)` |
| table header | `config.tableHeader` → applyStyle | `.bold()` (уже есть) |
| table cell | `config.tableCell` → applyStyle | ничего |
| list item | `config.listItem` → applyStyle | ничего |

Layout-значения — константы:
- `blockSpacing` → `8` (inline в VStack)
- `listSpacing` → `4` (inline в VStack)
- `listMarkerSpacing` → `6` (inline в HStack)
- `bulletMarker` → `"•"` (inline в Text)
- `listNumberFormat` → `.decimal` (inline)

`renderWithInlineCollapsing()` — упрощённая сигнатура:
```swift
@ViewBuilder
private func renderWithInlineCollapsing(
    _ children: [HTMLNode]? = nil,
    baseFont: Font = .body
) -> some View {
    let nodes = children ?? element.children
    if canCollapseInline(nodes, customRenderers: custom) {
        buildInlineText(nodes, customRenderers: custom, onLinkTap: onLinkTap, baseFont: baseFont)
    } else if children != nil {
        VStack(alignment: .leading) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { _, child in
                NodeRenderer(node: child, blockContext: true)
            }
        }
    } else {
        renderChildren()
    }
}
```

Caller'ы применяют SwiftUI модификаторы сами:
```swift
// Heading
renderWithInlineCollapsing(baseFont: .largeTitle)
    .font(.largeTitle)
    .accessibilityAddTraits(.isHeader)

// Paragraph — body is default, no modifier needed
renderWithInlineCollapsing()
```

`headingStyle(for:)` → упростить до маппинга level → Font:
```swift
private func headingFont(for level: Int) -> Font {
    switch level {
    case 1: .largeTitle
    case 2: .title
    case 3: .title2
    case 4: .title3
    case 5: .headline
    default: .subheadline
    }
}
```

`buildInlineText()` — убрать параметр `config`:
- Захардкодить `config.link.foregroundColor ?? .blue` → `.blue`
- Убрать `config` из всех вызовов `buildInlineText`, `buildNodeText`, `buildElementText`

**Acceptance Criteria:**
- [ ] Все обращения к `config.*` заменены на хардкод
- [ ] `renderWithInlineCollapsing()` без параметра `style`
- [ ] `headingStyle(for:)` → `headingFont(for:)` возвращает `Font`
- [ ] `buildInlineText()` без параметра `config`
- [ ] Layout-значения захардкожены
- [ ] Визуальный результат идентичен текущему
- [ ] Typecheck проходит
- [ ] Тесты проходят

---

### US-004: HTMLTagRenderer переопределяет встроенные теги

**Описание:** Изменить приоритет рендеринга: `custom.tagRenderers` и `custom.tagInlineText` проверяются ДО встроенного switch.

**Контекст:**

Текущий приоритет в `ElementRenderer.body`:
1. Named renderers (heading, paragraph, link...) — приоритет
2. Встроенный switch (хардкод div, b, table...)
3. `custom.tagRenderers[tagName]` — только unknown

Новый приоритет:
1. Named renderers (heading, paragraph, link...) — приоритет
2. **`custom.tagRenderers[tagName]`** — переопределяет встроенный тег
3. **`custom.tagInlineText[tagName]`** — делает тег inline
4. Встроенный switch — фолбэк
5. Unknown element handler

Изменения в `ElementRenderer.body`:

```swift
var body: some View {
    // 1. Named renderers — приоритет
    if let view = renderNamedElement() {
        view
    }
    // 2. Custom tag renderers — переопределение встроенных
    else if let tagRenderer = custom.tagRenderers[element.tagName] {
        tagRenderer(element.children, element.attributes)
    }
    // 3. Custom inline text — тег становится inline
    else if custom.tagInlineText[element.tagName] != nil {
        renderInlineElement()
    }
    // 4. Встроенный switch — фолбэк
    else {
        renderBuiltInElement()
    }
}
```

`renderNamedElement()` — выносит проверку named renderers:
```swift
@ViewBuilder
private func renderNamedElement() -> AnyView? {
    // Проверяет custom.heading для h1-h6, custom.paragraph для p,
    // custom.link для a, etc.
    // Возвращает nil если нет named renderer
}
```

Альтернатива (проще): оставить switch, но добавить проверку tagRenderers в начало каждого case. Или вынести в отдельную проверку перед switch:

```swift
var body: some View {
    if let rendered = renderWithCustomOverride() {
        rendered
    } else {
        renderDefault()
    }
}

@ViewBuilder
private func renderWithCustomOverride() -> AnyView? {
    // Named renderers
    switch element.tagName {
    case "h1"..."h6":
        if let heading = custom.heading { ... }
    case "p":
        if let paragraph = custom.paragraph { ... }
    ...
    default: break
    }

    // Tag renderers (overrides built-in)
    if let tagRenderer = custom.tagRenderers[element.tagName] {
        return tagRenderer(element.children, element.attributes)
    }

    return nil
}
```

Конкретная реализация — на усмотрение разработчика. Главное: `custom.tagRenderers` проверяется РАНЬШЕ встроенного switch для ВСЕХ тегов.

Примеры использования:
```swift
// Переопределить div: вместо VStack — HStack
HTMLTagRenderer("div") { children, attrs in
    HStack { HTMLNodeView(nodes: children) }
}

// Переопределить b: вместо bold — italic
HTMLTagRenderer("b", inlineText: { text, _ in text.italic() })

// Сделать div inline
HTMLTagRenderer("div", inlineText: { text, _ in text })

// Сделать span block
HTMLTagRenderer("span") { children, _ in
    VStack { HTMLNodeView(nodes: children) }
}
```

**Acceptance Criteria:**
- [ ] `custom.tagRenderers[tagName]` проверяется перед встроенным switch
- [ ] Named renderers (heading, paragraph, link...) — приоритет выше tagRenderers
- [ ] `HTMLTagRenderer("div") { ... }` переопределяет встроенный div
- [ ] `HTMLTagRenderer("b", inlineText: { ... })` переопределяет встроенный bold
- [ ] `custom.tagInlineText[tagName]` делает block-тег inline (коллапсируется в Text)
- [ ] Тег без override → встроенный рендеринг (текущий switch)
- [ ] Без tagRenderers → текущее поведение
- [ ] Typecheck проходит

---

### US-005: canCollapseInline учитывает tagRenderers

**Описание:** `canCollapseInline()` должен знать о переопределённых тегах: block-рендерер блокирует collapsing, inline-рендерер разрешает.

**Контекст:**

Текущая логика `canCollapseInline()`:
- `phrasingTags.contains(tagName)` → inline
- `custom.tagInlineText[tagName]` → inline
- Всё остальное → block (return false)

Новая логика:
```swift
func canCollapseInline(
    _ children: [HTMLNode],
    customRenderers: HTMLCustomRenderers = HTMLCustomRenderers()
) -> Bool {
    // Link renderer check (без изменений)
    if customRenderers.link != nil && customRenderers.linkInlineText == nil {
        if containsTag("a", in: children) { return false }
    }

    return children.allSatisfy { node in
        switch node {
        case .text, .comment: return true
        case .element(let el):
            // 1. tagInlineText — явно inline (приоритет)
            if customRenderers.tagInlineText[el.tagName] != nil {
                return canCollapseInline(el.children, customRenderers: customRenderers)
            }
            // 2. tagRenderers — явно block (блокирует collapsing)
            if customRenderers.tagRenderers[el.tagName] != nil {
                return false
            }
            // 3. Встроенные phrasing tags
            if phrasingTags.contains(el.tagName) {
                return canCollapseInline(el.children, customRenderers: customRenderers)
            }
            return false
        }
    }
}
```

Приоритет: `tagInlineText` > `tagRenderers` > `phrasingTags`.

Если тег есть И в tagInlineText, И в tagRenderers — tagInlineText побеждает (тег inline). Это логично: если пользователь дал и block, и inline вариант, при inline collapsing используется inline.

**Acceptance Criteria:**
- [ ] `tagInlineText[tag]` → тег collapsable (inline)
- [ ] `tagRenderers[tag]` (без tagInlineText) → тег НЕ collapsable (block)
- [ ] `phrasingTags` → тег collapsable (если нет override)
- [ ] `tagInlineText` приоритет выше `tagRenderers` при определении inline/block
- [ ] Без custom renderers → текущее поведение
- [ ] Typecheck проходит

---

### US-006: buildElementText учитывает tagInlineText для встроенных тегов

**Описание:** `buildElementText()` должен проверять `tagInlineText` ДО встроенного switch, чтобы переопределённый inline-рендеринг работал для встроенных тегов.

**Контекст:**

Сейчас `custom.tagInlineText` проверяется в `default` case — только для неизвестных тегов. Встроенные теги (`b`, `code`, `mark`) перехватываются switch раньше.

Изменение: проверить `tagInlineText` В НАЧАЛЕ `buildElementText()`, перед switch:

```swift
private func buildElementText(
    _ element: HTMLElement,
    parentStyles: InlineStyles,
    customRenderers: HTMLCustomRenderers,
    onLinkTap: (@MainActor @Sendable (URL, HTMLElement) -> Void)?,
    baseFont: Font
) -> Text {
    // Custom inline override — приоритет для всех тегов кроме <a>
    // (<a> обрабатывается отдельно из-за linkInlineText)
    if element.tagName != "a",
       let tagInline = customRenderers.tagInlineText[element.tagName] {
        let childText = buildInlineText(
            element.children, styles: parentStyles,
            customRenderers: customRenderers, onLinkTap: onLinkTap, baseFont: baseFont
        )
        return tagInline(childText, element.attributes)
    }

    var styles = parentStyles
    switch element.tagName {
    // ... текущий switch без изменений
    }
}
```

Исключение для `<a>`: `custom.linkInlineText` приоритет выше `tagInlineText["a"]`. Если нужен `tagInlineText["a"]`, linkInlineText не должен быть задан.

**Acceptance Criteria:**
- [ ] `tagInlineText["b"]` переопределяет встроенный bold inline рендеринг
- [ ] `tagInlineText["code"]` переопределяет встроенный code inline рендеринг
- [ ] `linkInlineText` приоритет выше `tagInlineText["a"]`
- [ ] Без tagInlineText → текущий switch без изменений
- [ ] Typecheck проходит

---

### US-007: Skip через HTMLTagRenderer

**Описание:** Добавить статический метод `HTMLTagRenderer.skip()` для пропуска тега (рендер children без обёртки тега).

**Контекст:**

Два варианта "пропуска":

1. **Skip тег, рендерить children** — `HTMLTagRenderer.skip("table")`. Тег пропускается, но его дети рендерятся (как unknown element). `onUnknownElement` callback срабатывает.

2. **Скрыть тег полностью** — `HTMLTagRenderer("table") { _, _ in EmptyView() }`. Ничего не рендерится.

Реализация skip:
```swift
extension HTMLTagRenderer {
    /// Пропустить тег — рендерить children без обёртки тега (как unknown element).
    public static func skip(_ tagName: String) -> HTMLTagRenderer {
        HTMLTagRenderer(tagName) { children, _ in
            HTMLNodeView(nodes: children)
        }
    }
}
```

`HTMLNodeView` уже публичный и принимает `[HTMLNode]`. Children рендерятся стандартным рендерером.

Для полного скрытия — пользователь пишет сам:
```swift
HTMLTagRenderer("table") { _, _ in EmptyView() }
```

**Acceptance Criteria:**
- [ ] `HTMLTagRenderer.skip("table")` — table рендерится как children
- [ ] `HTMLTagRenderer("table") { _, _ in EmptyView() }` — ничего не рендерится
- [ ] Skip работает для встроенных тегов (div, table, blockquote...)
- [ ] Typecheck проходит

---

### US-008: Обновить тесты

**Описание:** Обновить тесты: удалить style-тесты, добавить тесты TagRenderer override.

**Контекст:**

Удалить тесты:
- `defaultConfigurationHasHeading1Font`
- `defaultConfigurationHasPreformattedCornerRadius`
- `defaultConfigurationHasBlockquoteBorderWidth`
- `customCornerRadiusAndBorder`
- `preWithCustomCornerRadius`
- `blockquoteWithCustomBorder`
- `defaultConfigurationHasLayoutDefaults`
- `customLayoutValuesApplied`
- `defaultConfigurationHasMarkStyle`
- `defaultConfigurationHasSmallStyle`
- `defaultConfigurationHasKeyboardStyle`

Обновить тесты (убрать параметр `configuration`):
- Все тесты, использующие `HTMLView(document:, configuration:)` — убрать `configuration:`

Добавить тесты:

```swift
// TagRenderer переопределяет встроенный тег
@MainActor @Test func tagRendererOverridesBuiltInDiv() {
    let view = HTMLView(document: HTMLParser.parseFragment("<div>content</div>")) {
        HTMLTagRenderer("div") { children, _ in
            HStack { HTMLNodeView(nodes: children) }
        }
    }
    _ = view
}

// TagRenderer inline переопределяет встроенный bold
@MainActor @Test func tagRendererInlineOverridesBuiltInBold() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p><b>text</b></p>")) {
        HTMLTagRenderer("b", inlineText: { text, _ in text.italic() })
    }
    _ = view
}

// Skip встроенного тега
@MainActor @Test func tagRendererSkipTable() {
    let view = HTMLView(document: HTMLParser.parseFragment("<table><tr><td>cell</td></tr></table>")) {
        HTMLTagRenderer.skip("table")
    }
    _ = view
}

// Block-тег становится inline
@MainActor @Test func tagRendererMakesDivInline() {
    let view = HTMLView(document: HTMLParser.parseFragment("<p>text <div>inline</div> more</p>")) {
        HTMLTagRenderer("div", inlineText: { text, _ in text })
    }
    _ = view
}

// Inline-тег становится block
@MainActor @Test func tagRendererMakesSpanBlock() {
    let view = HTMLView(document: HTMLParser.parseFragment("<span>content</span>")) {
        HTMLTagRenderer("span") { children, _ in
            VStack { HTMLNodeView(nodes: children) }.background(.blue)
        }
    }
    _ = view
}

// Named renderer приоритет выше tagRenderer
@MainActor @Test func namedRendererPriorityOverTagRenderer() {
    let view = HTMLView(document: HTMLParser.parseFragment("<h1>heading</h1>")) {
        HTMLHeadingRenderer { children, level, _ in
            Text("Custom H\(level)")
        }
        HTMLTagRenderer("h1") { children, _ in
            Text("Should not be used")
        }
    }
    _ = view
}
```

**Acceptance Criteria:**
- [ ] Style-тесты удалены
- [ ] Существующие тесты обновлены (без config параметра)
- [ ] Новые тесты добавлены для tag override, skip, inline/block override, priority
- [ ] Все тесты проходят
- [ ] Typecheck проходит

## Функциональные требования

- FR-1: `HTMLElementStyle` и `HTMLStyleConfiguration` удалены
- FR-2: Дефолтный рендеринг захардкожен в функциях рендеринга
- FR-3: `HTMLTagRenderer` переопределяет встроенные теги (не только unknown)
- FR-4: `HTMLTagRenderer.skip()` — пропуск тега (render children)
- FR-5: Приоритет: Named renderer > TagRenderer > Встроенный рендеринг > Unknown
- FR-6: `tagInlineText` делает block-тег inline (коллапсируется в Text)
- FR-7: `tagRenderers` делает inline-тег block (блокирует collapsing)
- FR-8: `canCollapseInline()` учитывает tagRenderers и tagInlineText
- FR-9: `buildElementText()` проверяет tagInlineText перед встроенным switch
- FR-10: Обратная совместимость ContentBuilder API (HTMLHeadingRenderer, HTMLParagraphRenderer, etc.)
- FR-11: AnyView не в публичном API (внутри — допустим)

## Технические ограничения

- Swift 6.2 strict concurrency
- iOS 17+ minimum deployment target
- `ListNumberFormat` enum сохранён (используется в рендеринге)
- `ifLet` helper на View сохранён (может пригодиться)
- `onUnknownElement` callback сохранён (возвращает `AnyView` — внутренний API)

## Порядок реализации

US-001 → US-002 → US-003 → US-004 → US-005 → US-006 → US-007 → US-008

US-001..003 — удаление стилей (одна смысловая группа).
US-004..006 — расширение TagRenderer (вторая группа).
US-007 — skip.
US-008 — тесты (после всех изменений).

## Метрики успеха

- `HTMLView.init` без параметра `configuration` — проще API
- Дефолтный рендеринг визуально идентичен текущему
- `HTMLTagRenderer("div") { ... }` переопределяет встроенный div
- `HTMLTagRenderer("b", inlineText: { ... })` переопределяет встроенный bold
- Существующие тесты проходят (после обновления)
