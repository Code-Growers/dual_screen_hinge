import Flutter
import UIKit

private let methodChannelName = "com.example.iphone_duo_hinge/methods"
private let eventChannelName = "com.example.iphone_duo_hinge/events"

public final class DualScreenHingePlugin: NSObject, FlutterPlugin {
  private let streamHandler: DualScreenStreamHandler

  init(viewController: UIViewController?, provider: HingeProviding = HingeProviderFactory.make()) {
    streamHandler = DualScreenStreamHandler(viewController: viewController, provider: provider)
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

enum HingeProviderFactory {
  static func make() -> HingeProviding {
    #if DUAL_SCREEN_HINGE_IOS27
    if #available(iOS 27.0, *) { return IOS27HingeProvider() }
    #endif
    return UnsupportedHingeProvider()
  }
}

private final class TraitObserverView: UIView {
  var onTraitChange: (() -> Void)?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else {
      return
    }
    onTraitChange?()
  }
}

final class DualScreenStreamHandler: NSObject, FlutterStreamHandler {
  private weak var viewController: UIViewController?
  private let provider: HingeProviding
  private var observerView: TraitObserverView?
  private var sink: FlutterEventSink?
  private var pendingSample: HingeSample?
  private var displayLink: CADisplayLink?
  private var lastEvent: NSDictionary?
  private var sample = HingeSample(angle: nil, status: "unknown", hasHinge: false)

  init(viewController: UIViewController?, provider: HingeProviding) {
    self.viewController = viewController
    self.provider = provider
  }

  var capabilities: [String: Any] {
    let supported = sample.hasHinge || provider.isSupported
    return [
      "platformSupported": supported,
      "hingeAngleSensor": supported,
      "layoutFeatures": supported,
      "rearDisplay": false,
      "dualScreenPresentation": false,
    ]
  }

  var currentState: [String: Any] { buildState() }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    dispatchPrecondition(condition: .onQueue(.main))
    tearDown()
    sink = events

    let observer = TraitObserverView(frame: .zero)
    observer.backgroundColor = .clear
    observer.isUserInteractionEnabled = true
    observer.accessibilityElementsHidden = true
    observer.onTraitChange = { [weak self] in self?.emit(force: false) }
    observerView = observer
    viewController?.view.addSubview(observer)

    let link = CADisplayLink(target: self, selector: #selector(displayFrame))
    link.isPaused = true
    link.add(to: .main, forMode: .common)
    displayLink = link

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
    guard let next = pendingSample else { return }
    pendingSample = nil
    sample = next
    emit(force: false)
    displayLink?.isPaused = true
  }

  private func tearDown() {
    provider.stop()
    observerView?.onTraitChange = nil
    observerView?.removeFromSuperview()
    observerView = nil
    displayLink?.invalidate()
    displayLink = nil
    pendingSample = nil
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
    let inner = hasHinge && observerView?.traitCollection.horizontalSizeClass == .regular
    let screen = hasHinge ? (inner ? "inner" : "outer") : "unknown"
    let mappedPosture = mapNativeHingePosture(sample.status)
    return [
      "schemaVersion": 1,
      "activeScreen": screen,
      "isInnerScreen": inner,
      "hingeAngle": sample.angle ?? NSNull(),
      "posture": mappedPosture,
      "postureSource": hasHinge ? "platform" : "unavailable",
      "displayFeatures": [],
      "supportedPostures": hasHinge ? ["flat", "halfOpened", "closed", "tent"] : [],
      "displayModes": [
        "rearDisplay": mode(state: "unsupported"),
        "dualScreen": mode(state: "unsupported"),
      ],
    ]
  }

  private func mode(state: String) -> [String: Any] {
    ["state": state, "isContentVisible": false, "errorCode": NSNull()]
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
