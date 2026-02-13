# PRD: SwiftHTMLRenderer v1.0.0 Release

## Introduction

Финальный набор задач перед релизом v1.0.0. Три направления: поддержка `<img>` (самый частый элемент в CMS-контенте), базовый accessibility для VoiceOver, и качественный README с примерами для публикации пакета.

Parser и Renderer полностью готовы: 35+ HTML-элементов, inline collapsing, три уровня кастомизации. Осталось закрыть пробелы, мешающие production-использованию.

## Goals

- Поддержать `<img>` с async-загрузкой и кастомизацией
- Обеспечить базовую accessibility-совместимость для VoiceOver
- Подготовить README для публикации на GitHub

## User Stories

### US-001: Дефолтный рендеринг `<img>` через AsyncImage

**Description:** Как пользователь библиотеки, я хочу чтобы `<img>` рендерился из коробки, чтобы HTML-контент с картинками отображался без дополнительной настройки.

**Acceptance Criteria:**
- [ ] `<img src="https://example.com/photo.jpg">` рендерится через SwiftUI `AsyncImage`
- [ ] Во время загрузки отображается `ProgressView` как placeholder
- [ ] При ошибке загрузки отображается системная иконка (`exclamationmark.triangle`)
- [ ] Атрибут `alt` отображается как accessibility label
- [ ] Атрибуты `width` и `height` задают размер через `.frame()` (если указаны оба)
- [ ] Если `width`/`height` не указаны — картинка подстраивается под доступную ширину (`.scaledToFit()`)
- [ ] Невалидный `src` (не URL) — показывает состояние ошибки
- [ ] Пустой `src` — `EmptyView()`
- [ ] `<img>` внутри `<figure>` рендерится корректно
- [ ] Тесты: рендеринг img с src, без src, с alt, с width/height
- [ ] Проект компилируется, существующие тесты проходят

### US-002: Кастомный рендеринг `<img>` через ViewBuilder

**Description:** Как пользователь библиотеки, я хочу подставить свой загрузчик картинок (Kingfisher, SDWebImage, свой кеш), чтобы контролировать загрузку и кеширование.

**Acceptance Criteria:**
- [ ] Новый `HTMLImageRenderer` компонент для `@HTMLContentBuilder`
- [ ] Closure получает `src: String?`, `alt: String?`, `attributes: [String: String]`
- [ ] Если задан кастомный renderer — `AsyncImage` не используется
- [ ] Приоритет: ViewBuilder > дефолтный AsyncImage (как у остальных элементов)
- [ ] Пример использования в коде теста или DemoApp
- [ ] Проект компилируется, существующие тесты проходят

### US-003: HTMLImageStyle в HTMLStyleConfiguration

**Description:** Как пользователь библиотеки, я хочу настраивать стили картинок через конфиг (contentMode, cornerRadius, maxHeight), чтобы не писать кастомный ViewBuilder для простых случаев.

**Acceptance Criteria:**
- [ ] В `HTMLStyleConfiguration` добавлено поле `image: HTMLImageStyle`
- [ ] `HTMLImageStyle` содержит: `contentMode: ContentMode?`, `cornerRadius: CGFloat?`, `maxHeight: CGFloat?`, `placeholderColor: Color?`
- [ ] Дефолтный рендерер `<img>` применяет стили из конфига
- [ ] Дефолтные значения: `contentMode = .fit`, остальное `nil`
- [ ] Тест: img с кастомным конфигом применяет стили
- [ ] Проект компилируется, существующие тесты проходят

### US-004: Accessibility — headings и images

**Description:** Как пользователь с VoiceOver, я хочу чтобы заголовки распознавались как headings, а картинки имели alt-text, чтобы контент был доступен.

**Acceptance Criteria:**
- [ ] `h1`-`h6` получают `.accessibilityAddTraits(.isHeader)`
- [ ] `<img>` с атрибутом `alt` получает `.accessibilityLabel(alt)`
- [ ] `<img>` без `alt` получает `.accessibilityHidden(true)` (декоративное изображение)
- [ ] `<a>` получает `.accessibilityAddTraits(.isLink)` (только когда есть onLinkTap)
- [ ] Тесты: проверка что view с заголовком содержит header trait
- [ ] Проект компилируется, существующие тесты проходят

