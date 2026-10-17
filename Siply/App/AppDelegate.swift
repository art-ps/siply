import AppKit
import SwiftUI

/// Держит модели приложения и принимает файлы, открытые из Finder.
/// Модели живут здесь, а не в `SiplyApp`: `application(_:open:)` может прийти раньше, чем появится любое view.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let library = Library()
    let player: PlayerModel
    private let nowPlaying: NowPlaying
    private let outputs: OutputDeviceMonitor

    /// Показывает главное окно заново, если его закрыли. Задаётся view после первого появления.
    var openMainWindow: (() -> Void)?

    override init() {
        let player = PlayerModel(engine: AVAudioPlayerEngine())
        self.player = player
        nowPlaying = NowPlaying(player: player)
        outputs = OutputDeviceMonitor { player.availableOutputs = $0 }
        super.init()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Холодный старт: замыкания ещё нет, окно откроет сама сцена `Window`.
        if !NSApp.windows.contains(where: { $0.isVisible && $0.canBecomeMain }) {
            openMainWindow?()
        }
        NSApp.activate()
        Task { await FileOpener.open(urls, library: library, player: player) }
    }
}
