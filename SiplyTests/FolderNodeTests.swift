import XCTest
@testable import Siply

final class FolderNodeTests: XCTestCase {
    func testChildrenAreOnlyVisibleSubfoldersSortedLikeFinder() {
        let tmp = TempDir()
        tmp.dir("beta")
        tmp.dir("Alpha")
        tmp.dir("album 10")
        tmp.dir("album 2")
        tmp.dir(".hidden")
        tmp.file("song.mp3")

        let node = FolderNode(url: tmp.url)
        XCTAssertEqual(node.children?.map(\.name), ["album 2", "album 10", "Alpha", "beta"])
    }

    func testNoSubfoldersGivesNil() {
        let tmp = TempDir()
        tmp.file("song.mp3")
        XCTAssertNil(FolderNode(url: tmp.url).children)
    }

    func testUnreadableFolderGivesNil() {
        let node = FolderNode(url: URL(fileURLWithPath: "/nonexistent/siply"))
        XCTAssertNil(node.children)
    }

    func testEqualityByURL() {
        let tmp = TempDir()
        XCTAssertEqual(FolderNode(url: tmp.url), FolderNode(url: tmp.url))
        XCTAssertEqual(FolderNode(url: tmp.url).hashValue, FolderNode(url: tmp.url).hashValue)
    }
}
