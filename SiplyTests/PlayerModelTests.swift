import XCTest
@testable import Siply

@MainActor
final class PlayerModelTests: XCTestCase {
    private var engine: FakeAudioEngine!
    private var player: PlayerModel!
    private var defaults: UserDefaults!
    private let tracks = (1...4).map { Track(url: URL(fileURLWithPath: "/m/\($0).mp3")) }

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SiplyPlayerModelTests")!
        defaults.removePersistentDomain(forName: "SiplyPlayerModelTests")
        engine = FakeAudioEngine()
        player = PlayerModel(engine: engine, defaults: defaults)
    }

    func testPlayLoadsAndPlaysChosenTrack() {
        player.play(queue: tracks, startingAt: 1)
        XCTAssertEqual(engine.loaded, [tracks[1].url])
        XCTAssertTrue(engine.playing)
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(player.currentTrack, tracks[1])
    }

    func testPlayWithBadIndexDoesNothing() {
        player.play(queue: tracks, startingAt: 9)
        XCTAssertNil(player.currentTrack)
        XCTAssertFalse(player.isPlaying)
    }

    func testTogglePlayPause() {
        player.play(queue: tracks, startingAt: 0)
        player.togglePlayPause()
        XCTAssertFalse(player.isPlaying); XCTAssertFalse(engine.playing)
        player.togglePlayPause()
        XCTAssertTrue(player.isPlaying); XCTAssertTrue(engine.playing)
    }

    func testToggleWithoutQueueDoesNothing() {
        player.togglePlayPause()
        XCTAssertFalse(player.isPlaying)
    }

    func testFinishedAdvances() {
        player.play(queue: tracks, startingAt: 0)
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[1])
        XCTAssertTrue(player.isPlaying)
    }

    func testFinishedAtEndWithRepeatOffStopsOnLastTrack() {
        player.play(queue: tracks, startingAt: 3)
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[3])
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(engine.playing)
        XCTAssertEqual(engine.currentTime, 0)
        XCTAssertEqual(player.currentTime, 0)
    }

    func testRepeatAllWrapsToFirst() {
        player.repeatMode = .all
        player.play(queue: tracks, startingAt: 3)
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[0])
    }

    func testRepeatOneReplaysSame() {
        player.repeatMode = .one
        player.play(queue: tracks, startingAt: 2)
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[2])
        XCTAssertEqual(engine.loaded, [tracks[2].url, tracks[2].url])
    }

    func testNextAtEndWrapsForUser() {
        player.play(queue: tracks, startingAt: 3)
        player.next()
        XCTAssertEqual(player.currentTrack, tracks[0])
        XCTAssertTrue(player.isPlaying)
    }

    func testPreviousAfterThreeSecondsRestartsTrack() {
        player.play(queue: tracks, startingAt: 2)
        engine.currentTime = 5
        player.previous()
        XCTAssertEqual(player.currentTrack, tracks[2])
        XCTAssertEqual(engine.currentTime, 0)
        XCTAssertEqual(engine.loaded.count, 1)
    }

    func testPreviousEarlyGoesToPreviousTrack() {
        player.play(queue: tracks, startingAt: 2)
        engine.currentTime = 1
        player.previous()
        XCTAssertEqual(player.currentTrack, tracks[1])
    }

    func testPreviousOnFirstWrapsToLast() {
        player.play(queue: tracks, startingAt: 0)
        player.previous()
        XCTAssertEqual(player.currentTrack, tracks[3])
    }

    func testSeekUpdatesEngineAndState() {
        player.play(queue: tracks, startingAt: 0)
        player.seek(to: 42)
        XCTAssertEqual(engine.currentTime, 42)
        XCTAssertEqual(player.currentTime, 42)
    }

    func testShuffleKeepsCurrentAndVisitsEveryTrackOnce() {
        player.play(queue: tracks, startingAt: 1)
        player.shuffle = true
        var seen = [player.currentTrack!]
        for _ in 0..<3 { engine.finish(); seen.append(player.currentTrack!) }
        XCTAssertEqual(seen.first, tracks[1])
        XCTAssertEqual(Set(seen), Set(tracks))
        engine.finish()
        XCTAssertFalse(player.isPlaying, "после обхода всех при repeat off — стоп")
    }

    func testShuffleOffRestoresFolderOrder() {
        player.play(queue: tracks, startingAt: 1)
        player.shuffle = true
        player.shuffle = false
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[2])
    }

    func testUnreadableTrackIsSkipped() {
        engine.failing = [tracks[1].url]
        player.play(queue: tracks, startingAt: 0)
        engine.finish()
        XCTAssertEqual(player.currentTrack, tracks[2])
        XCTAssertTrue(player.isPlaying)
    }

    func testUnreadableStartTrackSkipsForward() {
        engine.failing = [tracks[0].url]
        player.play(queue: tracks, startingAt: 0)
        XCTAssertEqual(player.currentTrack, tracks[1])
        XCTAssertTrue(player.isPlaying)
    }

    func testUnreadableStartAtEndWrapsToFirst() {
        engine.failing = [tracks[3].url]
        player.play(queue: tracks, startingAt: 3)
        XCTAssertEqual(player.currentTrack, tracks[0])
        XCTAssertTrue(player.isPlaying)
    }

    func testAllUnreadableStops() {
        engine.failing = Set(tracks.map(\.url))
        player.play(queue: tracks, startingAt: 0)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(engine.loaded, [])
        XCTAssertNil(player.currentTrack)
        player.togglePlayPause()
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(engine.playing)
    }

    func testCycleRepeat() {
        XCTAssertEqual(player.repeatMode, .off)
        player.cycleRepeat(); XCTAssertEqual(player.repeatMode, .all)
        player.cycleRepeat(); XCTAssertEqual(player.repeatMode, .one)
        player.cycleRepeat(); XCTAssertEqual(player.repeatMode, .off)
    }

    func testSettingsPersist() {
        player.volume = 0.3
        player.shuffle = true
        player.repeatMode = .one
        let again = PlayerModel(engine: FakeAudioEngine(), defaults: defaults)
        XCTAssertEqual(again.volume, 0.3)
        XCTAssertTrue(again.shuffle)
        XCTAssertEqual(again.repeatMode, .one)
    }

    func testVolumeDefaultsToOneAndReachesEngine() {
        XCTAssertEqual(player.volume, 1)
        player.volume = 0.5
        XCTAssertEqual(engine.volume, 0.5)
    }
}
