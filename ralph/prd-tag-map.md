# PRD: HTMLTagMap — настраиваемость inline/block поведения тегов

## Введение

Библиотека HTMLRenderer решает за пользователя: какие HTML-теги inline, какие block, какие стили применять. Правила захардкожены в `phrasingTags`, `buildElementText()` switch, `ElementRenderer.body` switch. Пользователь может переопределить отдельные элементы через ViewBuilder, но не может заменить маппинг тегов.

HTMLTagMap — слой оверрайдов поверх встроенного рендеринга. Пустой TagMap = текущее поведение. Пользователь добавляет записи, чтобы переопределить конкретные теги. Остальные теги рендерятся встроенным рендерером.

## Цели

- Пользователь переопределяет inline/block поведение конкретных тегов через TagMap
- Inline-теги: closures `(Text, [String: String]) -> Text`
- Block-теги: `HTMLElementStyle` или ViewBuilder
- Пустой TagMap = текущее поведение (всё через встроенный рендеринг)
- Обратная совместимость: без TagMap = текущее поведение
- Без публичных style-структур — InlineStyles остаётся internal
- `.skip` позволяет явно отключить тег

## User Stories

### US-001: Создать типы HTMLTagMap и BlockTagBehavior

**Описание:** Как разработчик библиотеки, я создаю основные типы для TagMap.

**Контекст:**

Новый файл `Sources/HTMLRenderer/HTMLTagMap.swift`.

```swift
public struct HTMLTagMap: Sendable {
    public var inlineTags: [String: @Sendable (Text, [String: String]) -> Text]
    public var blockTags: [String: BlockTagBehavior]

    public init(
        inlineTags: [String: @Sendable (Text, [String: String]) -> Text] = [:],
        blockTags: [String: BlockTagBehavior] = [:]
    )
}

public enum BlockTagBehavior: Sendable {
    /// Стиль + renderWithInlineCollapsing. Простой вариант для стилизации блоков.
    case style(HTMLElementStyle?)
    /// Полный ViewBuilder — рендерит элемент целиком.
    case custom(@MainActor @Sendable (HTMLElement) -> AnyView)
    /// Пропустить тег — рендерится как unknown (skip tag, render children).
    case skip
}
```

Нет `BuiltInBlockTag`. Нет `.default`. Пустой TagMap = текущее поведение (все теги проходят через встроенный switch).

**Acceptance Criteria:**
- [ ] `HTMLTagMap` — public struct, Sendable
- [ ] `BlockTagBehavior` — public enum, Sendable, три case: style, custom, skip
- [ ] `HTMLTagMap.init` принимает оба словаря с пустыми дефолтами
- [ ] Typecheck проходит

---

### US-002: Fluent API для HTMLTagMap

**Описание:** Как пользователь библиотеки, я хочу удобно строить TagMap через fluent API.

**Контекст:**

```swift
extension HTMLTagMap {
    public func withInline(
        _ tag: String,
        _ transform: @Sendable @escaping (Text, [String: String]) -> Text
    ) -> HTMLTagMap

    public func withBlock(_ tag: String, _ behavior: BlockTagBehavior) -> HTMLTagMap

    public func withoutTag(_ tag: String) -> HTMLTagMap
}
```

Каждый метод возвращает копию (value semantics). `withoutTag` удаляет тег из обоих словарей (эффект: тег вернётся к встроенному рендерингу).

Пример:
```swift
HTMLTagMap()
    .withInline("b") { text, _ in text.italic() }       // <b> рендерит italic
    .withInline("highlight") { text, _ in text.foregroundStyle(.yellow) }  // новый inline тег
    .withBlock("callout", .style(.init(backgroundColor: .blue.opacity(0.1))))  // новый block тег
    .withBlock("table", .skip)                            // отключить table
```

**Acceptance Criteria:**
- [ ] `withInline` добавляет/заменяет inline closure
- [ ] `withBlock` добавляет/заменяет block behavior
- [ ] `withoutTag` удаляет тег из inlineTags и blockTags
- [ ] Методы не мутируют оригинал (возвращают копию)
- [ ] Tag names приводятся к lowercase
- [ ] Typecheck проходит

---

### US-003: HTMLTagMap как HTMLRendererComponent

**Описание:** Как пользователь библиотеки, я хочу класть HTMLTagMap внутрь `@HTMLContentBuilder`.

**Контекст:**

В `HTMLContentBuilder.swift`:

1. HTMLTagMap конформит `HTMLRendererComponent`:
```swift
extension HTMLTagMap: HTMLRendererComponent {
    public func apply(to renderers: inout HTMLCustomRenderers) {
        renderers.tagMap = self
    }
}
```

