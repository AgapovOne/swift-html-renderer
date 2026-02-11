# Исследование: сторонний HTML5-парсер

## Контекст

SwiftHTMLRenderer использует сторонний HTML5-парсер. Наш модуль Parser — обёртка, конвертирующая результат в собственный AST. Spec-compliant парсер — отдельный проект на месяцы. Наша ценность — SwiftUI-рендеринг и API кастомизации.

## Требования

### Обязательные (must have)

| # | Критерий | Описание |
|---|----------|----------|
| 1 | HTML5 spec-compliant | WHATWG HTML Living Standard. Error recovery, implicit tag closure, optional closing tags, void elements, nesting rules, content model |
| 2 | Парсинг фрагментов | API-контент приходит без `<html><body>`. Фрагменты — основной сценарий |
| 3 | Встраиваемость в Swift | Чистый Swift, C, C++, ObjC, Rust через C FFI, Zig — любой язык, если встраивается в SPM |
| 4 | Синхронный API | Без run loop, без async. Пользователь сам решает, на каком потоке вызвать |
| 5 | Thread-safe | Работает на любом потоке без внешней синхронизации |
| 6 | Быстрее NSAttributedString(html:) | Главный бенчмарк — нативный парсер Apple |
| 7 | Минимальный memory footprint | Библиотека, не приложение. Размер имеет значение |
| 8 | iOS 17+ | Совместимость с целевой платформой |
| 9 | Без тяжёлых зависимостей | Минимум транзитивных зависимостей |
| 10 | Лицензия: permissive или MPL 2.0 | MIT, BSD, Apache 2.0, MPL 2.0. Без GPL/LGPL |

### Важные (should have)

| # | Критерий | Описание |
|---|----------|----------|
| 11 | DOM-подобное дерево на выходе | Чтобы конвертировать в наш AST. SAX-style API усложнит обёртку |
| 12 | Живой проект | Активная поддержка снижает риск |
| 13 | Небольшой размер бинарника | Каждый мегабайт — нагрузка на пользователей библиотеки |

### Приятные бонусы (nice to have)

| # | Критерий |
|---|----------|
| 14 | SPM-поддержка из коробки |
| 15 | Уже используется в iOS/macOS проектах |
| 16 | Доступ к ошибкам парсинга (warnings/errors) |
| 17 | HTML entity decoding |
| 18 | Whitespace normalization |

### Что делает сторонний парсер (не мы)

Из SPEC.md — всё это ответственность сторонней библиотеки:

- Error recovery, implicit tag closure, optional closing tags
- HTML entities (именованные, числовые, hex)
- Void elements, self-closing syntax
- Whitespace normalization
- Nesting rules и content model
- Case-insensitive tag/attribute names
- Document structure (`<html>`, `<head>`, `<body>`)

### Критерии отсева

| Причина отсева | Пояснение |
|---|---|
| XML-парсер, не HTML5 | Не обрабатывает error recovery, implicit tags, невалидный HTML |
| Заброшена (нет коммитов 2+ года) | Наследуем баги без исправлений |
| Только SAX / токенизатор, нет дерева | Слишком сложно конвертировать в AST |
| Часть большого фреймворка | Тянет тонну зависимостей |
| GPL/LGPL лицензия | Несовместима с требованиями |
| Нет поддержки фрагментов | Основной сценарий — контент без `<html><body>` |

---

## Кандидаты, прошедшие отбор

### 1. Lexbor (C)

- **Репозиторий:** https://github.com/lexbor/lexbor
- **Лицензия:** Apache 2.0
- **Активность:** высокая. PHP 8.4 (дек 2024) интегрировал Lexbor как стандартный HTML-парсер. Биндинги для Python, Ruby, Crystal, Julia, Elixir.
- **HTML5 compliance:** 100% WHATWG. Проходит html5lib-tests.
- **Фрагменты:** да — `lxb_html_document_parse_fragment()`.
- **Выход:** DOM-дерево (`lxb_dom_node_t`). Модульная архитектура.
- **Зависимости:** ноль. Чистый C.
- **Размер:** полная библиотека ~6 MB (83% — таблицы кодировок). HTML-модуль значительно меньше.
- **SPM:** нет готового пакета. Нужно создать C-таргет.
- **Плюсы:** самый feature-rich. DOM, CSS-селекторы, сериализация. Самый быстрый в бенчмарках среди C HTML5-парсеров.
- **Минусы:** больший codebase, чем Gumbo. Нет SPM-пакета.

### 2. Gumbo (Codeberg fork, C)

- **Репозиторий:** https://codeberg.org/gumbo-parser/gumbo-parser
- **Лицензия:** Apache 2.0
- **Активность:** средняя. v0.13.2 (сентябрь 2025). Продолжение архивированного google/gumbo-parser (~5.3k stars).
- **HTML5 compliance:** 100% html5lib. Протестирован на 2.5+ млрд страниц из индекса Google.
- **Фрагменты:** да — `gumbo_parse_fragment()`.
- **Выход:** read-only DOM-дерево (`GumboOutput` → `GumboNode`).
- **Зависимости:** ноль. Чистый C99.
- **Размер:** ~200–300 KB скомпилированный. ~10 C-файлов.
- **SPM:** **есть готовый пакет** — `SwiftGumbo` (SPM-обёртка CGumboParser).
- **Плюсы:** простейший API. Минимальный footprint. Проверенная SPM-интеграция.
- **Минусы:** read-only дерево (нет мутации). Нет CSS-селекторов и сериализации. Меньше фич, чем Lexbor.

### 3. swift-justhtml (Swift)

