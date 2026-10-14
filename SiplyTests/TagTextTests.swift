import XCTest
@testable import Siply

final class TagTextTests: XCTestCase {
    func testCP1251ReadAsLatin1IsRepaired() {
        XCTAssertEqual(LibraryScanner.repairTag("Êóðþ"), "Курю")
        XCTAssertEqual(LibraryScanner.repairTag("Ñåðãåé Ìàçàåâ"), "Сергей Мазаев")
        XCTAssertEqual(LibraryScanner.repairTag("ß ëþáëþ òåáÿ ïî ñëåç (Ëîâåéêà)"), "Я люблю тебя по слез (Ловейка)")
        XCTAssertEqual(LibraryScanner.repairTag("Äà÷íèêè"), "Дачники")
    }

    func testRealTextIsUntouched() {
        for s in ["Beyoncé", "Mötley Crüe", "Sigur Rós", "Smooth", "007", "Белая Стрекоза Любви", ""] {
            XCTAssertEqual(LibraryScanner.repairTag(s), s)
        }
    }
}
