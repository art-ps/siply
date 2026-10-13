# Siply UI polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Плеер-бар только над колонкой контента и ограниченной ширины (как в Apple Music); play/pause по одиночному клику на обложке трека при наведении.

**Architecture:** Перенос `safeAreaInset` на detail-колонку `NavigationSplitView`; новый `TrackArtworkButton` в ячейке «Песня»; hover-состояние строки в `TrackTable`.

**Tech Stack:** SwiftUI, macOS 14. Без зависимостей.

**Spec:** Утверждённый в чате дизайн (bounded): (1) бар не наезжает на сайдбар, центрирован над контентом, `maxWidth 820`; (2) hover по строке → на обложке затемнение + ▶, клик → играет трек (очередь = папка); текущий трек: играет → иконка динамика, при hover ⏸, клик → пауза; на паузе ▶, клик → продолжить; даблклик по строке остаётся.

## Global Constraints

- Swift language mode 5, macOS 14, без новых зависимостей, один View на файл в `Siply/UI/`.
- Строки UI русские; a11y-лейблы «Воспроизвести»/«Пауза».
- Коммиты на русском, conventional prefix, без трейлеров `Co-Authored-By`/`Claude-Session`.
- Проверка: `xcodegen generate >/dev/null && xcodebuild test -scheme Siply -destination 'platform=macOS' -derivedDataPath build 2>&1 | grep -E "Test Case.*(passed|failed)|error:|warning: |TEST (SUCCEEDED|FAILED)|BUILD FAILED"` → `** TEST SUCCEEDED **`, 49 passed, без compile warnings (runtime-шум linkd/appintents игнорировать). Затем Debug-сборка, запуск с демо-папкой (`/tmp/siply-demo`, seed через `swift <scratch>/seed-root.swift /tmp/siply-demo`), скриншот, `pkill -x Siply`, `defaults delete info.pisarev.siply rootBookmark`.

## Review Focus

1. Бар при узком окне (800 pt) и при схлопнутом сайдбаре — не наезжает, по центру.
2. Клик по кнопке на обложке не ломает выделение строки/даблклик (primaryAction).
3. Hover-состояние сбрасывается при уходе курсора (иконка не «залипает»).

---

### Task 1: Бар над контентом, ограниченная ширина

**Files:**
- Modify: `Siply/UI/ContentView.swift`, `Siply/UI/PlayerBar.swift`

- [ ] **Step 1: `ContentView.swift`** — убрать `.safeAreaInset(edge: .bottom) { PlayerBar() }` с внешнего `Group`; в `detail:` обернуть содержимое:

```swift
                } detail: {
                    Group {
                        if let folder = library.selection {
                            FolderView(folder: folder)
                        } else {
                            Text("Выберите папку").foregroundStyle(.secondary)
                        }
                    }
                    .safeAreaInset(edge: .bottom) { PlayerBar() }
                }
```
`.onKeyPress(.space)` остаётся на внешнем `Group`. На экране без корня бара нет (играть нечего).

- [ ] **Step 2: `PlayerBar.swift`** — после `.overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))` и перед `.padding(12)` добавить:

```swift
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
```
(первый ограничивает ширину, второй центрирует). Всё остальное без изменений.

- [ ] **Step 3: Проверка** — команда из Global Constraints; Debug-сборка; запуск с демо-папкой; скриншот: бар по центру под контентом, сайдбар свободен. Закрыть, почистить defaults.

- [ ] **Step 4: Commit** — `fix: плеер-бар над контентом, ширина как в Apple Music`

---

### Task 2: Play/pause по клику на обложке

**Files:**
- Create: `Siply/UI/TrackArtworkButton.swift`
- Modify: `Siply/UI/TrackTable.swift`

- [ ] **Step 1: `Siply/UI/TrackArtworkButton.swift`**

```swift
import SwiftUI

/// Обложка в строке трека. При наведении на строку — кнопка play, у текущего трека — pause/play.
struct TrackArtworkButton: View {
    @Environment(PlayerModel.self) private var player
    let track: Track
    /// Курсор над строкой — состояние держит таблица.
    let hovering: Bool
    let play: () -> Void

    private var isCurrent: Bool { player.currentTrack?.url == track.url }

    var body: some View {
        Button {
            if isCurrent { player.togglePlayPause() } else { play() }
        } label: {
            ZStack {
                ArtworkView(data: track.artwork, size: 32)
                if hovering || isCurrent {
                    Color.black.opacity(0.45)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCurrent && player.isPlaying ? "Пауза" : "Воспроизвести")
    }

    private var icon: String {
        guard isCurrent else { return "play.fill" }
        if player.isPlaying { return hovering ? "pause.fill" : "speaker.wave.2.fill" }
        return "play.fill"
    }
}
```

- [ ] **Step 2: `TrackTable.swift`** — hover по строке + новая ячейка. Полный файл:

```swift
import SwiftUI

/// Таблица треков. Двойной клик / Enter — play(track); клик по обложке — play/pause.
struct TrackTable: View {
    @Environment(PlayerModel.self) private var player
    let tracks: [Track]
    let play: (Track) -> Void
    @State private var selection = Set<Track.ID>()
    /// Строка под курсором — чтобы показать кнопку на обложке.
    @State private var hovered: Track.ID?

    var body: some View {
        Table(tracks, selection: $selection) {
            TableColumn("Песня") { track in
                cell(track) {
                    HStack(spacing: 10) {
                        TrackArtworkButton(track: track, hovering: hovered == track.id) { play(track) }
                        Text(track.title).lineLimit(1)
                    }
                }
            }
            TableColumn("Артист") { track in
                cell(track) { Text(track.artist).lineLimit(1) }
            }
            TableColumn("Альбом") { track in
                cell(track) { Text(track.album).lineLimit(1) }
            }
            TableColumn("Время") { track in
                cell(track) {
                    Text(track.duration.mmss)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .width(60)
        }
        .contextMenu(forSelectionType: Track.ID.self) { _ in
            EmptyView()
        } primaryAction: { ids in
            if let id = ids.first, let track = tracks.first(where: { $0.id == id }) { play(track) }
        }
    }

    /// Ячейка на всю ширину колонки, чтобы hover ловился по всей строке.
    private func cell<Content: View>(_ track: Track, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { hovered = track.id } else if hovered == track.id { hovered = nil }
            }
    }
}
```

- [ ] **Step 3: Проверка** — команда из Global Constraints; Debug-сборка; запуск с демо-папкой; скриншот (без наведения — строки с обложками; hover субагент не сделает — сказать); закрыть, почистить defaults.

- [ ] **Step 4: Commit** — `feat: play/pause по клику на обложке трека`
