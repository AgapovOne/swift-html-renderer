# PRD: Расширенные бенчмарки — сравнение парсеров и pipeline

## Введение

Текущие бенчмарки сравнивают HTMLParser (Lexbor) только с NSAttributedString(html:). Этого мало — непонятно, как мы выглядим на фоне альтернативных HTML-парсеров (SwiftSoup, swift-justhtml) и подходов (BonMot). Замеряем только парсинг, а пользователь видит pipeline целиком: парсинг + рендеринг.

Расширяем бенчмарки: добавляем 4 альтернативы и замер полного pipeline (парсер + рендерер).

## Цели

- Сравнить скорость парсинга HTMLParser с SwiftSoup, swift-justhtml, Lexbor и BonMot
- Замерить полный pipeline: парсинг → SwiftUI View body computation
- Замерить полный layout pipeline в UI-контексте (UIHostingController)
- Сгенерировать единый отчёт BENCHMARK_RESULTS.md со всеми результатами
- Использовать те же тестовые документы (small, medium, large) и метрики (avg, median, p95, memory)

## User Stories

### US-001: Добавить SwiftSoup в бенчмарки

**Описание:** Как разработчик, хочу видеть скорость парсинга SwiftSoup рядом с HTMLParser, чтобы понимать преимущество на фоне самого популярного Swift HTML-парсера.

**Приёмочные критерии:**
- [ ] SwiftSoup добавлен как зависимость в Package.swift (только для бенчмарк-таргета)
- [ ] Функция `benchmarkSwiftSoup(html:warmup:iterations:)` парсит HTML через `try SwiftSoup.parse(html)` и возвращает `BenchmarkResult`
- [ ] Замер memory для SwiftSoup аналогичен HTMLParser
- [ ] Результаты отображаются в консоли и в BENCHMARK_RESULTS.md
- [ ] Бенчмарк компилируется и запускается: `swift run -c release HTMLParserBenchmarks`

### US-002: Добавить swift-justhtml в бенчмарки

**Описание:** Как разработчик, хочу видеть скорость парсинга swift-justhtml — единственного pure Swift HTML5-парсера с 100% compliance.

**Приёмочные критерии:**
- [ ] swift-justhtml (v0.3.3) добавлен как зависимость в Package.swift (только для бенчмарк-таргета). Import: `import justhtml`
- [ ] Функция `benchmarkJustHTML(html:warmup:iterations:)` парсит HTML через API swift-justhtml и возвращает `BenchmarkResult`
- [ ] Замер memory для swift-justhtml аналогичен HTMLParser
- [ ] Результаты отображаются в консоли и в BENCHMARK_RESULTS.md
- [ ] Бенчмарк компилируется и запускается

### US-003: Добавить BonMot в бенчмарки

**Описание:** Как разработчик, хочу видеть скорость BonMot (XMLParser) как альтернативного подхода к обработке HTML-контента в iOS.

BonMot использует Foundation XMLParser (не HTML5). Не понимает HTML entities (`&nbsp;`), void elements (`<br>`), незакрытые теги. API: `NSAttributedString.composed(ofXML:rules:)` — требует предопределённые XMLStyleRule для каждого тега.

**Приёмочные критерии:**
- [ ] BonMot (v6.1.3) добавлен как зависимость в Package.swift (только для бенчмарк-таргета)
- [ ] XML-адаптированные версии тестовых документов в TestDocuments.swift: void elements закрыты (`<br/>`), HTML entities заменены на XML-safe (`&nbsp;` → `&#160;`), все теги закрыты
- [ ] XMLStyleRule массив с правилами для всех тегов в тестовых документах (p, h1-h6, ul, ol, li, a, b, strong, em, code, pre, table, tr, td, th, blockquote, div, section, article, header, nav, footer, dl, dt, dd)
- [ ] Функция `benchmarkBonMot(xml:warmup:iterations:)` парсит XML-документы через BonMot и возвращает `BenchmarkResult`
- [ ] Замер memory для BonMot аналогичен HTMLParser
- [ ] В отчёте BonMot помечен как "XML-adapted docs" с пояснением
- [ ] Бенчмарк компилируется и запускается

### US-004: Вендорить Lexbor как C-таргет

**Описание:** Как разработчик, хочу включить Lexbor — самый быстрый C HTML-парсер — для понимания потолка производительности.

