# PRD: Улучшение кастомизации и расширение возможностей HTMLRenderer

## Introduction

HTMLRenderer предоставляет три уровня кастомизации: StyleConfig, ViewBuilder closures, Visitor protocol. На практике Level 2 (ViewBuilder) почти бесполезен — custom renderers получают `[HTMLNode]`, но не могут их отрисовать. StyleConfig покрывает мало свойств. Захардкоженные значения (spacing, markers, cornerRadius) нельзя настроить без переписывания рендеринга целиком.

Эта PRD исправляет 10 проблем кастомизации и расширяет набор поддерживаемых HTML-элементов.

## Goals

- Сделать Level 2 кастомизацию (ViewBuilder) реально работающей
- Дать возможность зарегистрировать рендерер для произвольного тега
- Расширить HTMLElementStyle (cornerRadius, border)
- Вынести захардкоженные layout-значения в конфигурацию
- Сделать ссылки кликабельными по умолчанию
- Добавить поддержку распространённых inline-элементов и definition lists

## User Stories

### US-001: Публичный HTMLNodeView для рендеринга children

**Description:** As a developer using custom renderers, I want to render child nodes inside my custom view so that I can customize element appearance without losing nested content.

**Acceptance Criteria:**
- [ ] Публичный `HTMLNodeView: View` в модуле HTMLRenderer
- [ ] `init(nodes: [HTMLNode])` — рендерит массив узлов
- [ ] `init(node: HTMLNode)` — рендерит один узел
- [ ] Использует тот же environment (styleConfiguration, customRenderers, onLinkTap, onUnknownElement)
- [ ] Работает внутри custom renderers (HTMLHeadingRenderer, HTMLParagraphRenderer и др.)
- [ ] Тесты: custom renderer с HTMLNodeView корректно рендерит вложенный контент
- [ ] Typecheck passes

### US-002: Generic HTMLTagRenderer по произвольному tag name

**Description:** As a developer, I want to register a custom renderer for any HTML tag (like `<video>`, `<img>`, `<details>`) so that I don't have to use a switch statement in onUnknownElement.

**Acceptance Criteria:**
- [ ] `HTMLTagRenderer("tagname") { children, attributes in ... }` — публичный тип
- [ ] Реализует `HTMLRendererComponent` protocol
- [ ] Добавляет closure в словарь `[String: closure]` внутри `HTMLCustomRenderers`
- [ ] Проверяется в ElementRenderer ДО `default` case (но ПОСЛЕ встроенных тегов)
- [ ] Можно зарегистрировать несколько тегов в одном `@HTMLContentBuilder`
- [ ] Работает с `HTMLNodeView` для рендеринга children
- [ ] Тесты: custom tag renderer вызывается для указанного тега
- [ ] Typecheck passes

### US-003: Расширение HTMLElementStyle (cornerRadius, border)

**Description:** As a developer, I want to customize corner radius and borders through StyleConfig so that I can style `<pre>` and `<blockquote>` without writing a full custom renderer.

**Acceptance Criteria:**
- [ ] `HTMLElementStyle` получает новые опциональные свойства: `cornerRadius: CGFloat?`, `borderColor: Color?`, `borderWidth: CGFloat?`
- [ ] `applyStyle()` применяет cornerRadius через `.clipShape(RoundedRectangle(cornerRadius:))` если задан
- [ ] `applyStyle()` применяет border через `.overlay(RoundedRectangle(...).stroke(color, lineWidth:))` если заданы borderColor и borderWidth
- [ ] `pre` block использует `config.preformatted.cornerRadius ?? 8` вместо захардкоженного 8
- [ ] `blockquote` использует `config.blockquote.borderWidth ?? 3` и `config.blockquote.borderColor ?? config.blockquote.foregroundColor ?? Color.accentColor`
- [ ] `.default` конфигурация обновлена: preformatted получает `cornerRadius: 8`, blockquote получает `borderWidth: 3`
- [ ] Обратная совместимость: все новые параметры опциональны, дефолты nil
- [ ] Тесты: кастомный cornerRadius и border применяются
- [ ] Typecheck passes

### US-004: Layout-значения в HTMLStyleConfiguration