2. Добавить поле `tagMap: HTMLTagMap?` в `HTMLCustomRenderers`.

3. Обновить `merge()` — последний TagMap побеждает.

Использование:
```swift
// Переопределить один inline тег
HTMLView(document: doc) {
    HTMLTagMap()
        .withInline("b") { text, _ in text.italic() }
}

// Добавить кастомный block тег
HTMLView(document: doc) {
    HTMLTagMap()
        .withBlock("callout", .custom { element in
            AnyView(Text("!").padding().background(.yellow))
        })
}

// Миксовать с ViewBuilder компонентами
HTMLView(document: doc) {
    HTMLTagMap()
        .withInline("mark") { text, _ in text.foregroundStyle(.red) }
    HTMLHeadingRenderer { children, level, attrs in
        // ViewBuilder по-прежнему имеет высший приоритет
    }
}
```

**Acceptance Criteria:**
- [ ] `HTMLTagMap` конформит `HTMLRendererComponent`
- [ ] `HTMLCustomRenderers` содержит `tagMap: HTMLTagMap?`
- [ ] `merge()` обновлён — новый tagMap заменяет старый
- [ ] TagMap работает внутри `@HTMLContentBuilder` closure
- [ ] Typecheck проходит

---

### US-004: TagMap в ElementRenderer — block rendering

**Описание:** Как пользователь библиотеки, я хочу чтобы при наличии TagMap block-теги с записями рендерились по правилам TagMap, а остальные — встроенным рендерером.

**Контекст:**

В `HTMLView.swift` (`ElementRenderer`):

Rendering flow для каждого элемента:

1. **Custom ViewBuilder** (heading, paragraph, link, etc.) — проверяется ПЕРВЫМ, приоритет выше всего
2. **TagMap check** (если `custom.tagMap != nil`):
   - `tagMap.blockTags[element.tagName]`:
     - `.style(elementStyle)` → `renderWithInlineCollapsing(style: elementStyle)`
     - `.custom(closure)` → `closure(element)`
     - `.skip` → `renderUnknownElement()` (onUnknownElement callback срабатывает)
   - `tagMap.inlineTags[element.tagName]` → `renderInlineElement()`
   - Тег не найден в tagMap → **fallback к встроенному рендерингу** (текущий switch)
3. **Встроенный switch** (текущее поведение) — если tagMap == nil ИЛИ тег не в tagMap

Ключевое отличие от предыдущего подхода: тег не в TagMap = **встроенный рендеринг**, не unknown.

**Acceptance Criteria:**
- [ ] Custom ViewBuilder (heading, paragraph, etc.) приоритет выше TagMap
- [ ] `tagMap.blockTags[tag]` с `.style` рендерит через renderWithInlineCollapsing(style:)
- [ ] `tagMap.blockTags[tag]` с `.custom` вызывает closure
- [ ] `tagMap.blockTags[tag]` с `.skip` рендерит как unknown (onUnknownElement callback)
- [ ] `tagMap.inlineTags[tag]` рендерит как inline element
- [ ] Тег не в tagMap → встроенный рендеринг (текущий switch case)
- [ ] Без tagMap → текущий switch без изменений
- [ ] Тесты проходят
- [ ] Typecheck проходит

---

### US-005: TagMap в InlineTextBuilder — inline rendering

**Описание:** Как пользователь библиотеки, я хочу чтобы inline-теги с записями в TagMap рендерились по closures из TagMap.

**Контекст:**

В `InlineTextBuilder.swift`:

1. `canCollapseInline()` — добавить параметр `tagMap: HTMLTagMap?`:
   - Тег inline, если:
     a. Есть в `tagMap.inlineTags` (TagMap приоритет), ИЛИ
     b. Есть в `phrasingTags` (встроенный, если не перекрыт tagMap.blockTags), ИЛИ
     c. Есть в `customRenderers.tagInlineText`
   - Тег НЕ inline, если:
     a. Есть в `tagMap.blockTags` (переопределён как block)
     b. Не подходит ни под одно из правил выше

2. `buildElementText()` — добавить параметр `tagMap: HTMLTagMap?`:
   - Если тег в `tagMap.inlineTags`:
     a. Рекурсивно построить children Text (через `buildInlineText`)
     b. Передать в closure: `closure(childText, element.attributes)`
   - Если тег не в tagMap → текущий switch (встроенное поведение)

3. Специальный случай `<a>`:
   - `customRenderers.linkInlineText` проверяется ПЕРВЫМ
   - Если `<a>` в `tagMap.inlineTags`:
     a. Внутренне пробросить `linkURL` к листовым узлам через InlineStyles (как сейчас)
     b. Листовые узлы создают AttributedString с `.link`
     c. `foregroundColor` из `config.link.foregroundColor` (внутренне)
     d. После рекурсии — применить TagMap closure поверх для визуального стиля
   - Если `<a>` НЕ в tagMap → текущее поведение (встроенный switch)

