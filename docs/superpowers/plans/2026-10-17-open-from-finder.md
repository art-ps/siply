# Открытие файла из Finder — план реализации

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Двойной клик по аудиофайлу в Finder открывает его папку корнем Siply и играет файл; неиграемые файлы скрыты из списка.

**Architecture:** Фильтр играемости — в `LibraryScanner.tracks(in:)`. Логика «открыть файл» — тестируемый `FileOpener` поверх `Library` и `PlayerModel`. `AppDelegate` (через `NSApplicationDelegateAdaptor`) владеет моделями и принимает `application(_:open:)`; окно — единственная сцена `Window`, которую делегат может снова открыть.

**Tech Stack:** Swift 5, SwiftUI, AppKit, AVFoundation, XCTest, xcodegen. Без сторонних зависимостей.

**Spec:** `docs/superpowers/specs/2026-10-17-open-from-finder-design.md`

## Global Constraints

- macOS 14.0 deployment target, Swift 5 language mode, ноль сторонних зависимостей.
- Info.plist генерирует xcodegen — правки только через `project.yml` (`targets.Siply.info.properties`), после добавления файлов — `xcodegen generate`.
- Комментарии и сообщения коммитов — на русском, conventional-префиксы (`feat:`, `docs:`, `test:`). **Без трейлеров `Co-Authored-By` / `Claude-Session`.** Git-автор уже настроен локально (Artem Pisarev <artem@pisarev.in>) — не менять.
- **Не запускать Siply.app, не убивать запущенный Siply, не трогать UserDefaults домена `info.pisarev.siply`.** Тесты используют `UserDefaults(suiteName:)`.
- Проверка: `xcodegen generate >/dev/null && xcodebuild test -scheme Siply -destination 'platform=macOS,arch=arm64' -derivedDataPath build 2>&1 | grep -E "Test Case.*failed|error:|TEST (SUCCEEDED|FAILED)|BUILD FAILED"` → `** TEST SUCCEEDED **`. Шум `linkd`/`autoShortcut` безвреден.
- Стиль: как в окружающем коде — короткие doc-комментарии `///` на русском, `ponytail:` для осознанных упрощений.

## Review Focus

1. URL из Finder может прийти нестандартизованным (`/private/var` vs `/var`, `..`) — трек должен найтись в очереди. Тест: открытие через URL с `standardizedFileURL`-отличием (Task 2).
2. Открытие файла, пока уже играет другая папка, и файл неиграемый — текущее воспроизведение не прерывается. Тест в Task 2.
3. Повторное открытие файла из той же папки — корень не пересобирается (`generation` и `root` те же), но играет новый трек. Тест в Task 2.
4. Холодный старт: URL приходит до появления окна — модель уже готова, окно показывает папку. Ручная проверка пользователем (Task 3).
5. Окно закрыто, приложение живо → открытие файла показывает окно, а не плодит второе. Ручная проверка пользователем (Task 3).

---

### Task 1: Скрывать неиграемые файлы

**Files:**
- Modify: `Siply/Library/LibraryScanner.swift` (`tracks(in:)`, новый `isPlayable`)
- Test: `SiplyTests/LibraryScannerTests.swift`

**Interfaces:**
- Produces: `static func isPlayable(_ url: URL) async -> Bool` в `LibraryScanner`; `LibraryScanner.tracks(in:)` возвращает только играемые треки (сигнатура прежняя).

- [ ] **Step 1: Failing tests** в `LibraryScannerTests`:

```swift
func testTracksSkipUnplayableFiles() async throws {
    let tmp = TempDir()
    tmp.file("01 Broken.mp3", Data("not audio".utf8))
    try AudioFixtures.writeWav(to: tmp.url.appendingPathComponent("02 Good.wav"))
    let names = await LibraryScanner.tracks(in: tmp.url).map { $0.url.lastPathComponent }
    XCTAssertEqual(names, ["02 Good.wav"])
}

func testIsPlayable() async throws {
    let tmp = TempDir()
    let bad = tmp.file("x.mp3", Data("not audio".utf8))
    let good = tmp.url.appendingPathComponent("y.wav")
    try AudioFixtures.writeWav(to: good)
    let badOK = await LibraryScanner.isPlayable(bad)
    let goodOK = await LibraryScanner.isPlayable(good)
    XCTAssertFalse(badOK)
    XCTAssertTrue(goodOK)
}
```

