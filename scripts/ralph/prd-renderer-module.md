# PRD: Renderer Module — AST → SwiftUI Views

## Introduction

Второй модуль SwiftHTMLRenderer: рендеринг HTML AST в нативные SwiftUI views. Принимает `HTMLDocument` от парсера и превращает в дерево SwiftUI views с дефолтными стилями.

Три уровня кастомизации: Style Configuration (шрифты/цвета), ViewBuilder closures (кастомные views для элементов), Visitor protocol (произвольный обход AST). Каждый элемент рендерится как отдельный View — inline collapsing отложен как оптимизация.

Модуль зависит от `HTMLParser`. Работает на iOS 17+.

## Goals

- Рендерить все поддерживаемые HTML-элементы из SPEC.md в SwiftUI views
- Дефолтные стили из коробки — работает без настройки
- Style Configuration для быстрой настройки шрифтов, цветов, отступов
- ViewBuilder closures для полной замены рендеринга конкретных элементов
- Visitor protocol для произвольного обхода AST (рендеринг, аналитика, экспорт)
- Ссылки через callback пользователя
- Неизвестные элементы — пропускаем тег, рендерим детей
- Таблицы через SwiftUI Grid (простые, без colspan/rowspan)
- iOS 17+, Swift 6.2, strict concurrency

## User Stories

### US-001: Добавить модуль HTMLRenderer в SPM-пакет

**Description:** Как разработчик библиотеки, я хочу добавить новый Swift-модуль `HTMLRenderer` в пакет, чтобы пользователи подключали рендерер отдельно от парсера.

**Acceptance Criteria:**
- [ ] Таргет `HTMLRenderer` в `Package.swift`, зависит от `HTMLParser`
- [ ] Таргет `HTMLRenderer` зависит от SwiftUI (`import SwiftUI`)
- [ ] Product `HTMLRenderer` экспортируется как библиотека
- [ ] Тестовый таргет `HTMLRendererTests` зависит от `HTMLRenderer`
- [ ] Файлы в `Sources/HTMLRenderer/`
- [ ] `swift build` собирается без ошибок

### US-002: Дефолтный рендеринг текстовых элементов

**Description:** Как пользователь библиотеки, я хочу передать HTML с текстом и получить SwiftUI view, чтобы отобразить rich-text контент.

**Acceptance Criteria:**
- [ ] `HTMLView(document:)` принимает `HTMLDocument` и рендерит SwiftUI view
- [ ] `HTMLView(html:)` — convenience, парсит строку через `HTMLParser.parseFragment()` и рендерит
- [ ] `<h1>`–`<h6>` рендерятся как `Text` с соответствующими размерами шрифтов (`.largeTitle`, `.title`, `.title2`, `.title3`, `.headline`, `.subheadline`)
- [ ] `<p>` рендерится как `Text` с `.body`
- [ ] `<b>`, `<strong>` — жирный шрифт
- [ ] `<i>`, `<em>` — курсив
- [ ] `<u>` — подчёркивание
- [ ] `<s>`, `<del>` — зачёркивание
- [ ] `<code>` — моноширинный шрифт
- [ ] `<sub>`, `<sup>` — подстрочный/надстрочный (через `.baselineOffset`)
- [ ] `<span>` — рендерит children без дополнительных стилей
- [ ] `<br>` — перенос строки
- [ ] Текстовые ноды (`.text`) рендерятся как `Text`
- [ ] `swift build` собирается без ошибок
- [ ] Тест: `HTMLView(html: "<h1>Title</h1>")` не крашится

### US-003: Дефолтный рендеринг блочных элементов

**Description:** Как пользователь библиотеки, я хочу отображать списки, цитаты и другие блочные элементы.

**Acceptance Criteria:**
- [ ] `<ul>` рендерится как вертикальный `VStack` с буллетами (`•`) перед каждым `<li>`
- [ ] `<ol>` рендерится как вертикальный `VStack` с нумерацией (`1.`, `2.`, ...) перед каждым `<li>`
- [ ] `<blockquote>` — отступ слева + вертикальная полоска (`.leading` border)
- [ ] `<pre>` — моноширинный шрифт, сохраняет whitespace, фоновый цвет
- [ ] `<hr>` — горизонтальная линия (`Divider`)
- [ ] `<div>` — рендерит children в `VStack`
- [ ] Семантические контейнеры (`<article>`, `<section>`, `<main>`, `<header>`, `<footer>`, `<nav>`, `<aside>`) — аналогично `<div>`, рендерят children
- [ ] `<figure>` — рендерит children, `<figcaption>` — мелкий текст (`.caption`)
- [ ] `swift build` собирается без ошибок
- [ ] Тест: `HTMLView(html: "<ul><li>A</li><li>B</li></ul>")` не крашится

### US-004: Рендеринг таблиц через Grid

**Description:** Как пользователь библиотеки, я хочу отображать простые HTML-таблицы.

