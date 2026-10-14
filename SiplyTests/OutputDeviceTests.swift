import XCTest
@testable import Siply

@MainActor
final class OutputDeviceTests: XCTestCase {
    private var engine: FakeAudioEngine!
    private var player: PlayerModel!
    private var defaults: UserDefaults!
    private let speakers = OutputDevice(uid: "builtin", name: "Динамики Mac mini")
    private let jbl = OutputDevice(uid: "bt-jbl", name: "JBL Flip")

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SiplyOutputDeviceTests")!
        defaults.removePersistentDomain(forName: "SiplyOutputDeviceTests")
        engine = FakeAudioEngine()
        player = PlayerModel(engine: engine, defaults: defaults)
    }

    func testSystemOutputByDefault() {
        player.availableOutputs = [speakers, jbl]
        XCTAssertNil(player.output)
        XCTAssertNil(engine.outputDeviceUID)
    }

    func testChosenDeviceGoesToEngine() {
        player.availableOutputs = [speakers, jbl]
        player.output = jbl
        XCTAssertEqual(engine.outputDeviceUID, "bt-jbl")
        player.output = nil
        XCTAssertNil(engine.outputDeviceUID)
    }

    func testChoiceSurvivesRestart() {
        player.output = jbl
        let again = PlayerModel(engine: engine, defaults: defaults)
        XCTAssertEqual(again.output, jbl)
    }

    func testDisconnectFallsBackToSystemAndReturnsOnReconnect() {
        player.availableOutputs = [speakers, jbl]
        player.output = jbl
        player.play(queue: [Track(url: URL(fileURLWithPath: "/m/1.mp3"))], startingAt: 0)

        player.availableOutputs = [speakers]          // колонка отключилась
        XCTAssertNil(engine.outputDeviceUID)
        XCTAssertEqual(player.output, jbl, "выбор помнится")
        XCTAssertTrue(engine.playing, "музыка не встаёт на паузу")

        player.availableOutputs = [speakers, jbl]     // подключилась снова
        XCTAssertEqual(engine.outputDeviceUID, "bt-jbl")
    }

    func testChoiceAppliedBeforeDeviceListArrives() {
        player.output = jbl
        XCTAssertNil(engine.outputDeviceUID, "устройства ещё не известны — играем как в системе")
        player.availableOutputs = [jbl]
        XCTAssertEqual(engine.outputDeviceUID, "bt-jbl")
    }
}
