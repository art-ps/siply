import SwiftUI

/// Содержимое ячейки «Песня»: обложка-кнопка и название.
struct TitleCell: View {
    let track: Track
    let player: PlayerModel
    let hovering: Bool
    let emphasized: Bool
    let play: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TrackArtworkButton(track: track, hovering: hovering, play: play)
            Text(track.title).lineLimit(1)
                .foregroundStyle(emphasized ? Color.white : Color.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .environment(player)
    }
}
