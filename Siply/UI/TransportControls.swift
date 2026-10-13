import SwiftUI

/// shuffle · prev · play/pause · next · repeat. Toggles серые, активные — акцентом.
struct TransportControls: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        let hasTrack = player.currentTrack != nil
        HStack(spacing: 18) {
            toggle("shuffle", on: player.shuffle, label: "Перемешивать",
                   value: player.shuffle ? "включено" : "выключено") { player.shuffle.toggle() }
            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.system(size: 17))
            }
            .accessibilityLabel("Предыдущий")
            .disabled(!hasTrack)
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .frame(width: 28)
            }
            .accessibilityLabel(player.isPlaying ? "Пауза" : "Воспроизвести")
            .disabled(!hasTrack)
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.system(size: 17))
            }
            .accessibilityLabel("Следующий")
            .disabled(!hasTrack)
            toggle(player.repeatMode == .one ? "repeat.1" : "repeat",
                   on: player.repeatMode != .off, label: "Повторять",
                   value: player.repeatMode == .off ? "выключено" : player.repeatMode == .all ? "все" : "один") {
                player.cycleRepeat()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ icon: String, on: Bool, label: String, value: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(on ? Color.accentColor : .secondary)
        }
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
