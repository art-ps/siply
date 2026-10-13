# Siply — лёгкий файловый плеер для macOS

Дата: 2026-10-13. Статус: спека утверждена в brainstorming.

## Цель

Нативный macOS-плеер без библиотеки и базы. Пользователь открывает корневую папку
с музыкой (папки-исполнители / папки-альбомы, внутри файлы). Слева — дерево папок,
справа — треки выбранной папки, снизу — плеер-бар. Лёгкий: ноль внешних зависимостей.

Референс дизайна — окно плейлиста Apple Music (шапка с обложкой + таблица треков +
плавающий плеер-бар). Тема — системная (светлая/тёмная), не принудительная.

## Стек

- Swift 6, SwiftUI, macOS 14+ (deployment target), Xcode 26.
- Проект генерируется `xcodegen` из `project.yml` (`.xcodeproj` не коммитим).
- Воспроизведение: `AVAudioPlayer`. Метаданные/обложки: `AVURLAsset.load(.metadata)`.
- Now Playing / медиаклавиши: `MPRemoteCommandCenter`, `MPNowPlayingInfoCenter`.
- Тесты: XCTest.
- Без подписи и нотаризации — локальная сборка и запуск.

## Форматы

Только то, что декодирует AVFoundation нативно. Фильтр по расширению (без учёта
регистра): `mp3 m4a aac flac wav aif aiff caf`. ALAC приходит как `m4a`.
OGG/Opus/APE/WavPack — вне скоупа (нужна сторонняя либа).

## Архитектура

```
Siply/
  App/        SiplyApp.swift, AppCommands.swift (меню, ⌘O, ⌘R)
  Library/    FolderNode.swift, Track.swift, LibraryScanner.swift, Bookmarks.swift
  Player/     PlayerModel.swift, AudioEngine.swift (протокол + AVAudioPlayer-реализация), NowPlaying.swift
  UI/         ContentView.swift, SidebarView.swift, FolderView.swift, TrackTable.swift, PlayerBar.swift, EmptyStateView.swift
SiplyTests/   LibraryScannerTests.swift, PlayerModelTests.swift, Fixtures/
project.yml
```

### Модель

- `FolderNode`: `url`, `name`, `children: [FolderNode]` — только директории, скрытые
  (`.`-префикс и `isHidden`) пропускаем, сортировка по имени (локализованная,
  без учёта регистра). Дети загружаются лениво при раскрытии.
- `Track`: `id` (url), `url`, `title`, `artist`, `album`, `duration: TimeInterval`,
  `trackNumber: Int?`, `artwork: Data?`. `title` — из тегов, фолбэк на имя файла
  без расширения; `artist`/`album` — пустая строка если тега нет.
- `LibraryScanner.tracks(in: URL) async -> [Track]`: только файлы прямо в папке
  (не рекурсивно), фильтр по расширениям, теги тянем асинхронно параллельно,
  сортировка: `trackNumber` по возрастанию (nil — в конец), затем имя файла.
- `LibraryScanner.folderArtwork(for: URL, tracks:) -> Data?`: artwork первого
  трека, у которого он есть; иначе `cover.jpg|cover.png|folder.jpg` в папке; иначе nil.

### Плеер

- `AudioEngine` — протокол: `load(url) throws`, `play()`, `pause()`, `stop()`,
  `seek(to:)`, `volume`, `currentTime`, `duration`, `onFinished: () -> Void`.
  Реализация `AVAudioPlayerEngine`. В тестах — `FakeAudioEngine`.
- `PlayerModel` (`@Observable`, `@MainActor`):
  - состояние: `queue: [Track]`, `currentIndex: Int?`, `isPlaying`, `currentTime`,
    `volume` (0…1), `shuffle: Bool`, `repeatMode: off | all | one`.
  - `play(queue:startingAt:)` — ставит очередь, грузит трек, играет.
  - `togglePlayPause()`, `next()`, `previous()`, `seek(to:)`.
  - `previous()`: если `currentTime > 3` — перемотка в начало, иначе предыдущий трек.
  - конец трека: `repeat one` → тот же; иначе следующий; конец очереди при
    `repeat off` → стоп (остаёмся на последнем, `isPlaying = false`), при
    `repeat all` → первый.
  - shuffle: при включении — перемешиваем порядок обхода (текущий трек остаётся
    текущим), при выключении — возвращаем порядок папки. Храним `order: [Int]`.
  - нечитаемый файл (`load` бросил) → лог в консоль, сразу `next()`; если все
    треки очереди нечитаемы — стоп.
  - таймер прогресса 0.5 с, только пока играет.
