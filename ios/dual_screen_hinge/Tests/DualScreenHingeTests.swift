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

    let regions = UnsupportedReservedRegionProvider()
    XCTAssertFalse(regions.isSupported)
    XCTAssertTrue(regions.regions(in: UIView()).isEmpty)
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
  @MainActor
  func testReservedRegionsAndActiveDivisionFeatureMapping() {
    let hingeProvider = MockHingeProvider()
    let regionProvider = MockReservedRegionProvider()
    regionProvider.samples = [
      ReservedRegionSample(
        bounds: CGRect(x: 400, y: 0, width: 12, height: 900),
        kind: "division",
        isActive: true
      ),
      ReservedRegionSample(
        bounds: CGRect(x: 400, y: 0, width: 0, height: 900),
        kind: "division",
        isActive: false
      ),
      ReservedRegionSample(
        bounds: CGRect(x: 760, y: 0, width: 64, height: 48),
        kind: "occlusion",
        isActive: true
      ),
    ]
    let controller = UIViewController()
    controller.loadViewIfNeeded()
    let handler = DualScreenStreamHandler(
      viewController: controller,
      provider: hingeProvider,
      regionProvider: regionProvider
    )

    let state = handler.currentState
    let regions = state["reservedRegions"] as? [[String: Any]]
    let features = state["displayFeatures"] as? [[String: Any]]

    XCTAssertEqual(regions?.count, 3)
    XCTAssertEqual(regions?.first?["kind"] as? String, "division")
    XCTAssertEqual(regions?.first?["isActive"] as? Bool, true)
    let regionBounds = regions?.first?["bounds"] as? [String: Double]
    XCTAssertEqual(regionBounds?["left"], 400)
    XCTAssertEqual(regionBounds?["top"], 0)
    XCTAssertEqual(regionBounds?["right"], 412)
    XCTAssertEqual(regionBounds?["bottom"], 900)
    XCTAssertEqual(features?.count, 1)
    XCTAssertEqual(features?.first?["type"] as? String, "fold")
    XCTAssertEqual(features?.first?["orientation"] as? String, "vertical")
    XCTAssertEqual(features?.first?["occlusion"] as? String, "none")
    XCTAssertEqual(features?.first?["isSeparating"] as? Bool, true)
    XCTAssertEqual(state["activeScreen"] as? String, "inner")
    XCTAssertEqual(state["isInnerScreen"] as? Bool, true)
    XCTAssertFalse((state["supportedPostures"] as? [String] ?? []).contains("tent"))
    XCTAssertEqual(handler.capabilities["reservedRegionGeometry"] as? Bool, true)
  }

  @MainActor
  func testReservedRegionsWorkBeforeHingeTelemetryStarts() {
    let regionProvider = MockReservedRegionProvider()
    regionProvider.samples = [
      ReservedRegionSample(
        bounds: CGRect(x: 400, y: 0, width: 0, height: 900),
        kind: "division",
        isActive: false
      ),
    ]
    let controller = UIViewController()
    controller.loadViewIfNeeded()
    let handler = DualScreenStreamHandler(
      viewController: controller,
      provider: UnsupportedHingeProvider(),
      regionProvider: regionProvider
    )

    let state = handler.currentState
    XCTAssertEqual(state["activeScreen"] as? String, "inner")
    XCTAssertEqual(state["isInnerScreen"] as? Bool, true)
    XCTAssertEqual(handler.capabilities["platformSupported"] as? Bool, true)
    XCTAssertEqual(handler.capabilities["reservedRegionGeometry"] as? Bool, true)
  }

  @MainActor
  func testUnchangedReservedRegionStateIsDeduplicated() {
    let hingeProvider = MockHingeProvider()
    let regionProvider = MockReservedRegionProvider()
    regionProvider.samples = [
      ReservedRegionSample(
        bounds: CGRect(x: 200, y: 0, width: 8, height: 600),
        kind: "division",
        isActive: true
      ),
    ]
    let controller = UIViewController()
    controller.loadViewIfNeeded()
    let handler = DualScreenStreamHandler(
      viewController: controller,
      provider: hingeProvider,
      regionProvider: regionProvider
    )
    var events: [[String: Any]] = []

    XCTAssertNil(handler.onListen(withArguments: nil) { value in
      if let event = value as? [String: Any] { events.append(event) }
    })
    hingeProvider.send(angle: nil, status: "unknown")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

    XCTAssertEqual(events.count, 1)
    XCTAssertNil(handler.onCancel(withArguments: nil))
  }
  #endif
}
