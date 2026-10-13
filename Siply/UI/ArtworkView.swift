import SwiftUI

/// Обложка или заглушка с нотой.
struct ArtworkView: View {
    let data: Data?
    let size: CGFloat
    var cornerRadius: CGFloat = 4

    var body: some View {
        Group {
            // ponytail: NSImage(data:) на каждый рендер; кэш по url — если таблица на сотнях треков начнёт тормозить
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "music.note")
                        .font(.system(size: size / 3))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
