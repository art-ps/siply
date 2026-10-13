import SwiftUI

@main
struct SiplyApp: App {
    @State private var library = Library()
    @State private var player = PlayerModel(engine: AVAudioPlayerEngine())

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
