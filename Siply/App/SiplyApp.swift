import SwiftUI

@main
struct SiplyApp: App {
    @State private var library = Library()
    @State private var player: PlayerModel
    private let nowPlaying: NowPlaying
    private let outputs: OutputDeviceMonitor

    init() {
        let player = PlayerModel(engine: AVAudioPlayerEngine())
        _player = State(initialValue: player)
        nowPlaying = NowPlaying(player: player)
        outputs = OutputDeviceMonitor { player.availableOutputs = $0 }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(library)
                .environment(player)
                // 960 — ниже шапка папки и плеер-бар не помещаются в колонку контента.
                .frame(minWidth: 960, minHeight: 560)
        }
        .commands {
            AppCommands(library: library, player: player)
        }
    }
}
