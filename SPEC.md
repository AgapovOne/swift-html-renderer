# SwiftHTMLRenderer — Specification

## Overview

SwiftHTMLRenderer — библиотека для парсинга HTML5 и рендеринга в нативные SwiftUI-вью. Предназначена для отображения rich-text контента из API, CMS, документации и любого HTML-форматированного текста.

Библиотека **не рендерит веб-страницы целиком**. Она работает с HTML-контентом: статьи, комментарии, справка, форматированный текст.

## Architecture

Два независимых модуля:

1. **Parser** — парсит HTML-строку в AST (Abstract Syntax Tree)
2. **Renderer** — рендерит AST в SwiftUI-вью

Модули можно использовать отдельно. Parser — без Renderer. Renderer — с AST, собранным вручную.

## Platform

- iOS 17+
- Дополнительные платформы — позже

## Parser

### Threading

Парсер синхронный. Работает на любом потоке. Пользователь сам решает: вызвать на main thread или диспатчить в бэкграунд.

Библиотека не управляет потоками. Immutable AST гарантирует thread safety — парсинг в бэкграунде, рендеринг на main thread без data races.

### Caching

Библиотека не кеширует AST. Пользователь сам решает, как хранить результат парсинга. Immutable и Hashable AST упрощает кеширование на стороне пользователя.

### Input

HTML-строка (`String`). Полный документ или фрагмент.

### Output

- Публичный AST — дерево элементов
- Список ошибок/предупреждений, найденных при парсинге

### Parsing strategy

Best-effort парсинг:
- Восстанавливается при ошибках, как браузеры
- Незакрытые теги — закрывает автоматически
- Неизвестные теги — сохраняет в AST как есть
- Возвращает результат + массив диагностик (ошибки, предупреждения)

### HTML entities

Полная поддержка:
- Именованные: `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&nbsp;`, `&copy;` и все остальные
- Числовые: `&#123;`
- Hex: `&#x1F600;`

### AST

Публичный, immutable, value types (structs). Equatable, Hashable.

Пользователь может:
- Инспектировать дерево
- Обходить дерево (visitor pattern)
- Создавать новое дерево на основе существующего (трансформация)
- Строить дерево вручную

Модификация = создание нового дерева. Это гарантирует thread safety и эффективное сравнение (SwiftUI diffing).

### Whitespace handling

Парсер схлопывает пробелы по правилам HTML:
- Несколько пробелов подряд → один пробел
- Переносы строк → пробел
- Пробелы в начале и конце блочных элементов — удаляются
- `<br>` — явный перенос строки
- `<pre>` (когда будет поддержан) — пробелы сохраняются как есть

Парсер знает block/inline-классификацию элементов по HTML-спецификации. Это свойство HTML, не рендеринга. AST хранит уже нормализованный текст.

### Attributes

Парсер сохраняет все атрибуты элемента и передаёт их в рендерер. Пользователь получает доступ ко всем атрибутам через словарь `[String: String]`.

Включая: `class`, `id`, `data-*`, `title`, `lang`, `style` (как сырая строка, без CSS-парсинга), `href`, `colspan`, и любые другие.

Boolean-атрибуты (`<details open>`, `<input disabled>`) хранятся как `["open": "open"]`, `["disabled": "disabled"]` — по HTML-спецификации.

### CSS

Не поддерживается в v1. Ни inline, ни `<style>`, ни внешние стили. Атрибут `style` сохраняется как сырая строка в атрибутах элемента. Может быть добавлено позже.

## Renderer

### Inline collapsing

Дефолтная стратегия: inline-элементы (`<b>`, `<i>`, `<u>`, `<s>`, `<a>`, `<sub>`, `<sup>`, `<span>`) внутри блочного элемента схлопываются в **один** SwiftUI view. Стили хранятся как атрибуты внутри одного view, а не как вложенные views.

Если пользователь задаёт ViewBuilder для inline-элемента — рендерер переключается на отдельные views для этого блока.

Это гибридный подход: максимальная производительность по умолчанию, гибкость при необходимости.

### Default rendering

Рендерер работает из коробки с дефолтными стилями. Пользователь переопределяет только то, что нужно.

### Interactivity

Только чтение. Формы, инпуты, кнопки — не поддерживаются.

Ссылки (`<a href>`) — вызывают callback пользователя с URL. Пользователь решает, что делать. Если callback не предоставлен — ссылка рендерится как стилизованный текст (подчёркивание, цвет), но не кликабельна.

### Customization priority

Если задано несколько уровней для одного элемента, приоритет:
1. **ViewBuilder closure** — высший приоритет, полностью заменяет рендеринг
2. **Style Configuration** — применяется, если нет ViewBuilder
3. **Дефолтные стили** — если ничего не задано

Visitor protocol — отдельный механизм. Заменяет весь пайплайн рендеринга. Не комбинируется с ViewBuilder и Style config.

### Three levels of customization

