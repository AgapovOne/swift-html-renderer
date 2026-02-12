# PRD: Parser Module — HTML5 → AST

## Introduction

Первый модуль SwiftHTMLRenderer: парсер HTML5-строки в публичный immutable AST. Использует Gumbo (Codeberg fork) как сторонний HTML5-парсер. Модуль конвертирует Gumbo-дерево в собственные Swift-структуры: Equatable, Hashable, value types.

Модуль работает автономно — без Renderer. Пользователь получает AST и решает, что с ним делать: рендерить, анализировать, трансформировать.

## Goals

- Парсить HTML5-строку (документ или фрагмент) в публичный AST
- AST — immutable value types (structs), Equatable, Hashable
- Gumbo встроен как C-таргет в SPM (без внешних зависимостей для пользователя)
- Синхронный API, thread-safe, без run loop
- Быстрее NSAttributedString(html:) — с бенчмарками
- iOS 17+, Swift 6.2, strict concurrency

## User Stories

### US-001: Настроить SPM-пакет с Gumbo C-таргетом

**Description:** Как разработчик библиотеки, я хочу встроить Gumbo-парсер в SPM-пакет, чтобы пользователи подключали одну зависимость без дополнительной настройки.

**Acceptance Criteria:**
- [ ] Gumbo C-исходники (Codeberg fork v0.13.x) добавлены в `Sources/CGumbo/`
- [ ] `Package.swift` содержит C-таргет `CGumbo` с правильными путями и header search paths
- [ ] Таргет `HTMLParser` зависит от `CGumbo`
- [ ] `swift build` компилирует пакет без ошибок на macOS (arm64)
- [ ] `swift build` компилирует без ошибок для iOS 17+ (через destination)
- [ ] Gumbo-исходники не модифицированы (чистый upstream)
- [ ] Лицензия Apache 2.0 для Gumbo указана в проекте

### US-002: Определить публичный AST

**Description:** Как пользователь библиотеки, я хочу получить типизированное дерево HTML-документа, чтобы обходить, инспектировать и трансформировать его.

**Acceptance Criteria:**
- [ ] `HTMLDocument` — корневой тип, содержит массив дочерних `HTMLNode`
- [ ] `HTMLNode` — enum с кейсами: `.element(HTMLElement)`, `.text(String)`, `.comment(String)`
- [ ] `HTMLElement` — struct с полями: `tagName: String` (lowercase), `attributes: [String: String]`, `children: [HTMLNode]`
- [ ] Все типы: `Equatable`, `Hashable`, `Sendable`
- [ ] Все типы — value types (structs/enums), не classes
- [ ] Boolean-атрибуты нормализованы: `["disabled": "disabled"]`
- [ ] `style` хранится как сырая строка в атрибутах (без CSS-парсинга)
- [ ] Все типы публичные (`public`)
- [ ] Публичные инициализаторы для ручного создания AST
- [ ] Код в модуле `HTMLParser`

### US-003: Реализовать конвертацию Gumbo → AST

**Description:** Как разработчик библиотеки, я хочу конвертировать Gumbo C-дерево в наш Swift AST, чтобы пользователь работал с безопасными Swift-типами.

**Acceptance Criteria:**
- [ ] Функция принимает `GumboOutput*`, возвращает `HTMLDocument`
- [ ] Рекурсивный обход `GumboNode*` → `HTMLNode`
- [ ] `GUMBO_NODE_ELEMENT` → `.element(HTMLElement)` с тегом, атрибутами, детьми
- [ ] `GUMBO_NODE_TEXT` и `GUMBO_NODE_WHITESPACE` → `.text(String)`
- [ ] `GUMBO_NODE_COMMENT` → `.comment(String)`
- [ ] `GUMBO_NODE_DOCUMENT` → обход дочерних узлов
- [ ] Tag names нормализованы в lowercase (через `gumbo_normalized_tagname` или `original_tag` для unknown)
- [ ] `GumboVector` корректно итерируется (`.data` + `.length`)
- [ ] `GumboAttribute` конвертируется в `[String: String]`
- [ ] `gumbo_destroy_output()` вызывается после конвертации (до возврата)
- [ ] Нет утечек памяти (Gumbo-аллокации полностью освобождаются)
- [ ] Конвертер — internal (не публичный), деталь реализации

### US-004: Публичный API парсинга

**Description:** Как пользователь библиотеки, я хочу парсить HTML одним вызовом, чтобы быстро получить AST.

