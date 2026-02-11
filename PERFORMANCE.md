# SwiftHTMLRenderer — Performance

## Цель

Быть быстрее нативных инструментов iOS для парсинга HTML:
- `NSAttributedString(data:options:documentAttributes:)` с `.documentType: .html`
- `XMLParser`

Оба инструмента крутят run loop при парсинге HTML. Это главная точка, в которой мы выигрываем: наш парсер работает синхронно, без run loop, без WebKit под капотом.

Конкретный множитель ускорения не фиксируем. Определим после первых замеров на реальных данных.

## Почему мы быстрее

`NSAttributedString(html:)` под капотом поднимает WebKit для парсинга HTML. Требует main thread и run loop. На небольших фрагментах оверхед инициализации WebKit доминирует над парсингом.

`XMLParser` — SAX-парсер. Работает через delegate callbacks, требует run loop. Не поддерживает невалидный HTML (strict XML).

SwiftHTMLRenderer:
- Чистый Swift-парсер, без зависимостей
- Синхронный, без run loop
- Работает на любом потоке
- Оптимизирован под HTML5 (не XML)
- Best-effort парсинг — не падает на невалидном HTML

## Что замеряем

### Метрики

| Метрика | Описание |
|---------|----------|
| **Parse time** | Время от HTML-строки до готового AST |
| **Render time** | Время от AST до готового SwiftUI View body |
| **Total pipeline** | Parse + Render + первый кадр на экране (time to first frame) |
| **Peak memory** | Максимальное потребление памяти во время парсинга |
| **Steady memory** | Потребление памяти после парсинга (размер AST в памяти) |

Каждая метрика замеряется отдельно для нашего парсера и для baseline (NSAttributedString, XMLParser).

### Размеры документов

Три категории тестовых документов:

| Категория | Размер | Пример |
|-----------|--------|--------|
| **Small** | < 1 KB | Комментарий, карточка товара, короткое описание |
| **Medium** | 1–10 KB | Статья, пост блога, страница документации |
| **Large** | 50+ KB | Длинная статья, changelog, документация API |

### Тестовые документы

Для каждой категории — набор фиксированных HTML-документов с разной сложностью:

1. **Plain text** — только параграфы и переносы строк
2. **Rich text** — параграфы, заголовки, жирный, курсив, ссылки
3. **Lists** — вложенные списки (ul/ol, 3+ уровня)
4. **Tables** — таблица 10x10, 50x5, разные размеры
5. **Mixed** — все элементы вперемешку, приближено к реальному контенту CMS
6. **Malformed** — невалидный HTML: незакрытые теги, вложенные ошибки

### Режимы замера

| Режим | Описание |
|-------|----------|
| **Single parse** | Один вызов парсера. Замеряем абсолютное время. |
| **Batch parse** | 100 последовательных вызовов. Среднее, медиана, p95, p99. |
| **Concurrent parse** | 10 параллельных парсингов. Проверяем thread safety и масштабируемость. |

## Baseline: что сравниваем

| Инструмент | Что делает | Ограничения |
|------------|-----------|-------------|
| `NSAttributedString(html:)` | Полный парсинг HTML → attributed string | Требует main thread, run loop, WebKit |
| `XMLParser` | SAX-парсинг XML | Strict XML, не HTML. Для сравнения скорости парсинга. |
| SwiftHTMLRenderer | Наш парсер | — |

Сравнение корректно только для парсинга. Рендеринг сравниваем с самими собой (регрессии), не с NSAttributedString — у них разный output.

## Как замеряем

### Инструмент

Swift Package `swift-collections-benchmark` или кастомный бенчмарк на `ContinuousClock` / `DispatchTime`.

```swift
let clock = ContinuousClock()

let parseTime = clock.measure {
    let result = HTMLParser.parse(html)
}

let renderTime = clock.measure {
    let view = HTMLRenderer.render(ast)
}
```

### Условия замера

- Release build (`-O`, без debug info)
- Реальное устройство (не симулятор)
- Прогрев: 10 итераций перед замером
- Минимум 100 итераций для статистики
- Отключены другие приложения
- Результаты: среднее, медиана, p95, p99, min, max

### Memory

`mach_task_basic_info` для peak memory. Замер до и после парсинга.

```swift
func currentMemory() -> Int {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), task_info_t(&info), &count)
    return Int(info.resident_size)
}
```

## Целевые показатели

### Парсинг

| Документ | Целевое время |
|----------|--------------|
| Small (< 1 KB) | < 1 ms |
| Medium (1–10 KB) | < 5 ms |
| Large (50+ KB) | < 50 ms |

Эти цифры — стартовые ориентиры. Скорректируем после первых замеров.

### Главный критерий

Парсинг быстрее `NSAttributedString(html:)` на всех размерах документов. NSAttributedString особенно медленный на мелких документах из-за оверхеда WebKit — там ожидаем максимальный отрыв.

### Память

- AST не должен потреблять больше 3x от размера исходного HTML
- Парсинг 50 KB документа не должен вызывать memory spike больше 10 MB

### Запуск бенчмарков

Ручной запуск. Отдельный таргет в SPM:

```
swift test --filter Benchmarks
```

Результаты сохраняются в файл для сравнения между версиями.

## Scroll performance (позже)

Замер FPS при скролле LazyVStack с HTML-ячейками — отдельная задача. Добавим после стабилизации парсера и рендерера.

## Оптимизации (потенциальные)

Не внедряем заранее. Список для справки, если замеры покажут проблемы:

- **Кеширование AST** — не парсить один и тот же HTML дважды
- **Lazy rendering** — рендерить только видимые элементы
- **String interning** — переиспользование строк для повторяющихся тегов/атрибутов
- **Copy-on-write AST** — модификация дерева без копирования
- **Pre-allocated buffers** — избежать реаллокаций при парсинге
