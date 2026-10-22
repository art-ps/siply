<p align="center">
  <img src="site/assets/icon.png" width="128" height="128" alt="Иконка Siply">
</p>

<h1 align="center">Siply</h1>

<p align="center">
  Лёгкий музыкальный плеер для macOS, который играет прямо из папок.<br>
  Открыл папку — слушаешь. Без импорта и без медиатеки.<br>
  Siply — сокращение от Simple Player.
</p>

<p align="center">
  <a href="https://github.com/art-ps/siply/releases/latest"><b>Скачать для macOS</b></a> ·
  <a href="https://siply.top/">Сайт</a> ·
  <a href="README.md">English</a>
</p>

<p align="center">
  <img src="site/assets/screenshot.png" alt="Окно Siply: дерево папок слева, треки с обложками справа, плавающая панель плеера">
</p>

## Зачем

Музыкальные приложения хотят владеть коллекцией: импортировать, индексировать, синхронизировать. Siply делает наоборот. Ваши папки уже и есть медиатека, Siply показывает их в аккуратном окне в духе Apple Music и играет.

## Возможности

- **Папки вместо медиатеки.** Слева дерево папок, справа треки выбранной папки.
- **Родные форматы.** MP3, AAC/M4A, FLAC, WAV, AIFF, CAF — всё, что играет AVFoundation, включая lossless.
- **Теги и обложки.** Названия, артисты, альбомы и обложки берутся из тегов. Старые ID3 в Windows-1251 показываются кириллицей, а не кракозябрами.
- **Как в Apple Music.** Шапка альбома с кнопками «Воспроизвести» и «Перемешать», таблица треков, плавающая панель плеера с Liquid Glass на macOS 26.
- **Выбор устройства вывода.** Siply играет в Bluetooth-колонку, а системные звуки остаются на динамиках Mac. Если колонка отключилась, музыка не останавливается и вернётся на неё при подключении.
- **Открытие из Finder.** Двойной клик по аудиофайлу — его папка открывается в Siply, файл начинает играть, следом остальные треки папки. Файлы, которые Siply не сыграет, в списке не показываются.
- **Поиск в папке** и колонки, которые запоминают ширину.
- **Клавиатура и медиаклавиши.** Пробел — пауза, Enter — играть выбранный трек; работают Пункт управления и медиаклавиши.
- **Маленький и нативный.** Swift, SwiftUI и AVFoundation, ни одной сторонней зависимости.

## Установка

1. Скачайте `Siply-x.y.z.dmg` в [релизах](https://github.com/art-ps/siply/releases/latest).
2. Откройте образ и перетащите **Siply** в **Программы**.

Чтобы аудиофайлы открывались в Siply двойным кликом: в Finder выберите файл → «Свойства» (⌘I) → «Открыть в программе» → Siply → «Изменить всё».

Нужна macOS 14 Sonoma или новее. Универсальная сборка для Apple Silicon и Intel, подписана и нотаризована Apple.

## Сборка из исходников

```bash
brew install xcodegen
xcodegen generate
xcodebuild -scheme Siply -configuration Release build
```

Тесты: `xcodebuild test -scheme Siply -destination 'platform=macOS'`.
Релиз (подпись, нотаризация, DMG): `scripts/release.sh`, затем `scripts/sync-site.sh build/release/Siply-X.Y.Z.dmg` и закоммитить `site/`.

---

<p align="center">
  Собрано с помощью AI. Карточка проекта на <a href="https://vibecoded.ru/products/siply">vibecoded.ru</a>.
</p>
