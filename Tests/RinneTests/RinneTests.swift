import XCTest
@testable import Rinne

final class RinneTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Rinne().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
