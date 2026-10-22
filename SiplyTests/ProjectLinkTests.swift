import XCTest
@testable import Siply

final class ProjectLinkTests: XCTestCase {
    func testCreditsLinksToVibecoded() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "Credits", withExtension: "rtf"))
        let text = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
        XCTAssertTrue(text.string.contains("проект vibecoded.ru"))
        let range = (text.string as NSString).range(of: "vibecoded.ru")
        XCTAssertNotEqual(range.location, NSNotFound)
        let link = text.attribute(.link, at: range.location, effectiveRange: nil)
        XCTAssertEqual((link as? URL)?.absoluteString ?? link as? String, "https://vibecoded.ru")
    }
}
