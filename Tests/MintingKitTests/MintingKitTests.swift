import XCTest

@testable import MintingKit

final class MintingKitTests: XCTestCase {
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    XCTAssertEqual(MintingKit(authToken: "faketoken").authToken, "faketoken")
  }
}