### US-005: README для публикации

**Description:** Как разработчик, который нашёл библиотеку на GitHub, я хочу быстро понять что она делает, как подключить, и как использовать, чтобы решить — подходит ли она мне.

**Acceptance Criteria:**
- [ ] Секция "What it does" — краткое описание (Parser + Renderer)
- [ ] Секция "Install" — SPM dependency с обоими модулями (HTMLParser, HTMLRenderer)
- [ ] Секция "Quick Start" — минимальный пример HTMLView с HTML-строкой (3-5 строк кода)
- [ ] Секция "Customization" — примеры трёх уровней: StyleConfiguration, ViewBuilder, Visitor
- [ ] Секция "Supported Elements" — таблица поддерживаемых элементов
- [ ] Секция "Image Support" — пример дефолтного и кастомного рендеринга img
- [ ] Секция "Links" — пример onLinkTap
- [ ] Секция "Parser Only" — пример использования только HTMLParser без Renderer
- [ ] Секция "Requirements" — iOS 17+, Swift 6.2, SPM
- [ ] README на английском языке
- [ ] Проект компилируется

## Functional Requirements

- FR-1: `ElementRenderer` обрабатывает `case "img"` — рендерит через `AsyncImage` по умолчанию
- FR-2: `HTMLImageRenderer` — новый компонент `HTMLContentBuilder` для кастомного рендеринга картинок
- FR-3: `HTMLImageStyle` — структура стилей для картинок в `HTMLStyleConfiguration`
- FR-4: `HTMLCustomRenderers` получает поле `image` для хранения кастомного renderer
- FR-5: Заголовки h1-h6 получают accessibility trait `.isHeader`
- FR-6: Ссылки с onLinkTap получают accessibility trait `.isLink`
- FR-7: Картинки с `alt` получают `accessibilityLabel`, без `alt` — `accessibilityHidden(true)`
- FR-8: README.md переписан с полным описанием Parser + Renderer

## Non-Goals

- CSS inline parsing — пользователь парсит строку `style` из `attributes` самостоятельно
- `<details>/<summary>` — отложен на v1.1
- `colspan`/`rowspan` — отложен на post-v1
- DocC документация — пока только README
- GIF/анимированные изображения — стандартный AsyncImage не поддерживает, кастомный renderer решает
- Image caching — ответственность пользователя (через кастомный renderer)
- Полный accessibility: списки как accessibility containers, таблицы с row/column labels, семантические роли nav/main/article — post-v1

## Technical Considerations

- `AsyncImage` доступен с iOS 15+, ограничений для iOS 17+ нет
- `AsyncImage` не кеширует картинки между view updates — документировать в README что для production рекомендуется кастомный renderer
- `width`/`height` атрибуты в HTML — строки, нужен парсинг в CGFloat
- Inline collapsing не затрагивает `<img>` — это блочный элемент, всегда рендерится отдельным view
- Accessibility traits применяются через ViewModifier, не влияют на существующую логику рендеринга

## Success Metrics

- Все 54 существующих теста проходят без изменений
- Новые тесты для `<img>` и accessibility
- README содержит рабочие примеры кода (компилируются)
- Библиотека готова к тегу v1.0.0 после выполнения всех user stories

## Design Decision: `<img>` и inline collapsing

`<img>` внутри phrasing-контекста (например `<p>text <img> more text</p>`) **ломает inline collapsing**. Блок переключается на separate views — аналогично тому, как работают блочные элементы внутри `<p>`.

**Причина:** inline collapsing строит один `Text` через конкатенацию. SwiftUI `Text` поддерживает `Image` интерполяцию (`Text("\(Image(...))")`), но только синхронный `Image` — не `AsyncImage`. Для async-загрузки нет способа встроить картинку в `Text`.

**Будущие варианты** описаны в `docs/FAQ.md` → "Почему `<img>` ломает inline collapsing?"

## Open Questions

Нет.