4. Передать tagMap во все вызовы `canCollapseInline()` и `buildInlineText()` из HTMLView.swift.

**Acceptance Criteria:**
- [ ] Тег из `tagMap.inlineTags` коллапсируется в Text
- [ ] Closure из `tagMap.inlineTags` применяется к children Text
- [ ] `tagMap.blockTags` блокирует inline collapsing (тег не inline)
- [ ] `customRenderers.linkInlineText` приоритет выше TagMap для `<a>`
- [ ] `customRenderers.tagInlineText` приоритет выше TagMap для любого тега
- [ ] `<a>` с TagMap closure — ссылки кликабельны (AttributedString с .link)
- [ ] `<a>` цвет из `config.link.foregroundColor`
- [ ] `<br>` через TagMap closure корректно рендерит newline
- [ ] `<q>` через TagMap closure корректно рендерит кавычки
- [ ] Тег не в tagMap → текущее встроенное поведение
- [ ] Без tagMap → поведение идентично текущему
- [ ] Тесты проходят
- [ ] Typecheck проходит

---

### US-006: Тесты TagMap

**Описание:** Как разработчик, я хочу убедиться что TagMap работает корректно.

**Acceptance Criteria:**
- [ ] Пустой TagMap — всё рендерится как сейчас (встроенный рендеринг)
- [ ] `.withInline("b") { text, _ in text.italic() }` — `<b>` рендерит italic
- [ ] `.withInline("custom") { ... }` — новый inline тег коллапсируется в Text
- [ ] `.withBlock("div", .style(.init(backgroundColor: .red)))` — div со стилем
- [ ] `.withBlock("custom", .custom { ... })` — кастомный ViewBuilder
- [ ] `.withBlock("table", .skip)` — table рендерится как unknown
- [ ] `tagMap.inlineTags["div"]` — div становится inline вместо block
- [ ] Ссылки кликабельны при TagMap с custom `<a>` closure
- [ ] Custom ViewBuilder (HTMLHeadingRenderer) приоритет выше TagMap
- [ ] Тесты проходят
- [ ] Typecheck проходит

## Функциональные требования

- FR-1: `HTMLTagMap` — public struct, Sendable, с `inlineTags` и `blockTags`
- FR-2: `BlockTagBehavior` — enum с `.style`, `.custom`, `.skip`
- FR-3: Fluent API: `withInline()`, `withBlock()`, `withoutTag()`
- FR-4: HTMLTagMap конформит `HTMLRendererComponent` для ContentBuilder
- FR-5: Тег в TagMap → TagMap правила. Тег не в TagMap → встроенный рендеринг
- FR-6: `tagMap.blockTags` может переопределить inline тег как block (и наоборот)
- FR-7: `<a>` — только inline. LinkURL и foregroundColor обрабатываются системой внутренне
- FR-8: Приоритет: Custom ViewBuilder > TagMap > Встроенный рендеринг
- FR-9: `.skip` → тег рендерится как unknown, `onUnknownElement` callback вызывается
- FR-10: Обратная совместимость: без TagMap / пустой TagMap = текущее поведение

## Не в скоупе

- Публичная структура InlineTextStyles — InlineStyles остаётся internal
- Изменение приоритета Custom ViewBuilder vs TagMap (ViewBuilder всегда выше)
- Deprecation существующего API (HTMLContentBuilder components работают как раньше)
- `<a>` как block-тег в TagMap (только inline, block через HTMLLinkRenderer)
- `.default` TagMap / `BuiltInBlockTag` — не нужны, fallback к встроенному рендерингу
- Вложенные TagMap (один TagMap на рендерер)
- Бенчмарк closure-based vs style accumulation
- tagMap как отдельный параметр HTMLView.init (только ContentBuilder)

## Технические ограничения

- Словарь с closures не может быть Equatable/Hashable — проверить, не ломает ли это HTMLCustomRenderers
- Swift 6.2 strict concurrency: inline closures `@Sendable`, block closures `@MainActor @Sendable`
- iOS 17+ minimum deployment target
- `canCollapseInline()` должен учитывать ОБА источника inline-тегов: tagMap.inlineTags И phrasingTags (для тегов не в tagMap)

## Метрики успеха

- Пользователь переопределяет inline-стиль одной строкой
- Пользователь делает тег block/inline одной строкой
- Пустой TagMap визуально идентичен текущему рендерингу
- Существующие тесты проходят без изменений