**Description:** As a developer, I want to customize spacing between elements, list markers, and other layout values so that I can match my app's design system without full custom renderers.

**Acceptance Criteria:**
- [ ] `HTMLStyleConfiguration` получает новые свойства:
  - `blockSpacing: CGFloat` (default 8) — spacing для VStack в div, section, blockquote и др.
  - `listSpacing: CGFloat` (default 4) — spacing для VStack в ul/ol
  - `listMarkerSpacing: CGFloat` (default 6) — spacing между маркером и контентом (HStack)
  - `bulletMarker: String` (default "•") — символ маркера для ul
- [ ] ElementRenderer использует эти значения вместо захардкоженных
- [ ] `.default` конфигурация содержит текущие значения (8, 4, 6, "•")
- [ ] Обратная совместимость: дефолты совпадают с текущим поведением
- [ ] Тесты: кастомные layout-значения применяются
- [ ] Typecheck passes

### US-005: HTMLListRenderer различает ul и ol

**Description:** As a developer using a custom list renderer, I want to know whether the list is ordered or unordered so that I can render appropriate markers.

**Acceptance Criteria:**
- [ ] `HTMLListRenderer` init изменён: `([HTMLNode], Bool, [String: String]) -> Content` — второй параметр `ordered: Bool`
- [ ] `HTMLCustomRenderers.list` closure обновлена: `([HTMLNode], Bool, [String: String]) -> AnyView`
- [ ] ElementRenderer передаёт `false` для `<ul>` и `true` для `<ol>`
- [ ] Тесты: custom list renderer получает корректное значение ordered
- [ ] Typecheck passes

### US-006: Ссылки кликабельны по умолчанию

**Description:** As a user of HTMLView, I want links to open in Safari by default so that I don't have to explicitly configure onLinkTap for basic link behavior.

**Acceptance Criteria:**
- [ ] Без `onLinkTap`: ссылки рендерятся как `Button`, при нажатии вызывают `OpenURLAction` из SwiftUI environment
- [ ] С `onLinkTap`: поведение не меняется — вызывается пользовательский handler
- [ ] Inline-collapsed ссылки (внутри `Text`) используют `AttributedString.link` — работают через environment `openURL` по умолчанию
- [ ] Тесты: ссылка без onLinkTap рендерится как Button
- [ ] Typecheck passes

### US-007: onLinkTap получает HTMLElement

**Description:** As a developer handling link taps, I want access to the full element (attributes like title, target, data-*) so that I can implement custom navigation logic.

**Acceptance Criteria:**
- [ ] Сигнатура `onLinkTap` изменена: `(@Sendable (URL, HTMLElement) -> Void)?`
- [ ] Все 4 init'а HTMLView обновлены
- [ ] Environment key `OnLinkTapKey` обновлён
- [ ] ElementRenderer передаёт `element` при вызове handler
- [ ] Тесты: onLinkTap получает HTMLElement с корректными атрибутами
- [ ] Typecheck passes

### US-008: Поддержка inline-элементов (mark, small, kbd, q, cite, ins)

**Description:** As a developer rendering CMS content, I want common inline elements to render with appropriate default styles so that content looks correct without custom configuration.

**Acceptance Criteria:**
- [ ] `<mark>` — жёлтый фон (`Color.yellow.opacity(0.3)`)
- [ ] `<small>` — `.caption` font
- [ ] `<kbd>` — monospaced font, серая рамка (1px), cornerRadius 3, padding 1-3
- [ ] `<q>` — оборачивает содержимое в кавычки (Text("\u201C") + children + Text("\u201D"))
- [ ] `<cite>` — italic
- [ ] `<ins>` — underline
- [ ] `<abbr>` — рендерит как обычный текст (tooltip невозможен в SwiftUI)
- [ ] Все новые элементы работают в inline collapsing (добавлены в phrasingTags)
- [ ] Все новые элементы работают в `buildInlineText` (InlineTextBuilder)
- [ ] `HTMLElementStyle` slots в `HTMLStyleConfiguration`: `mark`, `small`, `keyboard` для кастомизации
- [ ] `.default` конфигурация содержит дефолтные стили для новых элементов
- [ ] Тесты: каждый новый элемент рендерится с корректным стилем
- [ ] Typecheck passes

