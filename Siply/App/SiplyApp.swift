import SwiftUI

@main
struct SiplyApp: App {
    @State private var library = Library()
    @State private var player: PlayerModel
    private let nowPlaying: NowPlaying

    init() {
        let player = PlayerModel(engine: AVAudioPlayerEngine())
        _player = State(initialValue: player)
        nowPlaying = NowPlaying(player: player)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(library)
                .environment(player)
                .frame(minWidth: 800, minHeight: 500)
        }
        .commands {
            AppCommands(library: library, player: player)
        }
    }
}
