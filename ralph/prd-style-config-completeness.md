# PRD: Полная настраиваемость StyleConfiguration

## Введение

HTMLStyleConfiguration позволяет кастомизировать стили элементов — font, color, padding, border. Но три места в рендерере игнорируют config и используют захардкоженные значения. Нужно довести config до полной работоспособности: каждое поле в config должно реально влиять на рендеринг.

## Цели

- Каждое поле `HTMLStyleConfiguration` реально управляет рендерингом — нет проигнорированных значений
- Добавить `ListNumberFormat` для OL нумерации
- Обратная совместимость: `.default` даёт идентичный результат
- Никаких новых элементов в config (figcaption, dd, sub, sup не добавляем)

## User Stories

### US-001: Blockquote border toggle

**Описание:** Как разработчик, я хочу отключать левый бордер blockquote через config, чтобы стилизовать цитаты без вертикальной линии.

**Контекст:**
Сейчас blockquote border width и color уже читаются из `config.blockquote`:
```swift
.frame(width: config.blockquote.borderWidth ?? 3)
.foregroundStyle(config.blockquote.borderColor ?? ...)
```
Но overlay рисуется **всегда** — даже если `borderWidth: 0`. Нет проверки на `> 0`.

**Что сделать:**
Обернуть overlay в условие: если `borderWidth` равен 0, не рисовать бордер. Кто хочет убрать бордер — ставит `config.blockquote.borderWidth = 0`.

**Acceptance Criteria:**
- [ ] `config.blockquote.borderWidth = 0` → бордер не рисуется
- [ ] `config.blockquote.borderWidth = 5` → бордер 5pts (как и сейчас работает)
- [ ] `.default` config → бордер 3pts слева (без изменений)
- [ ] Тесты проходят
- [ ] Typecheck проходит

---

### US-002: OL numbering format

**Описание:** Как разработчик, я хочу менять формат нумерации упорядоченных списков (decimal, alpha, roman), чтобы не писать custom ViewBuilder для простой смены стиля.

**Контекст:**
Сейчас OL использует `Text("\(index + 1).")` — только decimal. Нет конфигурации.

**Что сделать:**

1. Создать enum `ListNumberFormat`:
```swift
public enum ListNumberFormat: Sendable {
    case decimal        // 1. 2. 3.
    case lowerAlpha     // a. b. c.
    case upperAlpha     // A. B. C.
    case lowerRoman     // i. ii. iii.
    case upperRoman     // I. II. III.
    case custom(@Sendable (Int) -> String)
}
```

2. Добавить поле в `HTMLStyleConfiguration`:
```swift
public var listNumberFormat: ListNumberFormat  // default: .decimal
```

3. Использовать в `renderOrderedList()`:
```swift
Text(config.listNumberFormat.format(index))
```

**Conformance:**
- `ListNumberFormat` должен быть `Sendable`
- Enum с associated value `@Sendable` closure — не может быть `Equatable`/`Hashable` автоматически
- Варианты: (a) отказаться от Equatable для ListNumberFormat, (b) сравнивать только по case без closure
- Выбираем (a) — `ListNumberFormat` не Equatable. Это не влияет на `HTMLStyleConfiguration`, если она и так не Equatable (проверить)

**Acceptance Criteria:**
- [ ] `.decimal` → "1." "2." "3." (текущее поведение)
- [ ] `.lowerAlpha` → "a." "b." "c." ... "z." "aa." ...
- [ ] `.upperAlpha` → "A." "B." "C."
- [ ] `.lowerRoman` → "i." "ii." "iii." "iv." ...
- [ ] `.upperRoman` → "I." "II." "III." "IV." ...
- [ ] `.custom { "\($0 + 1))" }` → "1)" "2)" "3)"
- [ ] `.default` config → decimal (без изменений)
- [ ] Typecheck и strict concurrency проходят

---

### US-003: kbd использует config.keyboard

**Описание:** Как разработчик, я хочу стилизовать `<kbd>` через `config.keyboard`, чтобы менять padding, border и cornerRadius без ViewBuilder.

**Контекст:**
Сейчас kbd вызывает `applyStyle(config.keyboard, skipFont: true)`, но потом **поверх** добавляет:
- `.padding(.horizontal, 3)` — перезаписывает config padding
- `.padding(.vertical, 1)` — перезаписывает config padding
- `.overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1))` — перезаписывает config border

Config `keyboard` содержит только `font` в дефолте, но padding/border/cornerRadius игнорируются, даже если пользователь их задал.

**Что сделать:**
Переписать kbd рендеринг по паттерну pre/blockquote — сначала читать config с fallback:

```swift
case "kbd":
    renderChildren()
        .font(config.keyboard.font ?? .system(.body, design: .monospaced))
        .padding(config.keyboard.padding ?? EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3))
        .overlay(
            RoundedRectangle(cornerRadius: config.keyboard.cornerRadius ?? 3)
                .stroke(
                    config.keyboard.borderColor ?? Color.gray,
                    lineWidth: config.keyboard.borderWidth ?? 1
                )
        )
        .applyStyle(config.keyboard, skipFont: true, skipPadding: true, skipCornerRadius: true, skipBorderWidth: true)
```

**Обновить `.default` config** — добавить полные значения для keyboard:
```swift
keyboard: HTMLElementStyle(
    font: .system(.body, design: .monospaced),
    padding: EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3),
    cornerRadius: 3,
    borderColor: Color.gray,
    borderWidth: 1
)
```

**Acceptance Criteria:**
- [ ] `config.keyboard.padding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)` → применяется
- [ ] `config.keyboard.borderColor = .blue` → синий бордер
- [ ] `config.keyboard.cornerRadius = 8` → скруглённый бордер
- [ ] `config.keyboard.borderWidth = 0` → нет бордера (проверить)
- [ ] `.default` config → визуально идентичный результат (padding 1/3, gray border 1pt, radius 3)
- [ ] Тесты проходят
- [ ] Typecheck проходит

---

## Функциональные требования

- FR-1: Blockquote overlay не рисуется при `borderWidth == 0` (или nil, fallback на 3)
- FR-2: Новый enum `ListNumberFormat` с 5 встроенными + custom closure
- FR-3: Новое поле `listNumberFormat` в `HTMLStyleConfiguration` (default: `.decimal`)
- FR-4: `renderOrderedList()` использует `config.listNumberFormat`
- FR-5: kbd рендеринг использует `config.keyboard` для padding, border, cornerRadius
- FR-6: `.default` config обновлён с полными значениями для keyboard
- FR-7: Все изменения обратно совместимы — `.default` даёт идентичный визуальный результат

## Не в скоупе

- Новые поля в config для figcaption, mark, dd, sub, sup (редкие элементы)
- Изменение alignment блоков/списков (layout concern, не стиль)
- Изменение table cell alignment
- Добавление borderPosition для blockquote (достаточно leading/none через borderWidth)
- Nested list numbering (отдельные настройки для вложенных OL)

## Технические ограничения

- `ListNumberFormat` с `@Sendable` closure не может быть `Equatable`/`Hashable`. Проверить, ломает ли это `HTMLStyleConfiguration` conformance
- Swift 6.2 strict concurrency: все closures `@Sendable`
- iOS 17+ minimum deployment target

## Метрики успеха

- Все 3 ранее захардкоженных параметра управляются через config
- Нет визуальных регрессий с `.default` config
- Тесты и typecheck проходят

## Открытые вопросы

- Нужен ли `Equatable` для `HTMLStyleConfiguration`? Если да — `ListNumberFormat` с closure это ломает. Проверить текущие conformances.