Lexbor v2.6.0. Нужны модули: core (~20 .c), dom (~16 .c), tag (1 .c), ns (1 .c), html (~118 .c), ports/posix (3 .c). Итого ~159 .c файлов, ~340 файлов с .h. Нужен ручной `config.h` вместо CMake-генерируемого.

**Приёмочные критерии:**
- [ ] Исходники Lexbor (модули core, dom, tag, ns, html, ports/posix) вендорятся в `Sources/CLexbor/`
- [ ] C-таргет `CLexbor` добавлен в Package.swift с корректными header search paths
- [ ] Ручной `config.h` с необходимыми дефайнами (`LEXBOR_STATIC`, версия)
- [ ] `CLexbor` компилируется без ошибок на macOS 14+
- [ ] Тестовый вызов `lxb_html_document_parse()` работает из Swift-кода

### US-005: Добавить Lexbor в бенчмарки

**Описание:** Как разработчик, хочу видеть скорость парсинга Lexbor для сравнения с другими Swift-парсерами.

**Приёмочные критерии:**
- [ ] Функция `benchmarkLexbor(html:warmup:iterations:)` парсит HTML через Lexbor C API и возвращает `BenchmarkResult`
- [ ] Замер memory для Lexbor аналогичен HTMLParser
- [ ] Корректно создаётся и уничтожается `lxb_html_document_t` (без утечек памяти)
- [ ] Результаты отображаются в консоли и в BENCHMARK_RESULTS.md
- [ ] Бенчмарк компилируется и запускается

### US-006: Замер pipeline — body computation (CLI)

**Описание:** Как разработчик, хочу замерять полный pipeline парсинг + создание SwiftUI View body без UI-контекста.

`HTMLView.body` не требует `@MainActor` без custom renderers — безопасно замерять на любом потоке в CLI. Это baseline-замер: показывает стоимость преобразования AST → view tree. Без SwiftUI runtime body вычисляется "вхолостую" — не отражает layout, но показывает стоимость нашего кода.

**Приёмочные критерии:**
- [ ] Функция `benchmarkPipeline(html:warmup:iterations:)` замеряет `HTMLParser.parseFragment()` + `HTMLView(document:).body`
- [ ] Отдельно отображаются: время парсинга, время рендеринга body, суммарное время pipeline
- [ ] Результаты включены в BENCHMARK_RESULTS.md в секции "Pipeline"
- [ ] HTMLRenderer добавлен как зависимость бенчмарк-таргета
- [ ] Бенчмарк компилируется и запускается

### US-007: Замер pipeline — layout (DemoApp)

**Описание:** Как разработчик, хочу замерять body + layout pass через `UIHostingController.sizeThatFits()` для реальной оценки производительности рендеринга.

`sizeThatFits` — стандартный подход для библиотек. Проходит body evaluation + layout pass. Не включает растеризацию — измеряет то, что контролирует библиотека, без шума от Core Animation.

**Приёмочные критерии:**
- [ ] В DemoApp добавлен экран/кнопка "Run Benchmarks"
- [ ] Замер через `UIHostingController(rootView: HTMLView(...)).sizeThatFits(in: CGSize(width: 375, height: .infinity))`
- [ ] Замеряется отдельно: parse time, layout time (sizeThatFits), total pipeline
- [ ] Результаты отображаются в UI DemoApp
- [ ] Замеры для всех трёх размеров документов (small, medium, large)

### US-008: Обновить отчёт BENCHMARK_RESULTS.md

**Описание:** Как разработчик, хочу видеть единый отчёт со всеми парсерами, pipeline и сравнительными таблицами.

**Приёмочные критерии:**
- [ ] Секция "Parsers Comparison" — таблица median по всем парсерам для каждого размера
- [ ] Секция "Pipeline" — parse time + body/layout time + total для нашей библиотеки (CLI: body computation, DemoApp: sizeThatFits)
- [ ] Секция "Memory Comparison" — memory delta по всем парсерам
- [ ] Speedup каждого парсера относительно NSAttributedString(html:) как baseline
- [ ] BonMot помечен как "XML-adapted docs" с пояснительной сноской
- [ ] Отчёт генерируется автоматически при запуске бенчмарков
- [ ] Формат таблиц совместим с GitHub Markdown

## Функциональные требования

