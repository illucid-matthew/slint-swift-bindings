// Ultra basic test, just to prove that testing works
import XCTest

@testable import SlintUI

final class ExampleTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(true, true)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}