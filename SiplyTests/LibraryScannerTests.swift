import XCTest
@testable import Siply

final class LibraryScannerTests: XCTestCase {
    func testAudioFilesFiltersByExtensionCaseInsensitiveAndSkipsHiddenAndSubfolders() {
        let tmp = TempDir()
        tmp.file("b.mp3")
        tmp.file("A.FLAC")
        tmp.file("c.M4A")
        tmp.file("notes.txt")
        tmp.file("cover.jpg")
        tmp.file(".hidden.mp3")
        let sub = tmp.dir("sub")
        try! Data().write(to: sub.appendingPathComponent("d.mp3"))

        let names = LibraryScanner.audioFiles(in: tmp.url).map(\.lastPathComponent)
        XCTAssertEqual(names, ["A.FLAC", "b.mp3", "c.M4A"])
    }

    func testAudioFilesOfMissingFolderIsEmpty() {
        XCTAssertEqual(LibraryScanner.audioFiles(in: URL(fileURLWithPath: "/nonexistent/siply")), [])
    }

    func testLoadTrackOnUnreadableFileFallsBackToFilename() async {
        let tmp = TempDir()
        let url = tmp.file("01 Intro.mp3", Data("not audio".utf8))
        let t = await LibraryScanner.loadTrack(url)
        XCTAssertEqual(t.title, "01 Intro")
        XCTAssertEqual(t.trackNumber, 1)
        XCTAssertEqual(t.duration, 0)
    }

    func testLoadTrackReadsDurationOfRealWav() async throws {
        let tmp = TempDir()
        let url = tmp.url.appendingPathComponent("02 Silence.wav")
        try AudioFixtures.writeWav(to: url, seconds: 2)
        let t = await LibraryScanner.loadTrack(url)
        XCTAssertEqual(t.duration, 2, accuracy: 0.05)
        XCTAssertEqual(t.title, "02 Silence")
        XCTAssertEqual(t.trackNumber, 2)
    }

    func testTracksAreSorted() async throws {
        let tmp = TempDir()
        try AudioFixtures.writeWav(to: tmp.url.appendingPathComponent("10 Ten.wav"))
        try AudioFixtures.writeWav(to: tmp.url.appendingPathComponent("2 Two.wav"))
        try AudioFixtures.writeWav(to: tmp.url.appendingPathComponent("Zeta.wav"))
        let titles = await LibraryScanner.tracks(in: tmp.url).map(\.title)
        XCTAssertEqual(titles, ["2 Two", "10 Ten", "Zeta"])
    }

    func testTracksSkipUnplayableFiles() async throws {
        let tmp = TempDir()
        tmp.file("01 Broken.mp3", Data("not audio".utf8))
        try AudioFixtures.writeWav(to: tmp.url.appendingPathComponent("02 Good.wav"))
        let names = await LibraryScanner.tracks(in: tmp.url).map { $0.url.lastPathComponent }
        XCTAssertEqual(names, ["02 Good.wav"])
    }

    func testIsPlayable() async throws {
        let tmp = TempDir()
        let bad = tmp.file("x.mp3", Data("not audio".utf8))
        let good = tmp.url.appendingPathComponent("y.wav")
        try AudioFixtures.writeWav(to: good)
        let badOK = await LibraryScanner.isPlayable(bad)
        let goodOK = await LibraryScanner.isPlayable(good)
        XCTAssertFalse(badOK)
        XCTAssertTrue(goodOK)
    }

    func testFolderArtworkPrefersTrackArtworkThenCoverFile() {
        let tmp = TempDir()
        let cover = Data([0xFF, 0xD8, 0xFF])
        tmp.file("cover.jpg", cover)
        let plain = Track(url: tmp.url.appendingPathComponent("a.mp3"))
        var withArt = plain
        withArt.artwork = Data([1, 2, 3])

        XCTAssertEqual(LibraryScanner.folderArtwork(for: tmp.url, tracks: [plain, withArt]), Data([1, 2, 3]))
        XCTAssertEqual(LibraryScanner.folderArtwork(for: tmp.url, tracks: [plain]), cover)
        XCTAssertNil(LibraryScanner.folderArtwork(for: TempDir().url, tracks: [plain]))
    }
}
