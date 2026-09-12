import XCTest
@testable import dual_screen_hinge

final class DualScreenHingeTests: XCTestCase {
  func testNativeStatusMapping() {
    XCTAssertEqual(mapNativeHingePosture("closed"), "closed")
    XCTAssertEqual(mapNativeHingePosture("partiallyOpen"), "halfOpened")
    XCTAssertEqual(mapNativeHingePosture("fullyOpen"), "flat")
    XCTAssertEqual(mapNativeHingePosture("tent"), "tent")
    XCTAssertEqual(mapNativeHingePosture("futureStatus"), "unknown")
  }

  func testUnsupportedProviderIsSafe() {
    let provider = UnsupportedHingeProvider()
    var received: HingeSample?
    provider.start(on: UIView()) { received = $0 }
    XCTAssertFalse(provider.isSupported)
    XCTAssertEqual(received, HingeSample(angle: nil, status: "unknown", hasHinge: false))
    provider.stop()
  }

  #if DEBUG
  @MainActor
  func testMockedEventsAreDeliveredOnMainThreadAndStopOnCancel() {
    let provider = MockHingeProvider()
    let controller = UIViewController()
    controller.loadViewIfNeeded()
    let handler = DualScreenStreamHandler(viewController: controller, provider: provider)
    var events: [[String: Any]] = []

    XCTAssertNil(handler.onListen(withArguments: nil) { value in
      XCTAssertTrue(Thread.isMainThread)
      if let event = value as? [String: Any] { events.append(event) }
    })
    provider.send(angle: 90, status: "partiallyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    XCTAssertEqual(events.last?["hingeAngle"] as? Double, 90)
    XCTAssertEqual(events.last?["posture"] as? String, "halfOpened")

    XCTAssertNil(handler.onCancel(withArguments: nil))
    let countAfterCancel = events.count
    provider.send(angle: 180, status: "fullyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    XCTAssertEqual(events.count, countAfterCancel)
  }
  #endif
}
