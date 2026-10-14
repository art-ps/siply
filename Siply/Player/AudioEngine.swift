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
    /// UID устройства вывода; nil — системный выход.
    var outputDeviceUID: String? { get set }
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

    var outputDeviceUID: String? {
        didSet {
            guard let p = player else { return }
            // AVAudioPlayer молча игнорирует смену устройства, пока играет или на паузе;
            // срабатывает только после stop() (проверено на живом Core Audio). Позицию сохраняем.
            let wasPlaying = p.isPlaying, time = p.currentTime
            p.stop()
            p.currentDevice = outputDeviceUID
            p.currentTime = time
            p.prepareToPlay()
            if wasPlaying { p.play() }
        }
    }

    func load(_ url: URL) throws {
        player?.delegate = nil
        player?.stop()
        let p = try AVAudioPlayer(contentsOf: url)
        p.delegate = self
        p.volume = volume
        p.currentDevice = outputDeviceUID
        p.prepareToPlay()
        player = p
    }

    func play() { player?.play() }
    func pause() { player?.pause() }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.onFinished?() }
    }
}
