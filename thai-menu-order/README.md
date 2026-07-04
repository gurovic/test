# Thai Menu Order — HarmonyOS NEXT

Мобильное приложение для HarmonyOS: наводите камеру на тайское меню, получаете список блюд на английском, нажимаете на блюдо — телефон произносит его по-тайски для заказа.

## Как это работает

```
Камера → OCR (тайский текст) → Перевод (en) → Список блюд
                                              ↓ tap
                                         TTS (th-TH)
```

## Важные ограничения HarmonyOS

| Компонент | Встроенный API | Поддержка тайского |
|-----------|----------------|-------------------|
| OCR | `@kit.CoreVisionKit` | На устройстве: zh, en, ja, ko. **Тайский — через облако** |
| Перевод | Нет единого Kit | **Google Translate API** или Huawei ML Kit (cloud) |
| TTS | `@kit.CoreSpeechKit` | Только zh/en. **Тайский — через облачный TTS** |

Проект использует облачные API Google (Translate + Text-to-Speech) для тайского языка. Можно заменить на DeepL, Azure или Huawei ML Kit.

## Требования

- DevEco Studio 5.0+ (HarmonyOS NEXT)
- Реальное устройство Huawei (TTS не работает в эмуляторе)
- Google Cloud API key с включёнными:
  - Cloud Translation API
  - Cloud Text-to-Speech API

## Запуск

1. Откройте папку `thai-menu-order` в DevEco Studio
2. Подключите Huawei-устройство с HarmonyOS NEXT
3. Соберите и установите приложение
4. Введите API key в поле на главном экране
5. Нажмите **Scan menu**, сфотографируйте меню
6. Нажмите на блюдо — услышите тайское название

## Структура проекта

```
entry/src/main/ets/
├── entryability/EntryAbility.ets
├── pages/Index.ets              # UI
├── model/MenuDish.ets           # Типы данных
├── services/
│   ├── OcrService.ets           # Распознавание текста
│   ├── TranslationService.ets   # th → en
│   ├── ThaiTtsService.ets       # Озвучивание тайского
│   └── CameraCaptureService.ets # Съёмка с камеры
└── viewmodel/MenuViewModel.ets  # Бизнес-логика
```

## Дальнейшие улучшения

- **Live preview OCR** — распознавание кадров с камеры в реальном времени (CameraKit + ImageReceiver)
- **Облачный OCR для тайского** — Huawei ML Kit cloud text recognition (19 языков, включая th)
- **Офлайн-режим** — кэш переводов популярных блюд
- **Романизация** — показывать транскрипцию рядом с тайским текстом
- **Фильтрация цен** — улучшенный парсинг строк меню (цена отдельно от названия)

## Альтернатива без своего backend

Huawei **Vision Kit** с `Image.enableAnalyzer(true)` умеет «перевод по картинке», но UX другой (не список блюд с TTS). Для вашего сценария «тап → озвучить для официанта» нужен кастомный список + TTS.

## Лицензия

Apache-2.0
