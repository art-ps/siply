import SwiftUI

/// Плавающий бар как в Apple Music: транспорт · обложка и текст с полосой прогресса · громкость.
struct PlayerBar: View {
    var body: some View {
        HStack(spacing: 16) {
            TransportControls()
            NowPlayingBlock()
                .frame(maxWidth: .infinity)
            VolumeControl()
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.separator))
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
