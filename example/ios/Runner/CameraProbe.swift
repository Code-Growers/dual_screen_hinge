import AVFoundation
import Flutter

/// Lets the end-to-end test turn the front (inner) camera on and off so it can
/// verify that iPhone Duo camera reserved regions change activity.
final class CameraProbe {
  private let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "camera-probe")

  static func register(with registrar: FlutterPluginRegistrar) {
    let probe = CameraProbe()
    let channel = FlutterMethodChannel(
      name: "dual_screen_hinge_example/camera_probe",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "start": probe.start(result)
      case "stop": probe.stop(result)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Reports "running", or why the camera could not start. Checks for a front
  /// camera before asking for access so simulators never show a prompt.
  private func start(_ result: @escaping FlutterResult) {
    guard let device = AVCaptureDevice.default(
      .builtInWideAngleCamera, for: .video, position: .front
    ) else {
      result("noFrontCamera")
      return
    }
    AVCaptureDevice.requestAccess(for: .video) { granted in
      self.queue.async {
        let status: String
        if !granted {
          status = "denied"
        } else if let input = try? AVCaptureDeviceInput(device: device) {
          if self.session.inputs.isEmpty, self.session.canAddInput(input) {
            self.session.addInput(input)
          }
          self.session.startRunning()
          status = self.session.isRunning ? "running" : "notRunning"
        } else {
          status = "inputUnavailable"
        }
        DispatchQueue.main.async { result(status) }
      }
    }
  }

  private func stop(_ result: @escaping FlutterResult) {
    queue.async {
      self.session.stopRunning()
      DispatchQueue.main.async { result(nil) }
    }
  }
}
