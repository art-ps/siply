import SwiftUI

/// Полоса прогресса под названием трека: тонкая, при hover толще; тянется мышью.
struct ProgressStrip: View {
    /// 0…1
    let progress: Double
    let thick: Bool
    /// Доля во время перетаскивания.
    let onDrag: (Double) -> Void
    /// Доля при отпускании.
    let onEnd: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.2))
                Capsule().fill(Color.primary.opacity(0.85))
                    .frame(width: min(max(progress, 0), 1) * geo.size.width)
            }
            .frame(height: thick ? 6 : 3)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { onDrag(fraction($0.location.x, geo.size.width)) }
                    .onEnded { onEnd(fraction($0.location.x, geo.size.width)) }
            )
            .animation(.easeOut(duration: 0.12), value: thick)
        }
        .frame(height: 8)
        .accessibilityLabel("Прогресс")
        .accessibilityValue("\(Int((min(max(progress, 0), 1)) * 100))%")
    }

    private func fraction(_ x: CGFloat, _ width: CGFloat) -> Double {
        width > 0 ? Double(min(max(x / width, 0), 1)) : 0
    }
}