**Acceptance Criteria:**
- [ ] `HTMLParser.parse(_ html: String) -> HTMLDocument` — парсинг полного документа
- [ ] `HTMLParser.parseFragment(_ html: String) -> HTMLDocument` — парсинг фрагмента (без `<html><body>` обёртки)
- [ ] Фрагмент `<p>Hello</p>` возвращает документ с одним элементом `p`, без обёрток `html`/`head`/`body`
- [ ] Полный документ `<html><body><p>Hi</p></body></html>` возвращает дерево с `html` → `head` + `body` → `p`
- [ ] Пустая строка возвращает пустой `HTMLDocument`
- [ ] Невалидный HTML не крашит парсер (error recovery от Gumbo)
- [ ] API синхронный, без throws (Gumbo всегда возвращает результат)
- [ ] `HTMLParser` — enum (namespace), не инстанцируется
- [ ] Thread-safe: вызывается с любого потока

### US-005: Тесты парсера

**Description:** Как разработчик библиотеки, я хочу покрыть парсер тестами, чтобы убедиться в корректности конвертации.

**Acceptance Criteria:**
- [ ] Тесты в `Tests/HTMLParserTests/`
- [ ] Тест: парсинг простого параграфа `<p>Hello</p>`
- [ ] Тест: вложенные inline-элементы `<p><b>bold <i>and italic</i></b></p>`
- [ ] Тест: атрибуты `<a href="url" class="link">text</a>`
- [ ] Тест: boolean-атрибут `<input disabled>`
- [ ] Тест: заголовки h1–h6
- [ ] Тест: списки `<ul><li>item</li></ul>` и `<ol><li>item</li></ol>`
- [ ] Тест: таблица `<table><tr><td>cell</td></tr></table>`
- [ ] Тест: фрагмент без `<html><body>`
- [ ] Тест: пустая строка
- [ ] Тест: невалидный HTML (незакрытые теги)
- [ ] Тест: HTML entities `&amp;`, `&#60;`, `&#x3C;`
- [ ] Тест: void elements `<br>`, `<img>`, `<hr>`
- [ ] Тест: semantic containers `<article>`, `<section>`, `<main>`
- [ ] Тест: `<pre>` сохраняет whitespace
- [ ] Тест: комментарии `<!-- comment -->`
- [ ] Тест: `Equatable` — два одинаковых парсинга дают равные AST
- [ ] Тест: `Hashable` — два одинаковых AST дают одинаковый хеш
- [ ] `swift test` проходит без ошибок

### US-006: Бенчмарки парсинга

**Description:** Как разработчик библиотеки, я хочу измерить скорость парсинга и сравнить с NSAttributedString(html:), чтобы подтвердить преимущество.

**Acceptance Criteria:**
- [ ] Бенчмарк-таргет в SPM (`HTMLParserBenchmarks`)
- [ ] Тестовые HTML-документы: small (<1 KB), medium (1–10 KB), large (50+ KB)
- [ ] Замер parse time нашего парсера (среднее, медиана, p95 за 100 итераций)
- [ ] Замер NSAttributedString(html:) на тех же документах (baseline)
- [ ] Замер peak memory при парсинге
- [ ] Использует `ContinuousClock` для замеров
- [ ] Release build (`-c release`)
- [ ] Прогрев: 10 итераций перед замером
- [ ] Результаты выводятся в консоль в читаемом формате
- [ ] Наш парсер быстрее NSAttributedString(html:) на всех размерах

## Functional Requirements

- FR-1: SPM-пакет с двумя таргетами: `CGumbo` (C) и `HTMLParser` (Swift)
- FR-2: Gumbo v0.13.x (Codeberg fork) встроен как C-исходники в `Sources/CGumbo/`
- FR-3: `HTMLParser.parse(_ html: String) -> HTMLDocument` парсит полный документ
- FR-4: `HTMLParser.parseFragment(_ html: String) -> HTMLDocument` парсит фрагмент
- FR-5: AST состоит из: `HTMLDocument`, `HTMLNode` (enum), `HTMLElement` (struct)
- FR-6: Все AST-типы: `public`, `Equatable`, `Hashable`, `Sendable`, value types
- FR-7: Tag names — lowercase. Attributes — `[String: String]`.
- FR-8: Парсер синхронный, thread-safe, без throws
- FR-9: Gumbo memory корректно освобождается после конвертации
- FR-10: Бенчмарк-таргет сравнивает parse time с NSAttributedString(html:)

