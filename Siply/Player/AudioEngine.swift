import AVFoundation

/// Минимальный интерфейс над плеером — чтобы PlayerModel тестировался без звука.
@MainActor
protocol AudioEngine: AnyObject {
    var volume: Float { get set }
    /// Чтение — позиция, запись — перемотка.
    var currentTime: TimeInterval { get set }
    var duration: TimeInterval { get }
    /// Вызывается на главном акторе, когда трек доиграл до конца.
    var onFinished: (@MainActor () -> Void)? { get set }
    func load(_ url: URL) throws
    func play()
    func pause()
}

@MainActor
final class AVAudioPlayerEngine: NSObject, AudioEngine, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?

    var volume: Float = 1 {
        didSet { player?.volume = volume }
    }

    var currentTime: TimeInterval {
        get { player?.currentTime ?? 0 }
        set { player?.currentTime = newValue }
    }

    var duration: TimeInterval { player?.duration ?? 0 }

    var onFinished: (@MainActor () -> Void)?

    func load(_ url: URL) throws {
        player?.delegate = nil
        player?.stop()
        let p = try AVAudioPlayer(contentsOf: url)
        p.delegate = self
        p.volume = volume
        p.prepareToPlay()
        player = p
    }

    func play() { player?.play() }
    func pause() { player?.pause() }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.onFinished?() }
    }
}
