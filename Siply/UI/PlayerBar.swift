import SwiftUI

/// Плавающий бар внизу: shuffle/prev/play/next/repeat, трек, прогресс, громкость.
struct PlayerBar: View {
    @Environment(PlayerModel.self) private var player
    /// Позиция во время перетаскивания слайдера — пока не отпустили, плеер не трогаем.
    @State private var scrub: TimeInterval?

    var body: some View {
        @Bindable var player = player
        let hasTrack = player.currentTrack != nil
        let shown = scrub ?? player.currentTime

        HStack(spacing: 20) {
            HStack(spacing: 14) {
                toggle("shuffle", on: player.shuffle, label: "Перемешивать") { player.shuffle.toggle() }
                Button { player.previous() } label: { Image(systemName: "backward.fill") }
                    .accessibilityLabel("Предыдущий")
                    .disabled(!hasTrack)
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 28)
                }
                .accessibilityLabel(player.isPlaying ? "Пауза" : "Воспроизвести")
                .disabled(!hasTrack)
                Button { player.next() } label: { Image(systemName: "forward.fill") }
                    .accessibilityLabel("Следующий")
                    .disabled(!hasTrack)
                toggle(player.repeatMode == .one ? "repeat.1" : "repeat",
                       on: player.repeatMode != .off, label: "Повторять",
                       value: player.repeatMode == .off ? "выключено" : player.repeatMode == .all ? "все" : "один") { player.cycleRepeat() }
            }
            .buttonStyle(.plain)
            .font(.body)

            HStack(spacing: 10) {
                ArtworkView(data: player.currentTrack?.artwork, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.title ?? "—").lineLimit(1)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(minWidth: 120, idealWidth: 260, maxWidth: 260, alignment: .leading)

            HStack(spacing: 8) {
                Text(shown.mmss)
                Slider(
                    value: Binding(get: { shown }, set: { scrub = $0 }),
                    in: 0...max(player.duration, 1),
                    onEditingChanged: { editing in
                        if !editing, let s = scrub { player.seek(to: s); scrub = nil }
                    }
                )
                .frame(minWidth: 80)
                .accessibilityLabel("Прогресс")
                .disabled(!hasTrack)
                Text("-" + max(player.duration - shown, 0).mmss)
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "speaker.fill")
                Slider(value: $player.volume, in: 0...1)
                    .frame(width: 80)
                    .accessibilityLabel("Громкость")
                Image(systemName: "speaker.wave.3.fill")
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.separator))
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .padding(12)
    }

    private var subtitle: String {
        guard let t = player.currentTrack else { return "" }
        return [t.artist, t.album].filter { !$0.isEmpty }.joined(separator: " — ")
    }

    private func toggle(_ icon: String, on: Bool, label: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(on ? Color.accentColor : .primary)
        }
        .accessibilityLabel(label)
        .accessibilityValue(value ?? (on ? "включено" : "выключено"))
    }
}
