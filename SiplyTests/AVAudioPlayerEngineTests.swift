import XCTest
@testable import Siply

@MainActor
final class AVAudioPlayerEngineTests: XCTestCase {
    func testLoadRealWavExposesDuration() throws {
        let tmp = TempDir()
        let url = tmp.url.appendingPathComponent("s.wav")
        try AudioFixtures.writeWav(to: url, seconds: 1.5)
        let engine = AVAudioPlayerEngine()
        try engine.load(url)
        XCTAssertEqual(engine.duration, 1.5, accuracy: 0.05)
        engine.currentTime = 1
        XCTAssertEqual(engine.currentTime, 1, accuracy: 0.05)
    }

    func testLoadGarbageThrows() {
        let tmp = TempDir()
        let url = tmp.file("bad.mp3", Data("nope".utf8))
        XCTAssertThrowsError(try AVAudioPlayerEngine().load(url))
    }

    func testVolumeSurvivesLoad() throws {
        let tmp = TempDir()
        let url = tmp.url.appendingPathComponent("s.wav")
        try AudioFixtures.writeWav(to: url)
        let engine = AVAudioPlayerEngine()
        engine.volume = 0.25
        try engine.load(url)
        XCTAssertEqual(engine.volume, 0.25)
    }
}