#### 1. Style Configuration

Простой конфиг: шрифты, цвета, отступы для каждого типа элемента.

```swift
var config = HTMLStyleConfiguration()
config.heading1.font = .largeTitle
config.heading1.foregroundColor = .blue
config.paragraph.font = .body
config.paragraph.lineSpacing = 4

HTMLView(html: myHTML, configuration: config)
```

Подходит для быстрой настройки без кастомных вью.

#### 2. ViewBuilder Closures

Полный контроль над рендерингом конкретного элемента. Библиотека передаёт контент и атрибуты — пользователь возвращает любой `View`.

```swift
HTMLView(html: myHTML) {
    Heading { content, attributes in
        Text(content)
            .font(.largeTitle)
            .foregroundColor(.blue)
    }

    Link { text, href, attributes in
        Button(text) { openURL(href) }
            .foregroundColor(.red)
    }
}
```

Что не переопределено — рендерится дефолтными стилями.

#### 3. Visitor Protocol

Общий механизм обхода AST, не привязанный к рендерингу. Пользователь определяет ассоциированный тип результата.

```swift
protocol HTMLVisitor {
    associatedtype Result
    func visitHeading(_ node: HeadingNode) -> Result
    func visitParagraph(_ node: ParagraphNode) -> Result
    func visitText(_ node: TextNode) -> Result
    // ...
}
```

Применения:
- Кастомный рендеринг (Result = `some View`)
- Аналитика (Result = `[String]`, подсчёт слов, сбор ссылок)
- Трансформация (Result = `HTMLNode`, изменение дерева)
- Экспорт (Result = `String`, конвертация в Markdown/plain text)

### Unknown elements

Неизвестные/неподдерживаемые теги — вызывают callback пользователя. Callback возвращает `some View`:

```swift
HTMLView(html: myHTML, onUnknownElement: { element in
    // Return any View: custom rendering, or EmptyView to skip
    Text(element.textContent)
        .foregroundColor(.gray)
})
```

Если callback не предоставлен — тег пропускается, но дети рендерятся. Это безопасный дефолт: структурные обёртки исчезают, контент остаётся.

### Accessibility

Базовый маппинг HTML-семантики в SwiftUI accessibility:
- Headings → accessibility heading trait
- Links → accessibility link trait
- Lists → соответствующие accessibility-аннотации

Остальное — ответственность пользователя через кастомные рендереры.

## Supported HTML Elements (v1)

### Text

| Element | Description |
|---------|-------------|
| `<h1>` — `<h6>` | Заголовки |
| `<p>` | Параграф |
| `<span>` | Inline-контейнер |
| `<br>` | Перенос строки |
| `<b>`, `<strong>` | Жирный текст |
| `<i>`, `<em>` | Курсив |
| `<u>` | Подчёркивание |
| `<s>`, `<del>` | Зачёркивание |
| `<a>` | Ссылка |
| `<sub>` | Подстрочный текст |
| `<sup>` | Надстрочный текст |

### Lists

| Element | Description |
|---------|-------------|
| `<ul>` | Неупорядоченный список |
| `<ol>` | Упорядоченный список |
| `<li>` | Элемент списка |

### Tables

| Element | Description |
|---------|-------------|
| `<table>` | Таблица |
| `<thead>` | Заголовок таблицы |
| `<tbody>` | Тело таблицы |
| `<tfoot>` | Подвал таблицы |
| `<tr>` | Строка |
| `<th>` | Ячейка заголовка |
| `<td>` | Ячейка данных |

**Ограничения v1:** `colspan` и `rowspan` не поддерживаются. Только простые таблицы.

### Semantic Containers

| Element | Description |
|---------|-------------|
| `<div>` | Блочный контейнер |
| `<article>` | Блочный контейнер (семантический) |
| `<section>` | Блочный контейнер (семантический) |
| `<main>` | Блочный контейнер (семантический) |
| `<header>` | Блочный контейнер (семантический) |
| `<footer>` | Блочный контейнер (семантический) |
| `<nav>` | Блочный контейнер (семантический) |
| `<aside>` | Блочный контейнер (семантический) |
| `<figure>` | Блочный контейнер (семантический) |
| `<figcaption>` | Подпись к figure |

### Code

| Element | Description |
|---------|-------------|
| `<code>` | Inline-код (моноширинный шрифт) |
| `<pre>` | Блок преформатированного текста (пробелы сохраняются) |

### Blockquote

| Element | Description |
|---------|-------------|
| `<blockquote>` | Цитата |

### Other

| Element | Description |
|---------|-------------|
| `<hr>` | Горизонтальная линия |

## Not in v1

Эти элементы и фичи запланированы на будущее:

- Images (`<img>`)
- Details/Summary (`<details>`, `<summary>`)
- CSS parsing (inline, embedded, external)
- Forms and interactive elements
- Additional platforms (macOS, visionOS)
- Streaming/incremental parsing
