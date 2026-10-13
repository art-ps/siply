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
        table.allowsTypeSelect = false
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
        table.doubleAction = #selector(Coordinator.rowDoubleClicked(_:))
        table.onActivate = { [weak coordinator = context.coordinator] in coordinator?.activateSelectedRow() }
        table.onSpace = { [weak coordinator = context.coordinator] in coordinator?.player.togglePlayPause() }
        context.coordinator.table = table

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 84, right: 0)   // место под плавающий бар
        scroll.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: 84, right: 0)
        scroll.contentView.postsBoundsChangedNotifications = true
        context.coordinator.scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification, object: scroll.contentView, queue: .main
        ) { [weak table] _ in
            MainActor.assumeIsolated { table?.refreshHover() }
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.play = play
        if tracks != coordinator.tracks {
            let table = coordinator.table
            let selectedURL = table.flatMap { t in
                coordinator.tracks.indices.contains(t.selectedRow) ? coordinator.tracks[t.selectedRow].url : nil
            }
            coordinator.tracks = tracks
            table?.reloadData()
            table?.refreshHover()
            if let selectedURL, let i = tracks.firstIndex(where: { $0.url == selectedURL }) {
                table?.selectRowIndexes([i], byExtendingSelection: false)
            } else {
                table?.deselectAll(nil)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var tracks: [Track] = []
        let player: PlayerModel
        var play: (Track) -> Void
        weak var table: KeyTableView?
        var scrollObserver: NSObjectProtocol?

        init(player: PlayerModel, play: @escaping (Track) -> Void) {
            self.player = player
            self.play = play
        }

        deinit {
            if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
        }

        func numberOfRows(in tableView: NSTableView) -> Int { tracks.count }

        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let view = tableView.makeView(withIdentifier: HoverRowView.id, owner: nil) as? HoverRowView ?? HoverRowView()
            view.identifier = HoverRowView.id
            view.isHovered = ((tableView as? KeyTableView)?.hoveredRow == row)
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
                let hovered = (tableView as? KeyTableView)?.hoveredRow == row
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

        /// Даблклик по строке (по заголовку и пустому месту clickedRow == -1).
        @objc func rowDoubleClicked(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard tracks.indices.contains(row) else { return }
            play(tracks[row])
        }

        /// Enter с клавиатуры по выделенной строке.
        func activateSelectedRow() {
            guard let row = table?.selectedRow, tracks.indices.contains(row) else { return }
            play(tracks[row])
        }
    }
}

/// NSTableView: Enter/Space с клавиатуры и единый трекинг hover — ровно одна строка под курсором.
final class KeyTableView: NSTableView {
    var onActivate: (() -> Void)?
    var onSpace: (() -> Void)?
    private(set) var hoveredRow: Int?
    private var tracking: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                  owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseMoved(with event: NSEvent) { setHoveredRow(row(at: convert(event.locationInWindow, from: nil))) }
    override func mouseEntered(with event: NSEvent) { mouseMoved(with: event) }
    override func mouseExited(with event: NSEvent) { setHoveredRow(-1) }

    /// Пересчитать hover по текущему положению курсора (после скролла / reload).
    func refreshHover() {
        guard let window else { setHoveredRow(-1); return }
        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        setHoveredRow(visibleRect.contains(point) ? row(at: point) : -1)
    }

    private func setHoveredRow(_ row: Int) {
        let new: Int? = row >= 0 ? row : nil
        guard new != hoveredRow else { return }
        if let old = hoveredRow { (rowView(atRow: old, makeIfNecessary: false) as? HoverRowView)?.isHovered = false }
        hoveredRow = new
        if let new { (rowView(atRow: new, makeIfNecessary: false) as? HoverRowView)?.isHovered = true }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36 where selectedRow >= 0, 76 where selectedRow >= 0:
            onActivate?()
        case 49:
            onSpace?()
        default:
            super.keyDown(with: event)
        }
    }
}