## Non-Goals (Out of Scope)

- SwiftUI-рендеринг (Renderer модуль — следующая итерация)
- Style Configuration, ViewBuilder closures, Visitor protocol
- CSS-парсинг
- Кеширование AST
- Управление потоками (Task, async/await)
- CocoaPods/Carthage поддержка
- macOS/visionOS/watchOS таргеты (только iOS 17+)
- Inline collapsing
- Accessibility маппинг
- Images, forms, interactive elements
- Streaming/incremental parsing

## Technical Considerations

### Структура проекта

```
Sources/
  CGumbo/
    include/
      gumbo.h
      ...
    src/
      parser.c
      tokenizer.c
      ...
    module.modulemap  (если нужен)
  HTMLParser/
    AST/
      HTMLDocument.swift
      HTMLNode.swift
      HTMLElement.swift
    Parser/
      HTMLParser.swift
      GumboConverter.swift  (internal)
Tests/
  HTMLParserTests/
    HTMLParserTests.swift
    HTMLParserFragmentTests.swift
    ASTEqualityTests.swift
Benchmarks/
  HTMLParserBenchmarks/
    main.swift
```

### Зависимости

- Gumbo C-исходники вендорятся в репозиторий (не внешняя SPM-зависимость)
- Ноль внешних зависимостей для пользователя

### Gumbo C API (ключевые функции)

```c
GumboOutput* gumbo_parse(const char* buffer);
GumboOutput* gumbo_parse_fragment(
    const GumboOptions* options,
    const char* buffer, size_t length,
    GumboTag fragment_ctx, GumboNamespaceEnum fragment_ns
);
void gumbo_destroy_output(const GumboOptions* options, GumboOutput* output);
const char* gumbo_normalized_tagname(GumboTag tag);
```

### Конвертация GumboNode → HTMLNode

```
GumboNode.type == GUMBO_NODE_ELEMENT  →  .element(HTMLElement)  *кроме <script> и <style>
GumboNode.type == GUMBO_NODE_TEXT     →  .text(String)
GumboNode.type == GUMBO_NODE_WHITESPACE → .text(String)
GumboNode.type == GUMBO_NODE_COMMENT  →  .comment(String)
GumboNode.type == GUMBO_NODE_DOCUMENT →  recurse into children
GumboNode.type == GUMBO_NODE_CDATA    →  пропускается
GumboNode.type == GUMBO_NODE_TEMPLATE →  пропускается
```

### Пропускаемые элементы

- `<script>` — пропускается полностью (с содержимым). Библиотека для контента, не для исполнения JS.
- `<style>` — пропускается полностью. CSS-парсинг вне scope v1.
- `GUMBO_NODE_CDATA` — пропускается. Крайне редок в HTML5.
- `GUMBO_NODE_TEMPLATE` — пропускается. Шаблоны не рендерятся.

### Фрагменты

`gumbo_parse_fragment()` принимает context element (по умолчанию `GUMBO_TAG_BODY`). Результат — дерево без `<html>/<head>/<body>` обёрток. Для `parseFragment()` обходим детей `<body>` напрямую.

### Performance

- Gumbo парсит синхронно, без аллокаций (кроме результата)
- Конвертация — один рекурсивный проход O(n)
- `gumbo_destroy_output()` освобождает всё Gumbo-дерево после конвертации
- Итого: 2 аллокации (Gumbo tree + Swift AST), одна сразу освобождается

### Memory safety

- C-указатели не выходят за пределы `GumboConverter`
- После `gumbo_destroy_output()` никакие C-указатели не используются
- Swift AST — полностью self-contained, без ссылок на C-память

## Success Metrics

- `swift build` собирается без ошибок и предупреждений
- `swift test` — все тесты проходят
- Parse time < NSAttributedString(html:) на small/medium/large документах
- Ноль утечек памяти (проверяется Instruments / Address Sanitizer)
- AST корректно представляет структуру всех поддерживаемых элементов из SPEC.md

## Resolved Questions

| Вопрос | Решение |
|---|---|
| Версия Gumbo | **v0.13.2** (последний релиз, сентябрь 2025) |
| `<script>` и `<style>` | **Пропускаются полностью** (с содержимым) |
| CDATA и template | **Пропускаются** |
| Бенчмарк-таргет | **Executable target** (`swift run HTMLParserBenchmarks -c release`) |