- `NowPlaying`: публикует трек/обложку/прогресс в `MPNowPlayingInfoCenter`,
  подписывает play/pause/next/prev/seek в `MPRemoteCommandCenter`.

### Persistence (`UserDefaults`)

- `rootBookmark: Data` — security-scoped bookmark корневой папки.
- `volume`, `shuffle`, `repeatMode`.
- При старте: резолвим bookmark; папки нет → экран без корня. Stale bookmark, который резолвится в живую папку, принимаем и пересохраняем.

## UI

- `NavigationSplitView`: сайдбар + контент. Плеер-бар — overlay снизу контента
  (safe-area inset), в стиле плавающей панели.
- **Без корня**: `EmptyStateView` — иконка, текст «Откройте папку с музыкой»,
  кнопка «Открыть папку…».
- **Сайдбар**: `List` с `DisclosureGroup` по `FolderNode`, иконка папки, корень
  раскрыт и выбран при старте. Только папки, файлов нет.
- **FolderView** (выбранная папка):
  - шапка: обложка 200×200 (скруглённая, тень), имя папки, «N треков · M мин»,
    кнопки «Воспроизвести» (`play(queue: tracks, startingAt: 0)`) и
    «Перемешать» (то же + `shuffle = true`).
  - тулбар: поле поиска «Найти в папке» — фильтр таблицы по title/artist/album
    (подстрока, без учёта регистра).
  - `Table`: колонки «Песня» (миниатюра 32×32 + title), «Артист», «Альбом»,
    «Время» (`m:ss`). Двойной клик / Enter → `play(queue: tracks, startingAt: i)`
    (очередь — вся папка в несфильтрованном порядке). Играющий трек — иконка
    динамика вместо миниатюры.
  - папка без треков: «В этой папке нет музыки».
  - загрузка тегов: таблица показывается сразу с именами файлов, теги подъезжают.
- **PlayerBar**: shuffle, prev, play/pause, next, repeat (слева); обложка 40×40,
  title, «artist — album» (центр); слайдер прогресса с `currentTime` слева и
  `-remaining` справа; слайдер громкости (справа). Без трека — бар с
  disabled-кнопками и «—».
- Смена выбранной папки не трогает очередь.
- Клавиши: Space — play/pause (когда фокус не в поле поиска), ⌘→ / ⌘← — next/prev,
  ⌘O — открыть папку, ⌘R — пересканировать текущую папку. Медиаклавиши — через
  `MPRemoteCommandCenter`.
- Доступность: кнопки с `accessibilityLabel`, видимый фокус стандартный.

## Ошибки

- Нечитаемый трек → пропуск + `print`/`os_log`, без алертов.
- Корень недоступен при старте → экран без корня.
- Ошибка чтения директории → узел без детей, в консоль лог.

## Тесты

`LibraryScannerTests` (фикстуры — маленькие сгенерированные файлы в `Fixtures/`):
- фильтрует по расширениям, игнорирует `.hidden` и не-аудио;
- не заходит в подпапки;
- сортирует по trackNumber, потом по имени; треки без номера — в конец;
- фолбэк title на имя файла без расширения;
- `folderArtwork` берёт `cover.jpg`, когда у треков нет artwork.

`PlayerModelTests` с `FakeAudioEngine`:
- `play(queue:startingAt:)` грузит нужный url и играет;
- `onFinished` → следующий; конец очереди при `repeat off` → стоп;
- `repeat all` → первый; `repeat one` → тот же;
- `previous()` при `currentTime > 3` — seek(0), иначе предыдущий трек;
- shuffle не теряет текущий трек и обходит все; выключение — исходный порядок;
- `load` бросает → пропуск к следующему.

UI проверяется руками: открыть папку, дерево, таблица, double-click, бар, Control Center.

## Вне скоупа (сознательно)

OGG/Opus/APE/WavPack; плейлисты; избранное/рейтинги; редактирование тегов; gapless;
эквалайзер; несколько корневых папок; рекурсивный список треков; авто-rescan
(FSEvents); drag-and-drop; подпись/нотаризация/дистрибуция; iCloud/стриминг.

## Сборка

```
xcodegen generate
xcodebuild -scheme Siply -configuration Debug build
xcodebuild -scheme Siply test
```
