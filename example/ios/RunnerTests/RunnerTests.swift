import Flutter
import UIKit
import XCTest

@testable import dual_screen_hinge

@MainActor
final class RunnerTests: XCTestCase {
  func testCurrentStateContract() {
    let plugin = DualScreenHingePlugin(viewController: UIViewController())
    let call = FlutterMethodCall(methodName: "currentState", arguments: nil)
    let resultExpectation = expectation(description: "currentState result")
    plugin.handle(call) { result in
      let state = result as? [String: Any]
      XCTAssertEqual(state?["schemaVersion"] as? Int, 1)
      XCTAssertNotNil(state?["isInnerScreen"])
      XCTAssertNotNil(state?["reservedRegions"] as? [[String: Any]])
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