- FR-1: Зависимости SwiftSoup, swift-justhtml, BonMot добавляются только для бенчмарк-таргета, не для библиотечных таргетов
- FR-2: Lexbor вендорится как отдельный C-таргет `CLexbor` в `Sources/CLexbor/`, используется только бенчмарк-таргетом
- FR-3: Каждый альтернативный парсер замеряется теми же тестовыми документами (small, medium, large) из TestDocuments.swift
- FR-4: Для BonMot создаются XML-адаптированные версии тестовых документов (закрытые void elements, XML-safe entities, закрытые теги) + XMLStyleRule массив
- FR-5: Метрики для каждого парсера: average, median, p95, memory delta
- FR-6: Warmup: 10 итераций. Замер: 100 итераций. Совпадает с текущими настройками
- FR-7: Если парсер падает или бросает исключение на тестовом документе — в отчёте "failed", бенчмарк продолжает работу
- FR-8: CLI pipeline benchmark замеряет отдельно: parse time, body computation time, total time
- FR-9: DemoApp pipeline benchmark использует `UIHostingController.sizeThatFits(in:)` для замера body + layout pass
- FR-10: Отчёт BENCHMARK_RESULTS.md генерируется одним запуском `swift run -c release HTMLParserBenchmarks`
- FR-11: UI benchmark results отображаются в DemoApp и не пишутся в файл автоматически

## Не в скоупе

- Замер scroll performance (FPS) — отдельная задача
- Конкурентный парсинг (параллельные вызовы) — не включаем
- Сравнение рендеринга с другими библиотеками (только парсинг сравниваем между парсерами)
- Автоматический запуск бенчмарков в CI
- Интеграция Lexbor как альтернативного парсера для библиотеки (только бенчмарк)

## Технические решения

### Зависимости

```swift
// Package.swift — только для бенчмарк-таргета
.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.11.2"),
.package(url: "https://github.com/kylehowells/swift-justhtml.git", from: "0.3.3"),
.package(url: "https://github.com/Rightpoint/BonMot.git", from: "6.1.3"),
```

### Lexbor vendoring

- Исходники: модули `core`, `dom`, `tag`, `ns`, `html`, `ports/posix` из https://github.com/lexbor/lexbor v2.6.0
- Путь: `Sources/CLexbor/`
- Сохраняем оригинальную структуру директорий (`source/lexbor/{module}/`)
- cSettings: `.headerSearchPath("source")` для резолва `#include "lexbor/core/base.h"`
- ~340 файлов (.c + .h)
- Ручной `config.h` с дефайнами: `LEXBOR_STATIC`, `LEXBOR_VERSION_MAJOR/MINOR/PATCH`

### BonMot — XML-адаптация документов

Для каждого тестового документа (small, medium, large) создаём XML-адаптированную версию:
- Void elements закрыты: `<br>` → `<br/>`, `<hr>` → `<hr/>`, `<img ...>` → `<img .../>`
- HTML entities заменены: `&nbsp;` → `&#160;`, `&mdash;` → `&#8212;`
- Все теги закрыты
- XMLStyleRule массив для всех используемых тегов (базовые стили: шрифт, размер, цвет)

API вызов:
```swift
let rules: [XMLStyleRule] = [
    .style("p", StringStyle(.font(.systemFont(ofSize: 16)))),
    .style("h1", StringStyle(.font(.boldSystemFont(ofSize: 28)))),
    .style("strong", StringStyle(.font(.boldSystemFont(ofSize: 16)))),
    // ... для каждого тега
]
let result = try NSAttributedString.composed(ofXML: xmlDoc, rules: rules)
```

### Pipeline benchmark (CLI)

```swift
// Замер body computation без UI-контекста
// HTMLView.body не требует @MainActor без custom renderers
import HTMLRenderer

let parseTime = clock.measure {
    document = HTMLParser.parseFragment(html)
}
let renderTime = clock.measure {
    let view = HTMLView(document: document)
    _ = view.body  // force body computation, thread-safe
}
```

### Pipeline benchmark (DemoApp)

```swift
// Замер body + layout pass через sizeThatFits (main thread)
// sizeThatFits проходит body evaluation + layout, без растеризации
let parseTime = clock.measure {
    document = HTMLParser.parseFragment(html)
}
let layoutTime = clock.measure {
    let hosting = UIHostingController(rootView: HTMLView(document: document))
    _ = hosting.sizeThatFits(in: CGSize(width: 375, height: .infinity))
}
```

## Метрики успеха

- Все 6 парсеров (HTMLParser, NSAttributedString, SwiftSoup, swift-justhtml, Lexbor, BonMot) в едином отчёте
- Pipeline замеры показывают разбивку parse/render/total
- Отчёт генерируется одной командой
- Бенчмарки не ломают основную библиотеку (зависимости изолированы)
