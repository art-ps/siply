import Foundation
import Observation

/// Состояние воспроизведения: очередь, текущий трек, режимы. Звук — через AudioEngine.
@MainActor
@Observable
final class PlayerModel {
    enum RepeatMode: String, CaseIterable {
        case off, all, one
    }

    private(set) var queue: [Track] = []
    private(set) var currentIndex: Int?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0

    var duration: TimeInterval { engine.duration }
    var currentTrack: Track? { currentIndex.map { queue[$0] } }

    var volume: Float {
        didSet { engine.volume = volume; defaults.set(volume, forKey: Keys.volume) }
    }
    var shuffle: Bool {
        didSet { rebuildOrder(); defaults.set(shuffle, forKey: Keys.shuffle) }
    }
    var repeatMode: RepeatMode {
        didSet { defaults.set(repeatMode.rawValue, forKey: Keys.repeatMode) }
    }
    /// Выбранное устройство вывода; nil — как в системе. Помнится, даже пока отключено.
    var output: OutputDevice? {
        didSet {
            defaults.set(output?.uid, forKey: Keys.outputUID)
            defaults.set(output?.name, forKey: Keys.outputName)
            applyOutput()
        }
    }
    /// Подключённые сейчас устройства вывода — их присылает OutputDeviceMonitor.
    var availableOutputs: [OutputDevice] = [] {
        didSet { applyOutput() }
    }

    @ObservationIgnored private let engine: AudioEngine
    @ObservationIgnored private let defaults: UserDefaults
    /// Порядок обхода индексов queue: прямой или перемешанный (текущий — первым).
    @ObservationIgnored private var order: [Int] = []
    @ObservationIgnored private var timer: Timer?
    /// Удалась ли хоть одна загрузка с начала последнего play(queue:startingAt:).
    @ObservationIgnored private var didLoad = false

    private enum Keys {
        static let volume = "volume"
        static let shuffle = "shuffle"
        static let repeatMode = "repeatMode"
        static let outputUID = "outputUID"
        static let outputName = "outputName"
    }

    init(engine: AudioEngine, defaults: UserDefaults = .standard) {
        self.engine = engine
        self.defaults = defaults
        volume = defaults.object(forKey: Keys.volume) as? Float ?? 1
        shuffle = defaults.bool(forKey: Keys.shuffle)
        repeatMode = RepeatMode(rawValue: defaults.string(forKey: Keys.repeatMode) ?? "") ?? .off
        if let uid = defaults.string(forKey: Keys.outputUID) {
            output = OutputDevice(uid: uid, name: defaults.string(forKey: Keys.outputName) ?? uid)
        }
        engine.volume = volume
        engine.onFinished = { [weak self] in self?.trackFinished() }
    }

    /// Выбранное устройство, если оно подключено; иначе системный выход. Музыка не останавливается.
    private func applyOutput() {
        let uid = output.flatMap { o in availableOutputs.contains { $0.uid == o.uid } ? o.uid : nil }
        if engine.outputDeviceUID != uid { engine.outputDeviceUID = uid }
    }

    // MARK: - Управление

    func play(queue: [Track], startingAt index: Int) {
        guard queue.indices.contains(index) else { return }
        self.queue = queue
        currentIndex = index
        rebuildOrder()
        didLoad = false
        if load(index) {
            startPlaying()
        } else {
            step(by: 1, wrap: true)
            // Ни один трек не открылся — указывать не на что, движок держит старый трек.
            if !didLoad { currentIndex = nil }
        }
    }

    func togglePlayPause() {
        guard currentIndex != nil else { return }
        if isPlaying {
            engine.pause()
            isPlaying = false
            stopTimer()
        } else {
            startPlaying()
        }
    }

    /// Пользовательский «следующий» — на краю очереди идёт по кругу.
    func next() { step(by: 1, wrap: true) }

    /// Больше 3 секунд от начала — перемотка в начало, иначе предыдущий трек.
    func previous() {
        if engine.currentTime > 3 { seek(to: 0); return }
        step(by: -1, wrap: true)
    }

    func seek(to time: TimeInterval) {
        engine.currentTime = time
        currentTime = time
    }

    func cycleRepeat() {
        let all = RepeatMode.allCases
        repeatMode = all[(all.firstIndex(of: repeatMode)! + 1) % all.count]
    }

    // MARK: - Внутреннее

    private func trackFinished() {
        if repeatMode == .one, let i = currentIndex, load(i) {
            startPlaying()
            return
        }
        step(by: 1, wrap: repeatMode == .all)
    }

    /// Шаг по order с пропуском нечитаемых. wrap=false на краю → halt().
    private func step(by delta: Int, wrap: Bool) {
        guard let cur = currentIndex, let start = order.firstIndex(of: cur) else { return }
        var pos = start
        for _ in 0..<order.count {
            pos += delta
            if !order.indices.contains(pos) {
                guard wrap else { halt(); return }
                pos = (pos + order.count) % order.count
            }
            let idx = order[pos]
            if load(idx) {
                currentIndex = idx
                startPlaying()
                return
            }
        }
        halt()
    }

    private func load(_ idx: Int) -> Bool {
        do {
            try engine.load(queue[idx].url)
            currentTime = 0
            didLoad = true
            return true
        } catch {
            NSLog("Siply: не удалось открыть %@: %@", queue[idx].url.lastPathComponent, "\(error)")
            return false
        }
    }

    private func startPlaying() {
        engine.play()
        isPlaying = true
        startTimer()
    }

    /// Конец очереди: остаёмся на текущем треке, в начале, на паузе.
    private func halt() {
        engine.pause()
        engine.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopTimer()
    }

    private func rebuildOrder() {
        let all = Array(queue.indices)
        guard shuffle, let cur = currentIndex else { order = all; return }
        order = [cur] + all.filter { $0 != cur }.shuffled()
    }

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.currentTime = self?.engine.currentTime ?? 0 }
        }
        // .common — чтобы прогресс не замирал, пока открыто меню.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
