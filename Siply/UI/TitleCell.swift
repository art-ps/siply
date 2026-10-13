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