### US-009: Поддержка definition lists (dl, dt, dd)

**Description:** As a developer rendering documentation content, I want definition lists to render with proper structure so that FAQ and glossary content displays correctly.

**Acceptance Criteria:**
- [ ] `<dl>` — `VStack(alignment: .leading, spacing: blockSpacing)`
- [ ] `<dt>` — bold text (`.bold()`)
- [ ] `<dd>` — indented text (`.padding(.leading, 16)`)
- [ ] dt и dd работают с inline collapsing
- [ ] `HTMLDefinitionListRenderer` — custom renderer component для `<dl>`
- [ ] Добавлен в `HTMLCustomRenderers` как `definitionList` slot
- [ ] Тесты: dl/dt/dd рендерятся с корректной структурой
- [ ] Typecheck passes

## Functional Requirements

- FR-1: `HTMLNodeView` — публичный View для рендеринга `[HTMLNode]` внутри custom renderers
- FR-2: `HTMLTagRenderer` — компонент для регистрации рендерера по произвольному tag name
- FR-3: `HTMLElementStyle` расширен свойствами `cornerRadius`, `borderColor`, `borderWidth`
- FR-4: `HTMLStyleConfiguration` содержит layout-значения: `blockSpacing`, `listSpacing`, `listMarkerSpacing`, `bulletMarker`
- FR-5: `HTMLListRenderer` передаёт `ordered: Bool` в closure
- FR-6: Ссылки кликабельны по умолчанию через `OpenURLAction` из environment
- FR-7: `onLinkTap` принимает `(URL, HTMLElement)` вместо `(URL)`
- FR-8: Встроенная поддержка `<mark>`, `<small>`, `<kbd>`, `<q>`, `<cite>`, `<ins>`, `<abbr>`
- FR-9: Встроенная поддержка `<dl>`, `<dt>`, `<dd>` с `HTMLDefinitionListRenderer`
- FR-10: Все новые inline-элементы работают в inline collapsing и InlineTextBuilder

## Non-Goals

- Поддержка `<img>` — пользователь решает через `HTMLTagRenderer`
- Поддержка редких inline-элементов (`<var>`, `<samp>`, `<time>`, `<dfn>`, `<ruby>`)
- AST-трансформация (map/filter)
- Параметр parseMode для HTMLView
- CSS-парсинг inline styles
- colspan/rowspan в таблицах
- Формы и интерактивные элементы

## Technical Considerations

- Breaking changes в сигнатурах: `HTMLListRenderer`, `onLinkTap`. Библиотека pre-release — допустимо.
- `HTMLNodeView` должен использовать тот же SwiftUI environment, что и внутренний `NodeRenderer`. Реализация — тонкая обёртка над `NodeRenderer`.
- `HTMLTagRenderer` словарь проверяется в ElementRenderer.body после встроенных case'ов, но до `default`. Если пользователь регистрирует рендерер для встроенного тега (например, "p"), он НЕ перекрывает встроенный — для этого есть `HTMLParagraphRenderer`.
- Inline collapsing: новые phrasing-элементы (`mark`, `small`, `kbd`, `q`, `cite`, `ins`, `abbr`) добавляются в `phrasingTags` set и обрабатываются в `buildElementText`.
- `<q>` в inline context: конкатенация `Text("\u201C") + childText + Text("\u201D")`.

## Success Metrics

- Custom renderers могут рекурсивно рендерить children через `HTMLNodeView`
- Пользователь регистрирует рендерер для любого тега в 1 строку
- Ссылки работают из коробки без конфигурации
- StyleConfig покрывает cornerRadius и border без ViewBuilder
- Layout-значения настраиваются без full override

## Open Questions

- Должен ли `HTMLTagRenderer` перекрывать встроенные теги? Текущее решение: нет, для встроенных тегов есть свои renderer components. Но стоит обсудить.
- `<kbd>` стиль: рамка реализуема через `overlay`, но в inline collapsing (внутри `Text`) рамки невозможны. Только monospaced font + foregroundColor. Нужен ли fallback?
