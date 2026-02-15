# SwiftHTMLRenderer — Project Rules

## What This Is

Библиотека для рендеринга HTML в SwiftUI views. Парсинг HTML — через зависимость [swift-lexbor](https://github.com/AgapovOne/swift-lexbor). Для rich-text контента из API, CMS, документации — не для рендеринга веб-страниц.

## Targets of library

- Скорость
- Качество (== Тестирование + расширяемый публичный интерфейс)
- Продуманное дефолтное поведение, доступное к расширению
- Простота использования

## Status

Библиотека в стадии активной разработки. Миграций нет, потому что нет пользователей. Обновления публичного интерфейса - норма, ведь мы на этапе проектирования.

## Architecture Decisions

### Renderer

- `HTMLView` — SwiftUI view из `HTMLDocument`.
- Два уровня кастомизации: ViewBuilder closures и Visitor protocol.
- Named renderers (heading, link, ...) + tag-based renderers (htmlTag, htmlTagInlineText, htmlSkipTag).
- Приоритет: named > tag block > tag inline > built-in > unknown.
- Inline collapsing: phrasing content схлопывается в один Text через AttributedString.
- Ссылки кликабельны всегда — через `onLinkTap` callback или `OpenURLAction`.
- Неизвестные элементы — пропускаем тег, рендерим детей.
- Таблицы через SwiftUI `Grid` (без colspan/rowspan).

## Platform

- iOS 17+
- Swift 6.2, strict concurrency
- SPM only. Без CocoaPods/Carthage.

## Testing Strategy

Тестируем рендерер через публичный API, без моков. Парсерные тесты — в swift-lexbor.

## Code Style

- Язык кода: English (имена типов, функций, переменных, комментарии).
- Язык документов: Russian (docs/, PRD, обсуждения).
- Минимум комментариев. Комментарий нужен только там, где код неочевиден.
- Без лишних абстракций. Три одинаковые строки лучше, чем преждевременная абстракция.

## Project Structure

```
Sources/
  HTMLRenderer/      — SwiftUI renderer module
Tests/
  HTMLRendererTests/ — Renderer tests
docs/                — SPEC.md, FAQ.md, PROGRESS.md
ralph/               — Ralph PRDs and archive
```

## Documentation

- `docs/SPEC.md` — возможности библиотеки (элементы, поведение, кастомизация)
- `docs/FAQ.md` — обоснования архитектурных решений
- `docs/PROGRESS.md` — прогресс, планы и известные ограничения

## Ralph

Когда работа выполняется с помощью ralph скрипта из claude, и используются prd.json, progress.txt и prd-*.md, то:
- Папка для всего - ralph/
- Предыдущие PRD положи в ralph/archive/* с названием PRD md документа
- Актуальные PRD и prd.json, progress.txt положи в ralph/
- При выполнении user story - делай коммиты по каждому user story
