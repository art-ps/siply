import SwiftUI

/// Экран без корневой папки.
struct EmptyStateView: View {
    let open: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Откройте папку с музыкой", systemImage: "music.note.list")
        } description: {
            Text("Слева появится дерево папок, справа — треки выбранной папки.")
        } actions: {
            Button("Открыть папку…", action: open)
                .buttonStyle(.borderedProminent)
        }
    }
}
