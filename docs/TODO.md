# TODO: HTMLRenderer

## Environment closures invalidation

**Проблема:** `HTMLCustomRenderers` содержит closures, которые не `Equatable`. При обновлении parent view SwiftUI инвалидирует все `ElementRenderer`, потому что не может доказать, что Environment value не изменился.

**Масштаб:** для документа с 200 узлами — 200 views пересчитываются при каждом обновлении parent, даже если HTML не менялся.

**Рассмотренные решения:**

1. **Reference wrapper + @State** — `HTMLCallbacks` class в `@State`. Решает invalidation, но `@State(initialValue:)` не обновляется при смене closures. Динамические closures (пользователь меняет `onLinkTap` при обновлении) — баг.

2. **Объединить Environment keys** — 3 keys → 1. Упрощает код, но не решает invalidation.

3. **Передавать через stored properties** — убрать Environment для closures. Решает invalidation, но prop drilling через всю рекурсию.

**Для решения нужно:**
- Определить, поддерживаем ли динамические closures (пользователь меняет `onLinkTap` между render-ами)
- Если нет → reference wrapper + @State
- Если да → нужен механизм обновления (@State + onChange или другой подход)

**Детальный анализ:** `docs/RENDERER_FIXES.md`, секция "Проблема 5"

---

## ForEach с \.offset

**Проблема:** `ForEach(Array(children.enumerated()), id: \.offset)` — позиционный ID. `Array(enumerated())` аллоцируется при каждом вызове body.

**Почему отложено:** AST immutable, массивы не меняются. `\.offset` стабилен. Добавление `id` в AST ломает `Equatable`. Аллокация на 5-20 элементах — наносекунды.

**Возможное улучшение:** если AST станет мутируемым (partial updates) — пересмотреть.

---

## AnyView в кастомных рендерерах

**Проблема:** `AnyView(render(...))` стирает тип, SwiftUI не оптимизирует diff.

**Почему отложено:** только custom renderer path. Дефолтный рендеринг без AnyView. Generic альтернатива требует 9+ type parameters — невозможный API.

**Возможное улучшение:** Swift evolution — если появятся type-erased opaque types в closures.

---

## ifLet в applyStyle()

**Проблема:** `if/else` в `@ViewBuilder` создаёт `_ConditionalContent`. До 7 вложенных conditional в `applyStyle()`.

**Почему отложено:** branches стабильны (стили не меняются динамически). Альтернатива (всегда применять модификатор) ломает каскадирование стилей.

---

## Пересчёт listItems/tableRows/tableCells

**Проблема:** `compactMap`/`flatMap` при каждом вызове body.

**Почему отложено:** immutable arrays, фильтрация 3-10 элементов — наносекунды. Даже таблица 50x5 — микросекунды.

---

## canCollapseInline без мемоизации

**Проблема:** рекурсивный обход при каждом render блочного элемента.

**Почему отложено:** типичная глубина 2-4 уровня. Кэширование требует external state. Проблема только на патологическом HTML (100+ уровней вложенности).
