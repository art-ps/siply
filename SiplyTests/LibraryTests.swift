import XCTest
@testable import Siply

@MainActor
final class LibraryTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SiplyLibraryTests")!
        defaults.removePersistentDomain(forName: "SiplyLibraryTests")
    }

    func testFreshLibraryHasNoRoot() {
        XCTAssertNil(Library(defaults: defaults).root)
    }

    func testOpenSetsRootAndSelectionAndPersists() {
        let tmp = TempDir()
        let lib = Library(defaults: defaults)
        lib.open(tmp.url)
        XCTAssertEqual(lib.root?.url, tmp.url.standardizedFileURL)
        XCTAssertEqual(lib.selection, lib.root)

        let again = Library(defaults: defaults)
        XCTAssertEqual(again.root?.url, tmp.url.standardizedFileURL)
        XCTAssertEqual(again.selection, again.root)
    }

    func testOpenFolderOfFileSetsRootSelectionAndPersists() {
        let tmp = TempDir()
        let file = tmp.file("a.mp3")
        let lib = Library(defaults: defaults)
        lib.openFolder(of: file)
        XCTAssertEqual(lib.root?.url, tmp.url.standardizedFileURL)
        XCTAssertEqual(lib.selection, lib.root)
        XCTAssertEqual(Library(defaults: defaults).root?.url, tmp.url.standardizedFileURL)
    }

    func testOpenFolderOfFileInCurrentRootKeepsTree() {
        let tmp = TempDir()
        let lib = Library(defaults: defaults)
        lib.open(tmp.url)
        let root = lib.root
        lib.selection = nil
        lib.openFolder(of: tmp.file("a.mp3"))
        XCTAssertTrue(lib.root === root)
        XCTAssertEqual(lib.selection, root)
        XCTAssertEqual(lib.generation, 0)
    }

    func testRestoreMissingFolderGivesNoRoot() {
        let tmp = TempDir()
        Library(defaults: defaults).open(tmp.url)
        try! FileManager.default.removeItem(at: tmp.url)
        XCTAssertNil(Library(defaults: defaults).root)
    }

    func testRescanRebuildsTreeKeepsSelectionBumpsGeneration() {
        let tmp = TempDir()
        let lib = Library(defaults: defaults)
        lib.open(tmp.url)
        XCTAssertNil(lib.root?.children)

        let sub = tmp.dir("album")
        lib.rescan()
        XCTAssertEqual(lib.root?.children?.map(\.name), ["album"])
        XCTAssertEqual(lib.selection, lib.root)
        XCTAssertEqual(lib.generation, 1)

        lib.selection = FolderNode(url: sub)
        lib.rescan()
        XCTAssertEqual(lib.selection?.url, sub.standardizedFileURL)
        XCTAssertEqual(lib.generation, 2)
    }
}