**Acceptance Criteria:**
- [ ] `<table>` рендерится через SwiftUI `Grid`
- [ ] `<thead>`, `<tbody>`, `<tfoot>` — структурные обёртки, рендерят children
- [ ] `<tr>` → `GridRow`
- [ ] `<th>` — жирный текст в ячейке
- [ ] `<td>` — обычный текст в ячейке
- [ ] Таблица с 2+ строками и 2+ столбцами отображается корректно
- [ ] `colspan` и `rowspan` игнорируются (не поддерживаются в v1)
- [ ] `swift build` собирается без ошибок
- [ ] Тест: `HTMLView(html: "<table><tr><td>A</td><td>B</td></tr></table>")` не крашится

### US-005: Ссылки и неизвестные элементы

**Description:** Как пользователь библиотеки, я хочу управлять поведением ссылок и видеть контент неизвестных тегов.

**Acceptance Criteria:**
- [ ] `HTMLView(document:, onLinkTap:)` — callback вызывается при нажатии на ссылку с `URL`
- [ ] `<a href="...">` без callback — стилизованный текст (подчёркивание + синий цвет), не кликабельный
- [ ] `<a href="...">` с callback — кликабельный, вызывает `onLinkTap` с URL из `href`
- [ ] Неизвестные/неподдерживаемые теги — тег пропускается, children рендерятся
- [ ] `onUnknownElement` callback — если задан, вызывается для неизвестных элементов, пользователь возвращает `AnyView`
- [ ] `swift build` собирается без ошибок
- [ ] Тест: `<a href="https://example.com">link</a>` рендерится без краша

### US-006: Style Configuration

**Description:** Как пользователь библиотеки, я хочу менять шрифты, цвета и отступы без написания кастомных views.

**Acceptance Criteria:**
- [ ] `HTMLStyleConfiguration` — struct с настройками для каждого типа элемента
- [ ] Настраиваемые свойства: `font`, `foregroundColor`, `backgroundColor`, `padding`, `lineSpacing`
- [ ] Группы элементов: `heading1`–`heading6`, `paragraph`, `bold`, `italic`, `underline`, `strikethrough`, `code`, `preformatted`, `blockquote`, `link`, `listItem`, `tableHeader`, `tableCell`
- [ ] `HTMLView(document:, configuration:)` — принимает конфигурацию
- [ ] Дефолтная конфигурация — `HTMLStyleConfiguration.default`
- [ ] Незаданные свойства используют дефолтные значения
- [ ] `swift build` собирается без ошибок
- [ ] Тест: кастомный `configuration` применяется без краша

### US-007: ViewBuilder Closures

**Description:** Как пользователь библиотеки, я хочу полностью заменить рендеринг конкретного элемента своим SwiftUI view.

**Acceptance Criteria:**
- [ ] Result builder для объявления кастомных рендереров элементов
- [ ] Поддержка переопределения: headings, paragraphs, links, lists, list items, blockquotes, code blocks, tables
- [ ] Closure получает контент элемента (children) и атрибуты (`[String: String]`)
- [ ] Closure возвращает `some View`
- [ ] Элементы без closure — рендерятся стилями из configuration или дефолтными
- [ ] ViewBuilder приоритетнее Style Configuration для того же элемента
- [ ] `swift build` собирается без ошибок
- [ ] Тест: ViewBuilder для heading применяется без краша

### US-008: Visitor Protocol

**Description:** Как пользователь библиотеки, я хочу обходить AST с произвольным результатом — для рендеринга, аналитики, экспорта.

**Acceptance Criteria:**
- [ ] `HTMLVisitor` protocol с `associatedtype Result`
- [ ] Методы для каждого типа элемента: `visitElement(_:)`, `visitText(_:)`, `visitComment(_:)`
- [ ] Дефолтные реализации через protocol extension (возвращают пустой результат или рекурсивно обходят children)
- [ ] `HTMLDocument.accept(visitor:)` — запускает обход и возвращает `[Result]`
- [ ] Visitor — отдельный механизм, не комбинируется со Style Config и ViewBuilder
- [ ] `swift build` собирается без ошибок
- [ ] Тест: visitor, собирающий текст из всех Text-нод, работает корректно

### US-009: Тесты рендерера

**Description:** Как разработчик библиотеки, я хочу покрыть рендерер тестами, чтобы убедиться в корректности.

**Acceptance Criteria:**
- [ ] Тесты в `Tests/HTMLRendererTests/`
- [ ] Тест: `HTMLView(html:)` создаётся без краша для каждого поддерживаемого элемента
- [ ] Тест: `HTMLView(document:)` с вручную созданным AST работает
- [ ] Тест: пустой `HTMLDocument` рендерит `EmptyView`
- [ ] Тест: Style Configuration применяется (view создаётся без краша)
- [ ] Тест: ViewBuilder closure вызывается для переопределённого элемента
- [ ] Тест: `HTMLVisitor` корректно обходит дерево и собирает результат
- [ ] Тест: неизвестный элемент — children рендерятся
- [ ] Тест: вложенные элементы `<div><p><b>text</b></p></div>` — корректная структура
- [ ] `swift test` проходит без ошибок