- [ ] **Step 2: Run** проверочную команду → FAIL (нет `isPlayable`).
- [ ] **Step 3: Implement.** `isPlayable`: `AVURLAsset(url:)`, `load(.isPlayable, .hasProtectedContent)`; true только если играемый и без DRM; ошибка загрузки → false. В `tracks(in:)` проверять параллельно в той же task group, что и `loadTrack` (не вторым проходом), и отбрасывать неиграемые до `Track.sorted`. `loadTrack` не менять (существующий тест фолбэка по имени должен остаться зелёным).
- [ ] **Step 4: Run** → `** TEST SUCCEEDED **`.
- [ ] **Step 5: Commit** `feat: скрывать в папке файлы, которые AVFoundation не сыграет`.

---

### Task 2: Открытие файла — модель, Info.plist

**Files:**
- Modify: `Siply/Library/Library.swift` (новый `openFolder(of:)`)
- Create: `Siply/Library/FileOpener.swift`
- Modify: `project.yml` (`CFBundleDocumentTypes`)
- Test: `SiplyTests/FileOpenerTests.swift` (новый), `SiplyTests/LibraryTests.swift`

**Interfaces:**
- Consumes: `LibraryScanner.tracks(in:) async -> [Track]` (Task 1), `PlayerModel.play(queue:startingAt:)`.
- Produces:
  - `Library.openFolder(of file: URL)` — корень = `file.deletingLastPathComponent()`; если `root?.url` уже равен этой папке (сравнение `standardizedFileURL`) — только `selection = root`, без `open`; иначе `open(folder)`.
  - `@MainActor enum FileOpener { static func open(_ urls: [URL], library: Library, player: PlayerModel) async }` — берёт `urls.first` (пусто → ничего), `library.openFolder(of:)`, `await LibraryScanner.tracks(in: folder)`, ищет индекс по `standardizedFileURL` и вызывает `player.play(queue:startingAt:)`; не нашёл → плеер не трогает.

- [ ] **Step 1: Failing tests.**

`LibraryTests`:
```swift
func testOpenFolderOfFileSetsRootSelectionAndPersists() {
    let tmp = TempDir()
    let file = tmp.file("a.mp3")
    let lib = Library(defaults: defaults)
    lib.openFolder(of: file)
    XCTAssertEqual(lib.root?.url, tmp.url.standardizedFileURL)
    XCTAssertEqual(lib.selection, lib.root)
    XCTAssertEqual(Library(defaults: defaults).root?.url, tmp.url.standardizedFileURL)
}

func testOpenFolderOfFileInCurrentRootKeepsTree() {
    let tmp = TempDir()
    let lib = Library(defaults: defaults)
    lib.open(tmp.url)
    let root = lib.root
    lib.selection = nil
    lib.openFolder(of: tmp.file("a.mp3"))
    XCTAssertTrue(lib.root === root)
    XCTAssertEqual(lib.selection, root)
    XCTAssertEqual(lib.generation, 0)
}
```

`FileOpenerTests` (`@MainActor`, setUp как в `PlayerModelTests`: свой suite `SiplyFileOpenerTests` для `Library` и `PlayerModel`, `FakeAudioEngine`). Фикстура: `TempDir` с WAV `01 A.wav`, `02 B.wav`, `03 C.wav` через `AudioFixtures.writeWav` и мусорным `04 Bad.mp3`.
```swift
func testOpenPlaysFileWithWholeFolderQueue() async {
    await FileOpener.open([dir.url.appendingPathComponent("02 B.wav")], library: library, player: player)
    XCTAssertEqual(library.root?.url, dir.url.standardizedFileURL)
    XCTAssertEqual(player.queue.map { $0.url.lastPathComponent }, ["01 A.wav", "02 B.wav", "03 C.wav"])
    XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "02 B.wav")
    XCTAssertTrue(player.isPlaying)
}

func testOpenTakesFirstOfSeveralURLs() async {
    await FileOpener.open([dir.url.appendingPathComponent("03 C.wav"), dir.url.appendingPathComponent("01 A.wav")],
                          library: library, player: player)
    XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "03 C.wav")
}

func testOpenMatchesNonStandardizedURL() async {
    let odd = dir.url.appendingPathComponent("sub/../02 B.wav")
    await FileOpener.open([odd], library: library, player: player)
    XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "02 B.wav")
}

func testOpenUnplayableFileOpensFolderKeepsCurrentPlayback() async {
    let other = Track(url: URL(fileURLWithPath: "/m/x.mp3"))
    player.play(queue: [other], startingAt: 0)
    await FileOpener.open([dir.url.appendingPathComponent("04 Bad.mp3")], library: library, player: player)
    XCTAssertEqual(library.root?.url, dir.url.standardizedFileURL)
    XCTAssertEqual(player.currentTrack, other)
    XCTAssertTrue(player.isPlaying)
}

func testOpenEmptyListDoesNothing() async {
    await FileOpener.open([], library: library, player: player)
    XCTAssertNil(library.root)
    XCTAssertNil(player.currentTrack)
}

func testAppDeclaresAudioDocumentTypes() {
    let types = (Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]]) ?? []
    let utis = Set(types.flatMap { $0["LSItemContentTypes"] as? [String] ?? [] })
    XCTAssertEqual(utis, ["public.mp3", "public.mpeg-4-audio", "public.aac-audio", "org.xiph.flac",
                          "com.microsoft.waveform-audio", "public.aiff-audio", "public.aifc-audio",
                          "com.apple.coreaudio-format"])
}
```
(`testOpenMatchesNonStandardizedURL`: создать подпапку `sub` в фикстуре.) Если `player.queue` приватный для чтения — он `private(set)`, читать можно.

