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

---

### Task 3: Бар-пилюля и проверка ресайза

**Files:**
- Modify: `Siply/UI/PlayerBar.swift`

- [ ] **Step 1: Форма.** В `PlayerBar.swift` заменить фон и обводку:
  `.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))` → `.background(.regularMaterial, in: Capsule())`;
  `.overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))` → `.overlay(Capsule().strokeBorder(.separator))`;
  `.padding(.horizontal, 16)` → `.padding(.horizontal, 20)`.

- [ ] **Step 2: Ресайз.** Debug-сборка, seed корня `/tmp/siply-demo/Artist/Album1`, запуск. Через `osascript` выставить размер окна и снять скриншот для каждого случая:
  ```bash
  for s in "800 500" "1100 700" "1600 900"; do set -- $s; osascript -e "tell application \"System Events\" to tell process \"Siply\" to set size of front window to {$1, $2}"; sleep 1; screencapture -x /tmp/siply-resize-$1.png; done
  ```
  Плюс свёрнутый сайдбар: `osascript -e 'tell application "System Events" to tell process "Siply" to keystroke "s" using {command down, control down}'` (toggle sidebar), скриншот `/tmp/siply-resize-nosidebar.png`. Просмотреть все PNG (Read). Критерий: бар по центру колонки контента, пилюля не обрезана, слайдер прогресса ≥ 100 pt, громкость видна. Если при 800 pt тесно — трек-блок `minWidth: 140`, громкость `.frame(width: 70)`; перепроверить.
  Если `osascript` упирается в права Accessibility — сказать в отчёте, снять хотя бы дефолтный размер.
  Закрыть: `pkill -x Siply; defaults delete info.pisarev.siply rootBookmark`.

- [ ] **Step 3: Commit** — `fix: плеер-бар в форме капсулы`

---

## Раунд 2 — акцент, бар как в Apple Music, нативная таблица

**Spec (утверждено в чате):** (1) акцент грязно-синий `#6B85A3` на всё приложение; (2) бар: скругление 12, транспорт слева, центр — обложка 40 + заголовок/подзаголовок с тонкой полосой прогресса под ними, hover по центру → времена вместо текста и толстая полоса с перетаскиванием, справа только динамик с выезжающим по hover слайдером; без «···», лирики, очереди; (3) таблица на `NSTableView`: ресайз колонок с автосохранением ширин, серая подсветка строки при наведении, без полосатости, тонкие разделители, даблклик/Enter — play, клик по обложке — play/pause.

Ограничения те же, что выше. Проверка каждой задачи: тесты зелёные (49), Debug-сборка, запуск с корнем `/tmp/siply-demo/Artist/Album1` (seed-скрипт), скриншот, `pkill -x Siply`, `defaults delete info.pisarev.siply rootBookmark`.

### Task 4: Акцентный цвет приложения

**Files:**
- Create: `Siply/Assets.xcassets/Contents.json`, `Siply/Assets.xcassets/AccentColor.colorset/Contents.json`
- Modify: `project.yml`

- [ ] **Step 1: asset-каталог**

`Siply/Assets.xcassets/Contents.json`:
```json
{ "info": { "author": "xcode", "version": 1 } }
```
`Siply/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors": [
    {
      "idiom": "universal",
      "color": {
        "color-space": "srgb",
        "components": { "red": "0x6B", "green": "0x85", "blue": "0xA3", "alpha": "1.000" }
      }
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

- [ ] **Step 2: `project.yml`** — в `targets.Siply.settings.base` добавить `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor`; в `targets.Siply.info.properties` добавить `NSAccentColorName: AccentColor`. `sources: [Siply]` подхватит каталог сам.

- [ ] **Step 3: Проверка** — `xcodegen generate`, тесты, Debug-сборка, запуск с Album1, скриншот: выделенная строка сайдбара и кнопка «Воспроизвести» серо-синие, не ярко-синие.

- [ ] **Step 4: Commit** — `feat: акцентный цвет приложения — серо-синий`

### Task 5: Плеер-бар как в Apple Music

**Files:**
- Rewrite: `Siply/UI/PlayerBar.swift`
- Create: `Siply/UI/TransportControls.swift`, `Siply/UI/NowPlayingBlock.swift`, `Siply/UI/ProgressStrip.swift`, `Siply/UI/VolumeControl.swift`

- [ ] **Step 1: `PlayerBar.swift`** (полная замена)

```swift
import SwiftUI

