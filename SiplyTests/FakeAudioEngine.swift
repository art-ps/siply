import Foundation
@testable import Siply

@MainActor
final class FakeAudioEngine: AudioEngine {
    struct LoadError: Error {}

    var volume: Float = 1
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 100
    var onFinished: (@MainActor () -> Void)?

    var loaded: [URL] = []
    var playing = false
    var failing: Set<URL> = []

    func load(_ url: URL) throws {
        if failing.contains(url) { throw LoadError() }
        loaded.append(url)
        currentTime = 0
    }

    func play() { playing = true }
    func pause() { playing = false }

    /// Имитирует конец трека.
    func finish() { onFinished?() }
}
