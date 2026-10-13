import AppKit
import SwiftUI

/// Строка таблицы с серой подсветкой при наведении.
final class HoverRowView: NSTableRowView {
    static let id = NSUserInterfaceItemIdentifier("hoverRow")
    var onHoverChange: ((Bool) -> Void)?
    var isHovered = false {
        didSet {
            guard isHovered != oldValue else { return }
            needsDisplay = true
            onHoverChange?(isHovered)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isHovered = false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)
        guard isHovered, !isSelected else { return }
        NSColor.labelColor.withAlphaComponent(0.06).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 0), xRadius: 6, yRadius: 6).fill()
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

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { if backgroundStyle != oldValue { render() } }
    }

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
        let view = TitleCell(track: track, player: player, hovering: hovering,
                             emphasized: backgroundStyle == .emphasized, play: play)
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
