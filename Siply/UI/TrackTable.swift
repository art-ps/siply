import SwiftUI

/// Таблица треков. Двойной клик / Enter — play(track).
struct TrackTable: View {
    @Environment(PlayerModel.self) private var player
    let tracks: [Track]
    let play: (Track) -> Void
    @State private var selection = Set<Track.ID>()

    var body: some View {
        Table(tracks, selection: $selection) {
            TableColumn("Песня") { track in
                HStack(spacing: 10) {
                    if player.currentTrack?.url == track.url {
                        Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                            .accessibilityLabel("Сейчас играет")
                    } else {
                        ArtworkView(data: track.artwork, size: 32)
                    }
                    Text(track.title).lineLimit(1)
                }
            }
            TableColumn("Артист") { Text($0.artist).lineLimit(1) }
            TableColumn("Альбом") { Text($0.album).lineLimit(1) }
            TableColumn("Время") { track in
                Text(track.duration.mmss)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .width(60)
        }
        .contextMenu(forSelectionType: Track.ID.self) { _ in
            EmptyView()
        } primaryAction: { ids in
            if let id = ids.first, let track = tracks.first(where: { $0.id == id }) { play(track) }
        }
    }
}