/// Плавающий бар как в Apple Music: транспорт · обложка и текст с полосой прогресса · громкость.
struct PlayerBar: View {
    var body: some View {
        HStack(spacing: 16) {
            TransportControls()
            NowPlayingBlock()
                .frame(maxWidth: .infinity)
            VolumeControl()
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
```

- [ ] **Step 2: `TransportControls.swift`**

```swift
import SwiftUI

/// shuffle · prev · play/pause · next · repeat. Toggles серые, активные — акцентом.
struct TransportControls: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        let hasTrack = player.currentTrack != nil
        HStack(spacing: 18) {
            toggle("shuffle", on: player.shuffle, label: "Перемешивать",
                   value: player.shuffle ? "включено" : "выключено") { player.shuffle.toggle() }
            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.system(size: 17))
            }
            .accessibilityLabel("Предыдущий")
            .disabled(!hasTrack)
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .frame(width: 28)
            }
            .accessibilityLabel(player.isPlaying ? "Пауза" : "Воспроизвести")
            .disabled(!hasTrack)
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.system(size: 17))
            }
            .accessibilityLabel("Следующий")
            .disabled(!hasTrack)
            toggle(player.repeatMode == .one ? "repeat.1" : "repeat",
                   on: player.repeatMode != .off, label: "Повторять",
                   value: player.repeatMode == .off ? "выключено" : player.repeatMode == .all ? "все" : "один") {
                player.cycleRepeat()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ icon: String, on: Bool, label: String, value: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(on ? Color.accentColor : .secondary)
        }
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
```

- [ ] **Step 3: `ProgressStrip.swift`**

```swift
import SwiftUI

/// Полоса прогресса под названием трека: тонкая, при hover толще; тянется мышью.
struct ProgressStrip: View {
    /// 0…1
    let progress: Double
    let thick: Bool
    /// Доля во время перетаскивания.
    let onDrag: (Double) -> Void
    /// Доля при отпускании.
    let onEnd: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.2))
                Capsule().fill(Color.primary.opacity(0.85))
                    .frame(width: min(max(progress, 0), 1) * geo.size.width)
            }
            .frame(height: thick ? 6 : 3)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { onDrag(fraction($0.location.x, geo.size.width)) }
                    .onEnded { onEnd(fraction($0.location.x, geo.size.width)) }
            )
            .animation(.easeOut(duration: 0.12), value: thick)
        }
        .frame(height: 8)
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(Int((min(max(progress, 0), 1)) * 100))%")
    }

    private func fraction(_ x: CGFloat, _ width: CGFloat) -> Double {
        width > 0 ? Double(min(max(x / width, 0), 1)) : 0
    }
}
```

- [ ] **Step 4: `NowPlayingBlock.swift`**

```swift
import SwiftUI

/// Центр бара: обложка, название и «артист — альбом», под ними полоса прогресса.
/// При наведении текст сменяется на времена, полоса становится толще и тянется.
struct NowPlayingBlock: View {
    @Environment(PlayerModel.self) private var player
    @State private var hovering = false
    /// Позиция во время перетаскивания — плеер не трогаем, пока не отпустили.
    @State private var scrub: TimeInterval?