- [ ] **Step 2: Run** → FAIL (нет `openFolder`, `FileOpener`, doc types).
- [ ] **Step 3: Implement** `Library.openFolder(of:)`, `FileOpener.open` по Interfaces. В `project.yml` → `targets.Siply.info.properties.CFBundleDocumentTypes`: один элемент `{CFBundleTypeName: "Audio", CFBundleTypeRole: Viewer, LSHandlerRank: Alternate, LSItemContentTypes: [восемь UTI выше]}`. `xcodegen generate`.
- [ ] **Step 4: Run** → `** TEST SUCCEEDED **`.
- [ ] **Step 5: Commit** `feat: открытие аудиофайла — папка становится корнем, файл играет` (включая `project.yml` и сгенерированный `Siply/Info.plist`).

---

### Task 3: Подключение к приложению, выделение строки, документация

**Files:**
- Create: `Siply/App/AppDelegate.swift`
- Modify: `Siply/App/SiplyApp.swift`, `Siply/UI/ContentView.swift`, `Siply/UI/TrackList.swift` (`updateNSView`)
- Modify: `README.md`, `README.ru.md`, `site/index.html`, `site/en/index.html` (раздел установки)

**Interfaces:**
- Consumes: `FileOpener.open(_:library:player:)` (Task 2).
- Produces: `final class AppDelegate: NSObject, NSApplicationDelegate` с `let library: Library`, `let player: PlayerModel`, `var openMainWindow: (() -> Void)?`.

- [ ] **Step 1: AppDelegate.** Переносит из `SiplyApp.init` создание `Library`, `PlayerModel(engine: AVAudioPlayerEngine())`, `NowPlaying`, `OutputDeviceMonitor` (держит их). `application(_:open:)`: если окна нет на экране — `openMainWindow?()`, `NSApp.activate()`, затем `Task { await FileOpener.open(urls, library:, player:) }`.
- [ ] **Step 2: SiplyApp.** `@NSApplicationDelegateAdaptor(AppDelegate.self) var delegate`; модели в environment берутся из `delegate`. `WindowGroup` → `Window("Siply", id: "main")` (единственное окно; ⌘N в приложении и так нет — `.newItem` заменён) — чтобы открытие файла не создавало второе окно. В `ContentView` (или модификатором в сцене) захватить `@Environment(\.openWindow)` в `onAppear`: `delegate.openMainWindow = { openWindow(id: "main") }`.
- [ ] **Step 3: Выделение строки.** В `TrackList.updateNSView`, при замене `tracks`: если прежнего выделения нет и `player.currentTrack?.url` есть в новых `tracks` — выделить эту строку и `scrollRowToVisible`. Так кликнутый в Finder трек выделен после загрузки папки (и при переходе в папку с играющим треком — это ожидаемо).
- [ ] **Step 4: Документация.** В раздел установки README (en/ru) и сайта (ru/en) — одна строка/пункт:
  - ru: «Чтобы аудиофайлы открывались в Siply двойным кликом: в Finder выберите файл → «Свойства» (⌘I) → «Открыть в программе» → Siply → «Изменить всё».»
  - en: “To open audio files in Siply with a double-click: select a file in Finder → Get Info (⌘I) → Open with → Siply → Change All.”
  В README.ru — в «Установка», в README — в «Install», на сайте — в блок `<h2>Установка</h2>` / `<h2>Install</h2>` в стиле соседних пунктов.
- [ ] **Step 5: Run** проверочную команду → `** TEST SUCCEEDED **` (все тесты, включая старые). Приложение **не запускать**.
- [ ] **Step 6: Commit** `feat: Siply открывает аудиофайлы из Finder` (код) и `docs: как открывать файлы в Siply двойным кликом` (README/сайт) — двумя коммитами.

Ручная проверка (делает пользователь, не исполнитель): холодный старт двойным кликом; клик при открытом окне; клик при закрытом окне — одно окно.
