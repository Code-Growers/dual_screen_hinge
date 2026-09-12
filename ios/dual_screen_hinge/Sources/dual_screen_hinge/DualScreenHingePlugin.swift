import Flutter
import UIKit

private let methodChannelName = "com.example.iphone_duo_hinge/methods"
private let eventChannelName = "com.example.iphone_duo_hinge/events"

public final class DualScreenHingePlugin: NSObject, FlutterPlugin {
  private let streamHandler: DualScreenStreamHandler

  init(
    viewController: UIViewController?,
    provider: HingeProviding = HingeProviderFactory.make(),
    regionProvider: ReservedRegionProviding = ReservedRegionProviderFactory.make()
  ) {
    streamHandler = DualScreenStreamHandler(
      viewController: viewController,
      provider: provider,
      regionProvider: regionProvider
    )
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = DualScreenHingePlugin(viewController: registrar.viewController)
    let methods = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
    let events = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(plugin, channel: methods)
    events.setStreamHandler(plugin.streamHandler)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    dispatchPrecondition(condition: .onQueue(.main))
    switch call.method {
    case "currentState":
      result(streamHandler.currentState)
    case "capabilities":
      result(streamHandler.capabilities)
    case "startRearDisplay", "stopRearDisplay", "startDualScreen", "stopDualScreen":
      result(FlutterError(
        code: "unsupported",
        message: "iOS does not expose an app-controlled display-mode session API.",
        details: nil
      ))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

struct HingeSample: Equatable {
  let angle: Double?
  let status: String
  let hasHinge: Bool
}

struct ReservedRegionSample: Equatable {
  let bounds: CGRect
  let kind: String
  let isActive: Bool
}

protocol ReservedRegionProviding: AnyObject {
  var isSupported: Bool { get }
  func regions(in view: UIView) -> [ReservedRegionSample]
}

final class UnsupportedReservedRegionProvider: ReservedRegionProviding {
  var isSupported: Bool { false }
  func regions(in view: UIView) -> [ReservedRegionSample] { [] }
}

protocol HingeProviding: AnyObject {
  var isSupported: Bool { get }
  func start(on view: UIView, onChange: @escaping (HingeSample) -> Void)
  func stop()
}

final class UnsupportedHingeProvider: HingeProviding {
  var isSupported: Bool { false }
  func start(on view: UIView, onChange: @escaping (HingeSample) -> Void) {
    onChange(HingeSample(angle: nil, status: "unknown", hasHinge: false))
  }
  func stop() {}
}

#if DEBUG
final class MockHingeProvider: HingeProviding {
  var isSupported = true
  private var callback: ((HingeSample) -> Void)?

  func start(on view: UIView, onChange: @escaping (HingeSample) -> Void) {
    callback = onChange
  }

  func send(angle: Double?, status: String, hasHinge: Bool = true) {
    callback?(HingeSample(angle: angle, status: status, hasHinge: hasHinge))
  }

  func stop() { callback = nil }
}
#endif

#if DEBUG
final class MockReservedRegionProvider: ReservedRegionProviding {
  var isSupported = true
  var samples: [ReservedRegionSample] = []

  func regions(in view: UIView) -> [ReservedRegionSample] { samples }
}
#endif

// Prevents iOS 27 symbols from being parsed by older SDKs.
#if DUAL_SCREEN_HINGE_IOS27
@available(iOS 27.0, *)
final class IOS27HingeProvider: HingeProviding {
  private weak var hostView: UIView?
  private var interaction: UIHingeInteraction?
  private(set) var isSupported = false

  func start(on view: UIView, onChange: @escaping (HingeSample) -> Void) {
    stop()
    hostView = view
    let interaction = UIHingeInteraction { [weak self] _, context in
      guard let self else { return }
      guard let hinge = context.hinge else {
        self.isSupported = false
        DispatchQueue.main.async {
          onChange(HingeSample(angle: nil, status: "unknown", hasHinge: false))
        }
        return
      }
      self.isSupported = true
      let status = String(describing: hinge.status)
      DispatchQueue.main.async {
        onChange(HingeSample(
          angle: hinge.angle.degrees,
          status: status,
          hasHinge: true
        ))
      }
    }
    self.interaction = interaction
    view.addInteraction(interaction)
  }

  func stop() {
    if let interaction { hostView?.removeInteraction(interaction) }
    interaction = nil
    hostView = nil
    isSupported = false
  }
}
#endif

// Reserved-region symbols first appear in the iOS 27.1 SDK. Keeping them in a
// separate compilation block lets older Xcode versions build the safe fallback.
#if DUAL_SCREEN_HINGE_IOS271
@available(iOS 27.1, *)
final class IOS271ReservedRegionProvider: ReservedRegionProviding {
  var isSupported: Bool { true }

  func regions(in view: UIView) -> [ReservedRegionSample] {
    divisionRegions(in: view) + occlusionRegions(in: view)
  }

  private func divisionRegions(in view: UIView) -> [ReservedRegionSample] {
    let activeFrames = view.reservedRegions(kind: .division).map(\.frame)
    return view.reservedRegions(
      kind: .division,
      options: .includeInactive
    ).map { region in
      ReservedRegionSample(
        bounds: region.frame,
        kind: "division",
        isActive: activeFrames.contains(region.frame)
      )
    }
  }

  private func occlusionRegions(in view: UIView) -> [ReservedRegionSample] {
    let activeFrames = view.reservedRegions(kind: .occlusion).map(\.frame)
    return view.reservedRegions(
      kind: .occlusion,
      options: .includeInactive
    ).map { region in
      ReservedRegionSample(
        bounds: region.frame,
        kind: "occlusion",
        isActive: activeFrames.contains(region.frame)
      )
    }
  }
}
#endif

enum HingeProviderFactory {
  static func make() -> HingeProviding {
    #if DUAL_SCREEN_HINGE_IOS27
    if #available(iOS 27.0, *) { return IOS27HingeProvider() }
    #endif
    return UnsupportedHingeProvider()
  }
}

enum ReservedRegionProviderFactory {
  static func make() -> ReservedRegionProviding {
    #if DUAL_SCREEN_HINGE_IOS271
    if #available(iOS 27.1, *) { return IOS271ReservedRegionProvider() }
    #endif
    return UnsupportedReservedRegionProvider()
  }
}

private final class TraitObserverView: UIView {
  var onGeometryChange: (() -> Void)?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard previousTraitCollection != traitCollection else { return }
    onGeometryChange?()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    onGeometryChange?()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    onGeometryChange?()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    onGeometryChange?()
  }
}

final class DualScreenStreamHandler: NSObject, FlutterStreamHandler {
  private weak var viewController: UIViewController?
  private let provider: HingeProviding
  private let regionProvider: ReservedRegionProviding
  private var observerView: TraitObserverView?
  private var sink: FlutterEventSink?
  private var pendingSample: HingeSample?
  private var geometryDirty = false
  private var displayLink: CADisplayLink?
  private var lastEvent: NSDictionary?
  private var sample = HingeSample(angle: nil, status: "unknown", hasHinge: false)

  init(
    viewController: UIViewController?,
    provider: HingeProviding,
    regionProvider: ReservedRegionProviding = UnsupportedReservedRegionProvider()
  ) {
    self.viewController = viewController
    self.provider = provider
    self.regionProvider = regionProvider
  }

  var capabilities: [String: Any] {
    let hingeSupported = sample.hasHinge || provider.isSupported
    let geometrySupported = regionProvider.isSupported
    return [
      "platformSupported": hingeSupported || geometrySupported,
      "hingeAngleSensor": hingeSupported,
      "layoutFeatures": hingeSupported || geometrySupported,
      "reservedRegionGeometry": geometrySupported,
      "rearDisplay": false,
      "dualScreenPresentation": false,
    ]
  }

  var currentState: [String: Any] { buildState() }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    dispatchPrecondition(condition: .onQueue(.main))
    tearDown()
    sink = events

    let hostView = viewController?.view
    let observer = TraitObserverView(frame: hostView?.bounds ?? .zero)
    observer.backgroundColor = .clear
    observer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    observer.isUserInteractionEnabled = false
    observer.accessibilityElementsHidden = true
    observerView = observer
    hostView?.addSubview(observer)

    let link = CADisplayLink(target: self, selector: #selector(displayFrame))
    link.isPaused = true
    link.add(to: .main, forMode: .common)
    displayLink = link
    observer.onGeometryChange = { [weak self] in self?.scheduleGeometryUpdate() }

    provider.start(on: observer) { [weak self] next in
      guard let self else { return }
      if Thread.isMainThread {
        self.pendingSample = next
        self.displayLink?.isPaused = false
      } else {
        DispatchQueue.main.async {
          self.pendingSample = next
          self.displayLink?.isPaused = false
        }
      }
    }
    emit(force: true)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    dispatchPrecondition(condition: .onQueue(.main))
    tearDown()
    return nil
  }

  @objc private func displayFrame() {
    let next = pendingSample
    let shouldUpdateGeometry = geometryDirty
    pendingSample = nil
    geometryDirty = false
    if let next { sample = next }
    guard next != nil || shouldUpdateGeometry else {
      displayLink?.isPaused = true
      return
    }
    emit(force: false)
    displayLink?.isPaused = true
  }

  private func scheduleGeometryUpdate() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.scheduleGeometryUpdate() }
      return
    }
    geometryDirty = true
    if let displayLink {
      displayLink.isPaused = false
    } else {
      emit(force: false)
    }
  }

  private func tearDown() {
    provider.stop()
    observerView?.onGeometryChange = nil
    observerView?.removeFromSuperview()
    observerView = nil
    displayLink?.invalidate()
    displayLink = nil
    pendingSample = nil
    geometryDirty = false
    sink = nil
    lastEvent = nil
  }

  private func emit(force: Bool) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.emit(force: force) }
      return
    }
    guard let sink else { return }
    let event = buildState() as NSDictionary
    guard force || lastEvent == nil || !event.isEqual(lastEvent) else { return }
    lastEvent = event
    sink(event)
  }

  private func buildState() -> [String: Any] {
    let hasHinge = sample.hasHinge || provider.isSupported
    let regions = reservedRegions()
    let role = screenRole(hasHinge: hasHinge, regions: regions)
    let mappedPosture = mapNativeHingePosture(sample.status)
    return [
      "schemaVersion": 1,
      "activeScreen": role.name,
      "isInnerScreen": role.isInner ?? NSNull(),
      "hingeAngle": sample.angle ?? NSNull(),
      "posture": mappedPosture,
      "postureSource": hasHinge ? "platform" : "unavailable",
      "displayFeatures": displayFeatures(from: regions),
      "reservedRegions": regions.map(regionDictionary),
      "supportedPostures": hasHinge ? ["flat", "halfOpened", "closed"] : [],
      "displayModes": [
        "rearDisplay": mode(state: "unsupported"),
        "dualScreen": mode(state: "unsupported"),
      ],
    ]
  }

  private func mode(state: String) -> [String: Any] {
    ["state": state, "isContentVisible": false, "errorCode": NSNull()]
  }

  private func reservedRegions() -> [ReservedRegionSample] {
    guard let hostView = viewController?.view, regionProvider.isSupported else { return [] }
    return regionProvider.regions(in: hostView)
  }

  private func screenRole(
    hasHinge: Bool,
    regions: [ReservedRegionSample]
  ) -> (name: String, isInner: Bool?) {
    if regions.contains(where: { $0.kind == "division" }) {
      return ("inner", true)
    }

    guard hasHinge || regionProvider.isSupported else { return ("unknown", nil) }

    let roleView = observerView ?? viewController?.viewIfLoaded
    if !regionProvider.isSupported {
      guard let roleView else { return ("unknown", nil) }
      let inner = roleView.traitCollection.horizontalSizeClass == .regular
      return (inner ? "inner" : "outer", inner)
    }

    guard
      let roleView,
      let window = roleView.window,
      let scene = window.windowScene
    else { return ("unknown", nil) }

    let windowSize = window.bounds.size
    let screenSize = scene.screen.coordinateSpace.bounds.size
    let isFullScreen = abs(windowSize.width - screenSize.width) < 0.5
      && abs(windowSize.height - screenSize.height) < 0.5
    guard isFullScreen else { return ("unknown", nil) }

    let traits = roleView.traitCollection
    if traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular {
      return ("inner", true)
    }
    if traits.horizontalSizeClass == .compact {
      return ("outer", false)
    }
    return ("unknown", nil)
  }

  private func displayFeatures(
    from regions: [ReservedRegionSample]
  ) -> [[String: Any]] {
    regions.compactMap { region in
      guard region.kind == "division", region.isActive else { return nil }
      let orientation = region.bounds.height >= region.bounds.width ? "vertical" : "horizontal"
      return [
        "bounds": boundsDictionary(region.bounds),
        "type": "fold",
        "orientation": orientation,
        "occlusion": "none",
        "isSeparating": true,
        "nativeState": sample.status,
      ]
    }
  }

  private func regionDictionary(_ region: ReservedRegionSample) -> [String: Any] {
    [
      "bounds": boundsDictionary(region.bounds),
      "kind": region.kind,
      "isActive": region.isActive,
    ]
  }

  private func boundsDictionary(_ bounds: CGRect) -> [String: Double] {
    [
      "left": bounds.minX,
      "top": bounds.minY,
      "right": bounds.maxX,
      "bottom": bounds.maxY,
    ]
  }
}

func mapNativeHingePosture(_ native: String) -> String {
  switch native.lowercased().replacingOccurrences(of: "_", with: "") {
  case "flat", "fullyopen": return "flat"
  case "halfopened", "partiallyopen": return "halfOpened"
  case "closed": return "closed"
  case "tent": return "tent"
  default: return "unknown"
  }
}