    var body: some View {
        let track = player.currentTrack
        let duration = max(player.duration, 1)
        let shown = scrub ?? player.currentTime
        let showTimes = hovering && track != nil

        HStack(spacing: 10) {
            ArtworkView(data: track?.artwork, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                ZStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(track?.title ?? "—")
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(subtitle(track))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .opacity(showTimes ? 0 : 1)
                    HStack {
                        Text(shown.mmss)
                        Spacer()
                        Text("-" + max(player.duration - shown, 0).mmss)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .opacity(showTimes ? 1 : 0)
                }
                ProgressStrip(progress: shown / duration, thick: showTimes) { fraction in
                    scrub = fraction * duration
                } onEnd: { fraction in
                    player.seek(to: fraction * duration)
                    scrub = nil
                }
                .allowsHitTesting(track != nil)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    private func subtitle(_ track: Track?) -> String {
        guard let track else { return "" }
        return [track.artist, track.album].filter { !$0.isEmpty }.joined(separator: " — ")
    }
}
```

- [ ] **Step 5: `VolumeControl.swift`**

```swift
import SwiftUI

/// Иконка громкости; при наведении слева выезжает слайдер.
struct VolumeControl: View {
    @Environment(PlayerModel.self) private var player
    @State private var hovering = false

    var body: some View {
        @Bindable var player = player
        HStack(spacing: 8) {
            if hovering {
                Slider(value: $player.volume, in: 0...1)
                    .controlSize(.small)
                    .frame(width: 90)
                    .accessibilityLabel("Громкость")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(width: 22)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Громкость")
                .accessibilityValue("\(Int(player.volume * 100))%")
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private var icon: String {
        if player.volume == 0 { return "speaker.slash.fill" }
        return player.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"
    }
}
```

- [ ] **Step 6: Проверка** — тесты, сборка, запуск с Album1, скриншот: бар 60 pt, скругление 12, слева транспорт, в центре «—» с тонкой полосой, справа только динамик. Второй скриншот с окном 1600×900 — бар не шире 820, по центру.

- [ ] **Step 7: Commit** — `feat: плеер-бар как в Apple Music — полоса прогресса под треком, громкость по hover`

### Task 6: Таблица треков на NSTableView

**Files:**
- Create: `Siply/UI/TrackList.swift`, `Siply/UI/TrackListCells.swift`, `Siply/UI/TitleCell.swift`
- Modify: `Siply/UI/FolderView.swift` (`TrackTable(tracks:…)` → `TrackList(tracks:player:play:)`), `README.md`
- Delete: `Siply/UI/TrackTable.swift`

- [ ] **Step 1: `TrackList.swift`**

```swift
import AppKit
import SwiftUI

/// Нативная таблица треков: ресайз колонок с автосохранением ширин, подсветка строки
/// при наведении, даблклик/Enter — play, клик по обложке — play/pause.
struct TrackList: NSViewRepresentable {
    let tracks: [Track]
    let player: PlayerModel
    let play: (Track) -> Void

    enum Column: String, CaseIterable {
        case title, artist, album, duration

        var id: NSUserInterfaceItemIdentifier { .init(rawValue) }
        var header: String {
            switch self {
            case .title: "Песня"
            case .artist: "Артист"
            case .album: "Альбом"
            case .duration: "Время"
            }
        }
        var width: CGFloat {
            switch self {
            case .title: 320
            case .artist: 180
            case .album: 180
            case .duration: 60
            }
        }
        var minWidth: CGFloat { self == .duration ? 50 : 80 }
    }

    func makeCoordinator() -> Coordinator { Coordinator(player: player, play: play) }

    func makeNSView(context: Context) -> NSScrollView {
        let table = KeyTableView()
        table.usesAlternatingRowBackgroundColors = false
        table.gridStyleMask = .solidHorizontalGridLineMask
        table.gridColor = .separatorColor
        table.rowHeight = 44
        table.style = .inset
        table.allowsMultipleSelection = false
        table.allowsColumnReordering = false
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.backgroundColor = .clear
        for column in Column.allCases {
            let c = NSTableColumn(identifier: column.id)
            c.title = column.header
            c.width = column.width
            c.minWidth = column.minWidth
            c.resizingMask = [.userResizingMask, .autoresizingMask]
            table.addTableColumn(c)
        }
        // Автосохранение ширин — после добавления колонок, иначе нечего восстанавливать.
        table.autosaveName = "trackColumns"
        table.autosaveTableColumns = true
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        table.target = context.coordinator
        table.doubleAction = #selector(Coordinator.activateRow(_:))
        context.coordinator.table = table

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.play = play
        if tracks != coordinator.tracks {
            coordinator.tracks = tracks
            coordinator.table?.reloadData()
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var tracks: [Track] = []
        let player: PlayerModel
        var play: (Track) -> Void
        weak var table: NSTableView?

        init(player: PlayerModel, play: @escaping (Track) -> Void) {
            self.player = player
            self.play = play
        }

        func numberOfRows(in tableView: NSTableView) -> Int { tracks.count }

        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let view = tableView.makeView(withIdentifier: HoverRowView.id, owner: nil) as? HoverRowView ?? HoverRowView()
            view.identifier = HoverRowView.id
            view.onHoverChange = { [weak self, weak view] hovered in
                guard let self, let view else { return }
                let column = table?.column(withIdentifier: Column.title.id) ?? 0
                (view.view(atColumn: column) as? TitleCellView)?.setHovering(hovered)
            }
            return view
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let column = tableColumn.flatMap({ Column(rawValue: $0.identifier.rawValue) }),
                  tracks.indices.contains(row) else { return nil }
            let track = tracks[row]
            switch column {
            case .title:
                let cell = tableView.makeView(withIdentifier: TitleCellView.id, owner: nil) as? TitleCellView ?? TitleCellView()
                cell.identifier = TitleCellView.id
                let hovered = (tableView.rowView(atRow: row, makeIfNecessary: false) as? HoverRowView)?.isHovered ?? false
                cell.configure(track: track, player: player, hovering: hovered) { [weak self] in self?.play(track) }
                return cell
            case .artist:
                return textCell(tableView, text: track.artist)
            case .album:
                return textCell(tableView, text: track.album)
            case .duration:
                return textCell(tableView, text: track.duration.mmss, secondary: true, mono: true)
            }
        }

        private func textCell(_ table: NSTableView, text: String, secondary: Bool = false, mono: Bool = false) -> NSView {
            let id = NSUserInterfaceItemIdentifier("textCell")
            let cell = table.makeView(withIdentifier: id, owner: nil) as? NSTableCellView ?? {
                let c = NSTableCellView()
                c.identifier = id
                let field = NSTextField(labelWithString: "")
                field.lineBreakMode = .byTruncatingTail
                field.translatesAutoresizingMaskIntoConstraints = false
                c.addSubview(field)
                c.textField = field
                NSLayoutConstraint.activate([
                    field.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 4),
                    field.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -4),
                    field.centerYAnchor.constraint(equalTo: c.centerYAnchor),
                ])
                return c
            }()
            cell.textField?.stringValue = text
            cell.textField?.textColor = secondary ? .secondaryLabelColor : .labelColor
            cell.textField?.font = mono
                ? .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                : .systemFont(ofSize: NSFont.systemFontSize)
            return cell
        }

        /// Даблклик или Enter по строке.
        @objc func activateRow(_ sender: NSTableView) {
            let row = sender.clickedRow >= 0 ? sender.clickedRow : sender.selectedRow
            guard tracks.indices.contains(row) else { return }
            play(tracks[row])
        }
    }
}

/// NSTableView, который по Enter вызывает doubleAction.
final class KeyTableView: NSTableView {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36, selectedRow >= 0, let action = doubleAction {
            NSApp.sendAction(action, to: target, from: self)
            return
        }
        super.keyDown(with: event)
    }
}
```

- [ ] **Step 2: `TrackListCells.swift`**

```swift
import AppKit
import SwiftUI

/// Строка таблицы с серой подсветкой при наведении.
final class HoverRowView: NSTableRowView {
    static let id = NSUserInterfaceItemIdentifier("hoverRow")
    var onHoverChange: ((Bool) -> Void)?
    private(set) var isHovered = false {
        didSet {
            guard isHovered != oldValue else { return }
            needsDisplay = true
            onHoverChange?(isHovered)
        }
    }
    private var tracking: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                  owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func prepareForReuse() {
        super.prepareForReuse()
        isHovered = false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        guard isHovered, !isSelected else { return }
        NSColor.labelColor.withAlphaComponent(0.06).setFill()
        bounds.fill()
    }
}

/// Ячейка «Песня»: SwiftUI-обложка с кнопкой + название.
final class TitleCellView: NSTableCellView {
    static let id = NSUserInterfaceItemIdentifier("titleCell")
    private var host: NSHostingView<TitleCell>?
    private var track: Track?
    private var player: PlayerModel?
    private var play: () -> Void = {}
    private var hovering = false

    func configure(track: Track, player: PlayerModel, hovering: Bool, play: @escaping () -> Void) {
        self.track = track
        self.player = player
        self.play = play
        self.hovering = hovering
        render()
    }

    func setHovering(_ value: Bool) {
        guard value != hovering else { return }
        hovering = value
        render()
    }

    private func render() {
        guard let track, let player else { return }
        let view = TitleCell(track: track, player: player, hovering: hovering, play: play)
        if let host {
            host.rootView = view
        } else {
            let h = NSHostingView(rootView: view)
            h.translatesAutoresizingMaskIntoConstraints = false
            addSubview(h)
            NSLayoutConstraint.activate([
                h.leadingAnchor.constraint(equalTo: leadingAnchor),
                h.trailingAnchor.constraint(equalTo: trailingAnchor),
                h.topAnchor.constraint(equalTo: topAnchor),
                h.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            host = h
        }
    }
}
```

- [ ] **Step 3: `TitleCell.swift`**

```swift
import SwiftUI

/// Содержимое ячейки «Песня»: обложка-кнопка и название.
struct TitleCell: View {
    let track: Track
    let player: PlayerModel
    let hovering: Bool
    let play: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TrackArtworkButton(track: track, hovering: hovering, play: play)
            Text(track.title).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .environment(player)
    }
}
```

- [ ] **Step 4: `FolderView.swift`** — заменить вызов `TrackTable(tracks: Track.filter(tracks, query: search)) { track in … }` на `TrackList(tracks: Track.filter(tracks, query: search), player: player) { track in … }` (тело замыкания без изменений). Удалить `Siply/UI/TrackTable.swift` (`git rm`).

- [ ] **Step 5: README** — в «Ручная проверка» добавить: «13. Ширина колонок таблицы меняется мышью и сохраняется после перезапуска.» и «14. Наведение на строку — серая подсветка; наведение на центр бара — времена и толстая полоса, тянется мышью; наведение на динамик — слайдер громкости.»

- [ ] **Step 6: Проверка** — тесты, сборка, запуск с Album1, скриншот: таблица с заголовками, без полос, тонкие разделители, обложки 32, время справа. Проверить, что `defaults read info.pisarev.siply` содержит ключ `NSTableView Columns trackColumns` после перетаскивания колонки — если osascript недоступен, пропустить и сказать.

- [ ] **Step 7: Commit** — `feat: таблица треков на NSTableView — ресайз колонок, hover-подсветка`
