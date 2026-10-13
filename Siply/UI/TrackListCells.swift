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
