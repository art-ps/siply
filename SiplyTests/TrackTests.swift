import XCTest
@testable import Siply

final class TrackTests: XCTestCase {
    private func url(_ name: String) -> URL { URL(fileURLWithPath: "/music/\(name)") }

    func testLeadingNumber() {
        XCTAssertEqual(Track.leadingNumber(in: "03 - Song"), 3)
        XCTAssertEqual(Track.leadingNumber(in: "12. Song"), 12)
        XCTAssertEqual(Track.leadingNumber(in: "1-07 Song"), 7)
        XCTAssertEqual(Track.leadingNumber(in: "7_Song"), 7)
        XCTAssertNil(Track.leadingNumber(in: "Song"))
        XCTAssertNil(Track.leadingNumber(in: "1999"))
        XCTAssertNil(Track.leadingNumber(in: "2024 remix"))
    }

    func testInitFromURLFallsBackToFilename() {
        let t = Track(url: url("02 Intro.flac"))
        XCTAssertEqual(t.title, "02 Intro")
        XCTAssertEqual(t.trackNumber, 2)
        XCTAssertEqual(t.artist, "")
        XCTAssertEqual(t.album, "")
        XCTAssertEqual(t.duration, 0)
        XCTAssertNil(t.artwork)
        XCTAssertEqual(t.id, url("02 Intro.flac"))
    }

    func testSortedByTrackNumberThenFilename() {
        let b = Track(url: url("b.mp3"), title: "B", trackNumber: nil)
        let a = Track(url: url("a.mp3"), title: "A", trackNumber: nil)
        let n2 = Track(url: url("z.mp3"), title: "Z", trackNumber: 2)
        let n10 = Track(url: url("y.mp3"), title: "Y", trackNumber: 10)
        XCTAssertEqual(Track.sorted([b, n10, a, n2]).map(\.title), ["Z", "Y", "A", "B"])
    }

    func testCountLabel() {
        XCTAssertEqual(Track.countLabel(1), "1 трек")
        XCTAssertEqual(Track.countLabel(2), "2 трека")
        XCTAssertEqual(Track.countLabel(5), "5 треков")
        XCTAssertEqual(Track.countLabel(11), "11 треков")
        XCTAssertEqual(Track.countLabel(21), "21 трек")
        XCTAssertEqual(Track.countLabel(0), "0 треков")
    }

    func testMMSS() {
        XCTAssertEqual(TimeInterval(83).mmss, "1:23")
        XCTAssertEqual(TimeInterval(600).mmss, "10:00")
        XCTAssertEqual(TimeInterval(0).mmss, "0:00")
        XCTAssertEqual(TimeInterval.nan.mmss, "0:00")
        XCTAssertEqual(TimeInterval(-5).mmss, "0:00")
    }
}
