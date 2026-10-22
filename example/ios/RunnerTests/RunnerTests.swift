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

  /// Split View and resizing shrink the window below the screen; screen
  /// identity must then stay unknown unless a division region proves it.
  func testScreenIdentityIsConservativeInPartialWindows() throws {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene }).first
    else { throw XCTSkip("No window scene.") }
    let screen = scene.screen.coordinateSpace.bounds

    func state(windowFrame: CGRect, regions: [ReservedRegionSample]) -> [String: Any] {
      let controller = UIViewController()
      let window = UIWindow(windowScene: scene)
      window.frame = windowFrame
      window.rootViewController = controller
      window.isHidden = false
      defer { window.isHidden = true }
      let regionProvider = MockReservedRegionProvider()
      regionProvider.samples = regions
      let handler = DualScreenStreamHandler(
        viewController: controller,
        provider: MockHingeProvider(),
        regionProvider: regionProvider
      )
      var last: [String: Any] = [:]
      _ = handler.onListen(withArguments: nil) { value in
        if let event = value as? [String: Any] { last = event }
      }
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
      _ = handler.onCancel(withArguments: nil)
      return last
    }

    let camera = ReservedRegionSample(
      bounds: CGRect(x: 10, y: 10, width: 30, height: 30), kind: "occlusion", isActive: true)
    var half = screen
    half.size.width /= 2

    let partial = state(windowFrame: half, regions: [camera])
    XCTAssertEqual(partial["activeScreen"] as? String, "unknown")
    XCTAssertTrue(partial["isInnerScreen"] is NSNull)
    XCTAssertEqual(partial["windowPlacement"] as? String, "left")

    var rightHalf = half
    rightHalf.origin.x = screen.maxX - half.width
    let trailing = state(windowFrame: rightHalf, regions: [camera])
    XCTAssertEqual(trailing["activeScreen"] as? String, "unknown")
    XCTAssertEqual(trailing["windowPlacement"] as? String, "right")

    let full = state(windowFrame: screen, regions: [camera])
    XCTAssertNotEqual(full["activeScreen"] as? String, "unknown")
    XCTAssertEqual(full["windowPlacement"] as? String, "full")

    let division = ReservedRegionSample(
      bounds: CGRect(x: half.width - 20, y: 0, width: 40, height: screen.height),
      kind: "division", isActive: true)
    let spanning = state(windowFrame: half, regions: [division])
    XCTAssertEqual(spanning["activeScreen"] as? String, "inner")
  }

  /// UIKit reports the bar edge relative to the layout direction, while the
  /// bar itself stays on the same hardware edge in right-to-left languages.
  func testVerticalBarEdgeIsPhysicalInBothLayoutDirections() throws {
    guard #available(iOS 17.0, *) else { throw XCTSkip("Trait overrides need iOS 17.") }
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene }).first
    else { throw XCTSkip("No window scene.") }

    func edge(_ direction: UITraitEnvironmentLayoutDirection) -> (String, UIEdgeInsets) {
      let controller = UIViewController()
      let window = UIWindow(windowScene: scene)
      window.rootViewController = controller
      window.isHidden = false
      defer { window.isHidden = true }
      controller.traitOverrides.layoutDirection = direction
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
      controller.view.layoutIfNeeded()
      return (VerticalBarEdgeReader.edge(of: controller.view), controller.view.safeAreaInsets)
    }

    let (leftToRight, insets) = edge(.leftToRight)
    let (rightToLeft, _) = edge(.rightToLeft)
    if leftToRight == "unknown" { throw XCTSkip("SDK or OS without verticalBarEdge.") }
    XCTAssertEqual(rightToLeft, leftToRight)
    switch leftToRight {
    case "left": XCTAssertGreaterThan(insets.left, insets.right)
    case "right": XCTAssertGreaterThan(insets.right, insets.left)
    default: XCTAssertEqual(leftToRight, "none")
    }
  }
}
