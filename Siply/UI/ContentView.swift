import SwiftUI

struct ContentView: View {
    @Environment(Library.self) private var library
    @Environment(PlayerModel.self) private var player

    var body: some View {
        @Bindable var library = library
        Group {
            if let root = library.root {
                NavigationSplitView {
                    SidebarView(root: root, selection: $library.selection)
                } detail: {
                    if let folder = library.selection {
                        FolderView(folder: folder)
                    } else {
                        Text("Выберите папку").foregroundStyle(.secondary)
                    }
                }
            } else {
                EmptyStateView(open: library.openFolderPanel)
            }
        }
        // Пробел — play/pause, когда фокус не в текстовом поле (поле само съедает пробел).
        .onKeyPress(.space) {
            player.togglePlayPause()
            return .handled
        }
    }
}
