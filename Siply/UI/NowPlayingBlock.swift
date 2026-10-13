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
