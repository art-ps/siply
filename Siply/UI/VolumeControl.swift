import SwiftUI

/// Иконка громкости; при наведении слева выезжает слайдер.
struct VolumeControl: View {
    @Environment(PlayerModel.self) private var player
    @State private var hovering = false
    /// Тянем слайдер — не прячем его, даже если курсор ушёл.
    @State private var editing = false

    var body: some View {
        @Bindable var player = player
        HStack(spacing: 8) {
            if hovering || editing {
                Slider(value: $player.volume, in: 0...1, onEditingChanged: { editing = $0 })
                    .controlSize(.small)
                    .frame(width: 90)
                    .accessibilityLabel("Громкость")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(width: 22)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Громкость")
                .accessibilityValue("\(Int(player.volume * 100))%")
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering || editing)
    }

    private var icon: String {
        if player.volume == 0 { return "speaker.slash.fill" }
        return player.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.3.fill"
    }
}
