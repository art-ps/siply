import SwiftUI

/// Плавающий бар как в Apple Music: транспорт · обложка и текст с полосой прогресса · устройство · громкость.
struct PlayerBar: View {
    var body: some View {
        HStack(spacing: 16) {
            TransportControls()
            NowPlayingBlock()
                .frame(maxWidth: .infinity)
            OutputPicker()
            VolumeControl()
        }
        .padding(.horizontal, 22)
        .frame(height: 60)
        .modifier(BarGlass())
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