## Functional Requirements

- FR-1: Модуль `HTMLRenderer` в SPM с зависимостью от `HTMLParser` и `SwiftUI`
- FR-2: `HTMLView` — главный SwiftUI view, принимает `HTMLDocument` или HTML-строку
- FR-3: Все элементы из SPEC.md рендерятся с дефолтными стилями
- FR-4: Каждый HTML-элемент → отдельный SwiftUI View (без inline collapsing)
- FR-5: `HTMLStyleConfiguration` — struct для настройки шрифтов, цветов, отступов
- FR-6: ViewBuilder closures заменяют рендеринг конкретных элементов
- FR-7: ViewBuilder приоритетнее Style Configuration
- FR-8: `HTMLVisitor` protocol с `associatedtype Result` для произвольного обхода
- FR-9: Visitor — отдельный механизм, не комбинируется с ViewBuilder/StyleConfig
- FR-10: Ссылки — callback `onLinkTap`, без callback — стилизованный некликабельный текст
- FR-11: Неизвестные элементы — пропуск тега, рендеринг children
- FR-12: Таблицы через SwiftUI `Grid`, без colspan/rowspan

## Non-Goals (Out of Scope)

- Inline collapsing (оптимизация — отдельная итерация)
- Accessibility маппинг (отдельный PRD)
- CSS-парсинг и inline styles
- Images (`<img>`)
- Forms, inputs, interactive элементы
- colspan/rowspan для таблиц
- Кеширование рендеринга
- macOS/visionOS/watchOS
- Streaming/incremental рендеринг
- Performance benchmarks рендеринга (только парсер бенчмаркится)

## Technical Considerations

### Структура модуля

```
Sources/
  HTMLRenderer/
    HTMLView.swift              — главный SwiftUI view
    Configuration/
      HTMLStyleConfiguration.swift
    Renderers/
      BlockRenderer.swift       — div, article, section, blockquote, pre, hr
      TextRenderer.swift        — h1-h6, p, b, i, u, s, code, span, br, sub, sup
      ListRenderer.swift        — ul, ol, li
      TableRenderer.swift       — table, thead, tbody, tfoot, tr, th, td
      LinkRenderer.swift        — a
    Visitor/
      HTMLVisitor.swift
    ViewBuilder/
      HTMLViewBuilder.swift     — result builder для кастомных renderers
Tests/
  HTMLRendererTests/
```

### Подход к рендерингу

- Рекурсивный обход AST: `HTMLNode` → соответствующий SwiftUI View
- Switch по `tagName` для выбора рендерера
- Каждый элемент — отдельный View (без AttributedString/inline collapsing)
- Текстовые inline-элементы (`<b>`, `<i>` и т.д.) применяют модификаторы к `Text`

### Таблицы

- SwiftUI `Grid` + `GridRow` — простой маппинг tr → GridRow, td/th → GridRow children
- Без расчёта ширины колонок — Grid делает это сам
- `<thead>/<tbody>/<tfoot>` — структурные, просто передают children

### Приоритет кастомизации

```
1. ViewBuilder closure (если задан для элемента)
2. Style Configuration (если задана для элемента)
3. Дефолтные стили
```

Visitor protocol — полностью отдельный пайплайн. Пользователь вызывает `document.accept(visitor:)` напрямую, минуя `HTMLView`.

### Зависимости

- `HTMLParser` — AST типы
- `SwiftUI` — рендеринг

## Success Metrics

- `swift build` собирается без ошибок и предупреждений
- `swift test` — все тесты проходят
- Все элементы из SPEC.md рендерятся с дефолтными стилями
- Три уровня кастомизации работают по приоритету: ViewBuilder > StyleConfig > Default
- Visitor корректно обходит дерево с произвольным Result type

## Resolved Questions

| Вопрос | Решение |
|---|---|
| Все три уровня кастомизации? | **Да, все три в v1** |
| Inline collapsing? | **Нет, простой подход — каждый элемент = View. Оптимизация позже** |
| Accessibility? | **Отдельный PRD** |
| Таблицы? | **Grid-based в этом PRD, без colspan/rowspan** |

## Open Questions

- Как именно ViewBuilder result builder будет собирать кастомные renderers? Нужно ли enum для типов элементов или строковый tag name?
- Нужен ли `HTMLView(html:)` convenience или достаточно `HTMLView(document:)`? Решение: оба, convenience парсит через `parseFragment`.
- Visitor: нужны ли отдельные методы для каждого тега (`visitHeading`, `visitParagraph`) или достаточно `visitElement`? Начинаем с `visitElement`/`visitText`/`visitComment`, расширим при необходимости.
