import SwiftUI

/// Liquid Glass на macOS 26+, ниже — полупрозрачный материал.
struct BarGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.separator))
        }
    }
}
