import XCTest
@testable import Siply

final class SmokeTests: XCTestCase {
    func testTargetLinks() {
        XCTAssertNotNil(SiplyApp.self)
    }
}
