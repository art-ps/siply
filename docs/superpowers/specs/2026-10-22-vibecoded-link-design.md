# Ссылка «проект vibecoded.ru» в тулбаре и в «О программе»

## Зачем

Siply — проект vibecoded.ru. Подпись со ссылкой на сайт, как в mac-transcribe (`Sources/MacTranscribeApp.swift`, `ProjectLink`).

## Поведение

1. Тулбар главного окна, правая часть (`ToolbarItem(placement: .primaryAction)`): «проект» (`.secondary`) + «vibecoded.ru» — `Link` на `https://vibecoded.ru`, `.fontWeight(.medium)`, `Color.accentColor`, `.help("https://vibecoded.ru")`. Общий шрифт `.callout`, `.fixedSize(horizontal: true, vertical: false)`, `HStack(alignment: .firstTextBaseline, spacing: 4)`.
2. На macOS 26+ у элемента скрыта общая стеклянная подложка (`.sharedBackgroundVisibility(.hidden)`), ниже — как получится по умолчанию.
3. Подпись видна, когда открыта библиотека (окно с сайдбаром). Заголовок окна (имя папки) и поиск не трогаем.
4. Стандартное окно «О программе Siply» показывает строку «проект vibecoded.ru», «vibecoded.ru» — кликабельная ссылка на `https://vibecoded.ru`. Через `Credits.rtf` в ресурсах приложения (стандартная панель подхватывает сама, без кода).
5. Только русский текст.

## Проверки

- Тест: `Bundle.main` содержит `Credits.rtf`; загруженный `NSAttributedString` содержит «проект vibecoded.ru»; у подстроки «vibecoded.ru» атрибут `.link` == `https://vibecoded.ru`.
- Все тесты зелёные: `xcodegen generate >/dev/null && xcodebuild test -scheme Siply -destination 'platform=macOS,arch=arm64' -derivedDataPath build`.
- Тулбар — визуально: отдельная копия сборки (не трогать запущенный Siply пользователя и его UserDefaults), скриншот.

## Не делаем

- Английскую локализацию.
- Ссылку на пустом экране «Открыть папку».
- Свою панель «О программе».
