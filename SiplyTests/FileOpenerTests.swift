import XCTest
@testable import Siply

@MainActor
final class FileOpenerTests: XCTestCase {
    private var dir: TempDir!
    private var library: Library!
    private var player: PlayerModel!

    override func setUp() async throws {
        try await super.setUp()
        let defaults = UserDefaults(suiteName: "SiplyFileOpenerTests")!
        defaults.removePersistentDomain(forName: "SiplyFileOpenerTests")
        dir = TempDir()
        for name in ["01 A.wav", "02 B.wav", "03 C.wav"] {
            try AudioFixtures.writeWav(to: dir.url.appendingPathComponent(name))
        }
        _ = dir.file("04 Bad.mp3", Data("garbage".utf8))
        try FileManager.default.createDirectory(at: dir.url.appendingPathComponent("sub"),
                                                withIntermediateDirectories: true)
        library = Library(defaults: defaults)
        player = PlayerModel(engine: FakeAudioEngine(), defaults: defaults)
    }

    func testOpenPlaysFileWithWholeFolderQueue() async {
        await FileOpener.open([dir.url.appendingPathComponent("02 B.wav")], library: library, player: player)
        XCTAssertEqual(library.root?.url, dir.url.standardizedFileURL)
        XCTAssertEqual(player.queue.map { $0.url.lastPathComponent }, ["01 A.wav", "02 B.wav", "03 C.wav"])
        XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "02 B.wav")
        XCTAssertTrue(player.isPlaying)
        XCTAssertEqual(library.revealURL?.lastPathComponent, "02 B.wav")
    }

    func testOpenTakesFirstOfSeveralURLs() async {
        await FileOpener.open([dir.url.appendingPathComponent("03 C.wav"), dir.url.appendingPathComponent("01 A.wav")],
                              library: library, player: player)
        XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "03 C.wav")
    }

    func testOpenMatchesNonStandardizedURL() async {
        let odd = dir.url.appendingPathComponent("sub/../02 B.wav")
        await FileOpener.open([odd], library: library, player: player)
        XCTAssertEqual(player.currentTrack?.url.lastPathComponent, "02 B.wav")
    }

    func testOpenUnplayableFileOpensFolderKeepsCurrentPlayback() async {
        let other = Track(url: URL(fileURLWithPath: "/m/x.mp3"))
        player.play(queue: [other], startingAt: 0)
        await FileOpener.open([dir.url.appendingPathComponent("04 Bad.mp3")], library: library, player: player)
        XCTAssertEqual(library.root?.url, dir.url.standardizedFileURL)
        XCTAssertEqual(player.currentTrack, other)
        XCTAssertNil(library.revealURL)
        XCTAssertTrue(player.isPlaying)
    }

    func testOpenEmptyListDoesNothing() async {
        await FileOpener.open([], library: library, player: player)
        XCTAssertNil(library.root)
        XCTAssertNil(player.currentTrack)
    }

    func testAppDeclaresAudioDocumentTypes() {
        let types = (Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]]) ?? []
        let utis = Set(types.flatMap { $0["LSItemContentTypes"] as? [String] ?? [] })
        XCTAssertEqual(utis, ["public.mp3", "public.mpeg-4-audio", "public.aac-audio", "org.xiph.flac",
                              "com.microsoft.waveform-audio", "public.aiff-audio", "public.aifc-audio",
                              "com.apple.coreaudio-format"])
    }
}