- **Репозиторий:** https://github.com/kylehowells/swift-justhtml
- **Лицензия:** MIT
- **Активность:** новый проект (декабрь 2025). Один автор, 194 коммита.
- **HTML5 compliance:** 100% html5lib (1831 тест). Порт Python-библиотеки justhtml.
- **Фрагменты:** да — `FragmentContext`.
- **Выход:** DOM-дерево. CSS-селекторы, экспорт в HTML/plain text/Markdown.
- **Зависимости:** ноль. Pure Swift + Foundation.
- **Размер:** нативный Swift, минимальный overhead.
- **SPM:** из коробки. Все Apple-платформы + Linux.
- **Перформанс:** ~97ms для 2.5MB HTML (5 статей Wikipedia). ~4x быстрее Python-версии.
- **Плюсы:** нативный Swift. Ноль зависимостей. SPM из коробки. 100% spec compliance.
- **Минусы:** очень молодой проект (1 релиз). Один автор. API может измениться.

### 4. SwiftSoup (Swift)

- **Репозиторий:** https://github.com/scinfu/SwiftSoup
- **Лицензия:** MIT
- **Активность:** высокая. v2.11.2 (ноябрь 2025). ~4900 stars.
- **HTML5 compliance:** частичная (~92%). Порт Java-библиотеки jsoup. Бесконечный цикл на 197 тестах `tests16.dat` (edge cases script-тегов).
- **Фрагменты:** да — `SwiftSoup.parseBodyFragment()`.
- **Выход:** DOM-дерево. jQuery-подобный API, CSS-селекторы.
- **Зависимости:** ноль. Pure Swift.
- **SPM:** из коробки.
- **Плюсы:** зрелый, популярный, хорошо протестирован на реальном HTML.
- **Минусы:** не проходит полный html5lib test suite. Edge cases с script-тегами.

### 5. html5ever (Rust)

- **Репозиторий:** https://github.com/servo/html5ever
- **Лицензия:** MIT / Apache 2.0 (dual)
- **Активность:** высокая. Используется в Servo. v0.38.0 (январь 2026).
- **HTML5 compliance:** 100% WHATWG. Browser-grade парсер.
- **Фрагменты:** да — `parse_fragment()`.
- **Выход:** дерево через `TreeSink` trait. Reference: `markup5ever_rcdom`.
- **Зависимости:** `markup5ever`, `tendril`, `log`. Умеренно.
- **Размер:** ~1–3 MB stripped static library.
- **SPM:** нет. Нужен C FFI wrapper + кросс-компиляция для iOS.
- **Плюсы:** эталонный парсер. Browser-grade. Активная поддержка Mozilla/Servo.
- **Минусы:** нужно написать C FFI обёртку. Кросс-компиляция Rust → iOS. Сложнейшая интеграция из всех кандидатов.

---

## Отсеянные библиотеки

| Библиотека | Язык | Причина отсева |
|---|---|---|
| Kanna | Swift (libxml2) | XML-парсер, не HTML5 |
| Fuzi | Swift (libxml2) | XML-парсер + заброшен 5+ лет |
| libxml2 | C | XML tree construction, не WHATWG HTML5 |
| MyHTML | C | LGPL + автор депрекейтнул в пользу Lexbor |
| Modest | C | LGPL + депрекейтнут |
| lol-html | Rust (C API) | Streaming rewriter, нет DOM-дерева |
| tl | Rust | Не HTML5 compliant, нет DOM-дерева |
| html5gum | Rust | Только токенизатор, нет tree construction |
| scraper | Rust | Обёртка над html5ever — лишний слой |
| kuchiki/dom_query | Rust | Обёртки над html5ever |
| tidy-html5 | C | Не WHATWG, «чистильщик», не парсер |
| hubbub | C | SAX-only, ~90% compliance, зависимости |
| HTMLKit (iabudiab) | ObjC | Заброшен 4+ года |
| HTMLReader | ObjC | Заброшен, Objective-C |
| ZMarkupParser | Swift | Не парсер, только NSAttributedString |
| rem | Zig | GPL |
| zhtml | Zig | Только токенизатор, незрел |
| SuperHTML | Zig | Инструмент, не библиотека для встраивания |
| alpha-html | Zig | LGPL + не HTML5 compliant |
| htmlcss | C | Не HTML5 compliant |
| Gumbo (Google) | C | Архивирован 2023, заменён Codeberg fork |

---

## Сравнение финалистов

| Критерий | Lexbor | Gumbo | swift-justhtml | SwiftSoup | html5ever |
|---|---|---|---|---|---|
| HTML5 compliance | 100% | 100% | 100% | ~92% | 100% |
| Фрагменты | Да | Да | Да | Да | Да |
| Язык | C | C | Swift | Swift | Rust |
| Лицензия | Apache 2.0 | Apache 2.0 | MIT | MIT | MIT/Apache |
| Зависимости | 0 | 0 | 0 | 0 | ~5 crates |
| SPM из коробки | Нет | Да (SwiftGumbo) | Да | Да | Нет |
| Размер бинарника | ~1–6 MB | ~200–300 KB | Нативный | Нативный | ~1–3 MB |
| Зрелость | Высокая (PHP 8.4) | Высокая (Google) | Низкая (дек 2025) | Высокая (4.9k★) | Высокая (Servo) |
| DOM mutation | Да | Нет (read-only) | Да | Да | Через TreeSink |
| CSS-селекторы | Да | Нет | Да | Да | Нет (отдельно) |
| Сложность интеграции | Средняя | Низкая | Минимальная | Минимальная | Высокая |
| Перформанс | Самый быстрый (C) | Быстрый (C) | Быстрый (Swift) | Средний | Быстрый (Rust) |
| Риски | Нет SPM-пакета | Read-only дерево | Молодой проект, 1 автор | Не 100% compliant | Сложная сборка |

---

## Решение

> Заполняется после обсуждения
