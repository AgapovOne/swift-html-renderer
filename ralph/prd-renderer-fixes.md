# PRD: HTMLRenderer Quality Fixes

## Introduction

HTMLRenderer имеет 3 проблемы: deprecated API, лишние `init(html:)` инициализаторы с парсингом внутри view, монолитный switch на 230+ строк. Этот PRD покрывает их исправление.

Полный анализ: `docs/RENDERER_REVIEW.md`, `docs/RENDERER_FIXES.md`
Отложенные проблемы: `docs/TODO.md`

## Goals

- Заменить deprecated `foregroundColor()` на `foregroundStyle()`
- Убрать `init(html:)` — оставить только `init(document:)`
- Разбить монолитный switch в ElementRenderer на методы с helper для повторяющегося `canCollapseInline` паттерна

## User Stories

### US-001: Replace deprecated foregroundColor with foregroundStyle
**Description:** As a library maintainer, I want to use modern SwiftUI API so that deprecation warnings don't appear in consumer projects.

**Acceptance Criteria:**
- [ ] `InlineTextBuilder.swift:192` — `foregroundColor(color)` заменён на `foregroundStyle(color)`
- [ ] Нет других вызовов `foregroundColor()` в модуле HTMLRenderer
- [ ] Все тесты HTMLRendererTests проходят
- [ ] Билд без deprecation warnings

### US-002: Remove init(html:) from HTMLView
**Description:** As a library designer, I want HTMLView to accept only pre-parsed HTMLDocument so that parsing responsibility is explicit and users control caching.

**Acceptance Criteria:**
- [ ] Удалён `init(html:, configuration:, onLinkTap:, onUnknownElement:)`
- [ ] Удалён `init(html:, configuration:, onLinkTap:, onUnknownElement:, content:)`
- [ ] Остались только 2 инициализатора: `init(document:, ...)` и `init(document:, ..., content:)`
- [ ] `import HTMLParser` убран из HTMLRenderer module, если больше не нужен в этом файле (проверить — HTMLContentBuilder и InlineTextBuilder используют HTMLParser типы, import остаётся)
- [ ] Все тесты HTMLRendererTests обновлены: `HTMLView(html:)` → `HTMLView(document: HTMLParser.parseFragment(...))`
- [ ] Библиотека компилируется

### US-003: Refactor monolithic ElementRenderer switch
**Description:** As a library developer, I want readable and maintainable ElementRenderer so that adding new elements doesn't require navigating 230-строчный switch.

**Acceptance Criteria:**
- [ ] Inline-элементы (b, strong, i, em, u, s, del, code, span, abbr, mark, small, kbd, q, cite, ins, br, sub, sup) вынесены в `renderInlineElement() -> some View`
- [ ] Table default rendering вынесен в `renderTableDefault() -> some View`
- [ ] List rendering (ul, ol) вынесен в `renderUnorderedList()` и `renderOrderedList()`
- [ ] Block containers (div, article, section, main, header, footer, nav, aside) вынесены в `renderBlockContainer() -> some View`
- [ ] Definition list (dl, dt, dd) вынесен в метод
- [ ] Повторяющийся паттерн `if canCollapseInline { buildInlineText } else { renderChildren() }` вынесен в helper-метод `renderWithInlineCollapsing(style:defaultFont:)`
- [ ] Главный switch содержит только вызовы методов, без inline-логики
- [ ] Все 48 тестов HTMLRendererTests проходят без изменений
- [ ] Public API не изменился (кроме удалённых init-ов из US-002)

## Functional Requirements

- FR-1: Заменить `Text.foregroundColor()` на `Text.foregroundStyle()` в InlineTextBuilder
- FR-2: Удалить 2 init-а `HTMLView` с параметром `html: String`
- FR-3: Обновить тесты: парсинг вынести из HTMLView в тесты
- FR-4: Разбить `ElementRenderer.body` switch на категорийные методы
- FR-5: Создать helper `renderWithInlineCollapsing()` для устранения дублирования 8 одинаковых `canCollapseInline` проверок

## Non-Goals

- Не менять `ForEach(id: \.offset)` — immutable AST, стабильно
- Не убирать `AnyView` из кастомных рендереров — стандартный trade-off
- Не менять `ifLet` в `applyStyle()` — branches стабильны
- Не менять `Group` в `HTMLView.body` — layout контролирует пользователь
- Не добавлять кэширование `canCollapseInline` — overhead пренебрежим
- Не рефакторить Environment closures — отложено в `docs/TODO.md`

## Technical Considerations

- **Порядок:** US-001 → US-002 → US-003. US-001 независима. US-002 перед US-003, чтобы switch refactor не конфликтовал с обновлением тестов.
- **Breaking change:** удаление `init(html:)` — breaking change для пользователей. Для библиотеки до публичного релиза это приемлемо.
- **Helper `renderWithInlineCollapsing`:** принимает `style: HTMLElementStyle`, `defaultFont: Font?`. Внутри проверяет `canCollapseInline`, вызывает `buildInlineText` или `renderChildren`, применяет стиль. Заменяет 8 мест с дублированным паттерном.

## Success Metrics

- Все тесты проходят (с обновлениями в US-002)
- Нет deprecation warnings
- `ElementRenderer.body` switch — только вызовы методов
- 2 init-а вместо 4
