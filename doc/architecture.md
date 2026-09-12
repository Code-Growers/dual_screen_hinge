# Architecture

One unfederated platform interface owns the public contract. A shared broadcast
EventChannel stream carries immutable snapshots, while a MethodChannel handles
snapshots and explicit display-session controls.

Android combines `TYPE_HINGE_ANGLE`, AndroidX WindowManager layout information,
and experimental Window Area capability/session APIs. Sensor registration is
bound to foreground lifecycle plus Dart listenership. Display sessions are
bound to the owning Flutter engine rather than stream listeners.

iOS attaches a transparent, noninteractive observer view to the Flutter view
controller. A `HingeProviding` adapter owns `UIHingeInteraction`, while a
separately guarded `ReservedRegionProviding` adapter reads iOS 27.1 division
and camera regions. Region and window-scene evidence take precedence over size
classes for screen role; ambiguous multitasking layouts remain unknown. The
unsupported providers are used with older SDKs/runtimes and non-foldable
hardware.

## Source layout

| Area | Responsibility |
| --- | --- |
| `lib/dual_screen_hinge.dart` | Public package exports |
| `lib/src/` | Models, facade, injectable interface, and channel transport |
| `android/.../DualScreenHingePlugin.kt` | Flutter lifecycle, channels, and display sessions |
| `android/.../HingeAngleSensorController.kt` | Hinge sensor registration and frame coalescing |
| `android/.../WindowStateObserver.kt` | WindowManager layout and Window Area observation |
| `ios/.../DualScreenHingePlugin.swift` | Provider abstraction, event stream, and plugin registration |
| `example/lib/` | Entrypoints plus separated app, dashboard, and visualizer code |
