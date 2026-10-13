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
                            // Ячейки Table не наследуют environment — передаём явно.
                            .environment(player)
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
