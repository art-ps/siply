import SwiftUI

@main
struct SiplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // Единственное окно: открытие файла из Finder не должно плодить второе.
        Window("Siply", id: "main") {
            ContentView()
                .environment(delegate.library)
                .environment(delegate.player)
                // 960 — ниже шапка папки и плеер-бар не помещаются в колонку контента.
                .frame(minWidth: 960, minHeight: 560)
                .onAppear {
                    let open = openWindow
                    delegate.openMainWindow = { open(id: "main") }
                }
        }
        .commands {
            AppCommands(library: delegate.library, player: delegate.player)
        }
    }
}
