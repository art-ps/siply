import SwiftUI

/// Шапка папки: обложка, имя, «N треков · M мин», кнопки.
struct FolderHeader: View {
    @Environment(PlayerModel.self) private var player
    let folder: FolderNode
    let tracks: [Track]
    let artwork: Data?

    var body: some View {
        HStack(alignment: .bottom, spacing: 24) {
            ArtworkView(data: artwork, size: 200, cornerRadius: 8)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 12) {
                Text(folder.name)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                Text(summary)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                HStack(spacing: 12) {
                    Button {
                        player.shuffle = false
                        player.play(queue: tracks, startingAt: 0)
                    } label: {
                        Label("Воспроизвести", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        player.shuffle = true
                        player.play(queue: tracks, startingAt: tracks.indices.randomElement() ?? 0)
                    } label: {
                        Label("Перемешать", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .disabled(tracks.isEmpty)
            }
            Spacer()
        }
    }

    private var summary: String {
        let minutes = Int(tracks.reduce(0) { $0 + $1.duration } / 60)
        return "\(Track.countLabel(tracks.count)) · \(minutes) мин"
    }
}
