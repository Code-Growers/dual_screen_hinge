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

  func testHingeAngleIsConvertedFromRadians() {
    XCTAssertEqual(hingeDegrees(fromRadians: 0), 0)
    XCTAssertEqual(hingeDegrees(fromRadians: .pi / 2), 90, accuracy: 1e-9)
    XCTAssertEqual(hingeDegrees(fromRadians: .pi), 180, accuracy: 1e-9)
  }

  func testWindowPlacementFromScreenEdges() {
    let screen = CGRect(x: 0, y: 0, width: 800, height: 600)
    XCTAssertEqual(windowPlacement(windowFrame: screen, screenBounds: screen), "full")
    XCTAssertEqual(
      windowPlacement(windowFrame: CGRect(x: 0, y: 0, width: 396, height: 600), screenBounds: screen),
      "left"
    )
    XCTAssertEqual(
      windowPlacement(windowFrame: CGRect(x: 404, y: 0, width: 396, height: 600), screenBounds: screen),
      "right"
    )
    // A window spanning the width stays full even when split top and bottom.
    XCTAssertEqual(
      windowPlacement(windowFrame: CGRect(x: 0, y: 300, width: 800, height: 300), screenBounds: screen),
      "full"
    )
    XCTAssertEqual(
      windowPlacement(windowFrame: CGRect(x: 0.3, y: 0, width: 400, height: 600), screenBounds: screen),
      "left"
    )
    XCTAssertEqual(
      windowPlacement(windowFrame: CGRect(x: 100, y: 100, width: 400, height: 300), screenBounds: screen),
      "unknown"
    )
    XCTAssertEqual(windowPlacement(windowFrame: .zero, screenBounds: screen), "unknown")
    XCTAssertEqual(windowPlacement(windowFrame: screen, screenBounds: .zero), "unknown")
  }

  func testVerticalBarEdgeResolvesToPhysicalEdge() {
    XCTAssertEqual(physicalBarEdge(leading: true, layoutDirection: .leftToRight), "left")
    XCTAssertEqual(physicalBarEdge(leading: false, layoutDirection: .leftToRight), "right")
    XCTAssertEqual(physicalBarEdge(leading: true, layoutDirection: .rightToLeft), "right")
    XCTAssertEqual(physicalBarEdge(leading: false, layoutDirection: .rightToLeft), "left")
    XCTAssertEqual(physicalBarEdge(leading: true, layoutDirection: .unspecified), "left")
  }

  func testVerticalBarEdgeIsUnknownOutsideAWindow() {
    XCTAssertEqual(VerticalBarEdgeReader.edge(of: nil), "unknown")
    XCTAssertEqual(VerticalBarEdgeReader.edge(of: UIView()), "unknown")
  }

  #if DUAL_SCREEN_HINGE_IOS27
  func testUIKitHingeStatusNamesMapToPostures() throws {
    guard #available(iOS 27.1, *) else { throw XCTSkip("Requires iOS 27.1") }
    let cases: [(UIHinge.Status, String)] = [
      (.closed, "closed"),
      (.partiallyOpen, "halfOpened"),
      (.fullyOpen, "flat"),
      (.unknown, "unknown"),
    ]
    for (status, posture) in cases {
      XCTAssertEqual(mapNativeHingePosture(IOS27HingeProvider.statusName(status)), posture)
    }
  }
  #endif

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
  func testPostureSourceWaitsForFirstHingeSample() {
    let provider = MockHingeProvider()
    let controller = UIViewController()
    controller.loadViewIfNeeded()
    let handler = DualScreenStreamHandler(viewController: controller, provider: provider)
    var events: [[String: Any]] = []

    XCTAssertNil(handler.onListen(withArguments: nil) { value in
      if let event = value as? [String: Any] { events.append(event) }
    })
    XCTAssertTrue(provider.isSupported)
    XCTAssertEqual(events.last?["postureSource"] as? String, "unavailable")
    XCTAssertEqual(events.last?["hingeAngle"] as? NSNull, NSNull())

    provider.send(angle: 128, status: "partiallyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    XCTAssertEqual(events.last?["postureSource"] as? String, "platform")
    XCTAssertEqual(events.last?["posture"] as? String, "halfOpened")
    XCTAssertNil(handler.onCancel(withArguments: nil))
  }

  // UIScene apps register plugins before the Flutter view controller exists.
  @MainActor
  func testAttachesWhenViewControllerAppearsAfterListen() {
    let provider = MockHingeProvider()
    let regionProvider = MockReservedRegionProvider()
    regionProvider.samples = [
      ReservedRegionSample(
        bounds: CGRect(x: 400, y: 0, width: 12, height: 900),
        kind: "division",
        isActive: true
      ),
    ]
    var controller: UIViewController?
    let handler = DualScreenStreamHandler(
      viewControllerProvider: { controller },
      provider: provider,
      regionProvider: regionProvider
    )
    var events: [[String: Any]] = []

    XCTAssertNil(handler.onListen(withArguments: nil) { value in
      if let event = value as? [String: Any] { events.append(event) }
    })
    XCTAssertEqual((events.last?["reservedRegions"] as? [[String: Any]])?.count, 0)

    let host = UIViewController()
    host.loadViewIfNeeded()
    controller = host
    NotificationCenter.default.post(name: UIWindow.didBecomeVisibleNotification, object: nil)
    provider.send(angle: 120, status: "partiallyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

    XCTAssertEqual(events.last?["hingeAngle"] as? Double, 120)
    XCTAssertEqual((events.last?["reservedRegions"] as? [[String: Any]])?.count, 1)
    XCTAssertEqual(events.last?["activeScreen"] as? String, "inner")
    XCTAssertNil(handler.onCancel(withArguments: nil))
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
    // The controller was never placed in a window.
    XCTAssertEqual(state["windowPlacement"] as? String, "unknown")
    XCTAssertEqual(state["verticalBarEdge"] as? String, "unknown")
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
    hingeProvider.send(angle: 90, status: "partiallyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    let countAfterFirstSample = events.count

    hingeProvider.send(angle: 90, status: "partiallyOpen")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

    XCTAssertEqual(events.count, countAfterFirstSample)
    XCTAssertNil(handler.onCancel(withArguments: nil))
  }
  #endif
}
