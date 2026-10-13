import SwiftUI

/// Меню: Файл → Открыть папку… (⌘O), Обновить (⌘R); Управление → next/prev.
struct AppCommands: Commands {
    let library: Library
    let player: PlayerModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Открыть папку…") { library.openFolderPanel() }
                .keyboardShortcut("o")
            Button("Обновить") { library.rescan() }
                .keyboardShortcut("r")
        }
        CommandMenu("Управление") {
            Button("Воспроизвести / Пауза") { player.togglePlayPause() }
            Button("Следующий") { player.next() }
                .keyboardShortcut(.rightArrow, modifiers: .command)
            Button("Предыдущий") { player.previous() }
                .keyboardShortcut(.leftArrow, modifiers: .command)
        }
    }
}
