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
