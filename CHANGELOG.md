## 1.1.0

- Add `DualScreenState.verticalBarEdge` (`VerticalBarEdge`): the physical edge where iOS 27.1 places its vertical bar, from `UITraitCollection.verticalBarEdge`, so custom Flutter controls can follow it on iPhone Duo, including the outer edge in Split View.
- Add `DualScreenState.windowPlacement` (`WindowPlacement`): whether the iOS window spans the screen width or sits on the left or right, from the window frame in screen coordinates.
- Both are optional wire keys that Android omits and Dart decodes as `unknown`. Detect `verticalBarEdge` in the UIKit SDK for CocoaPods and Swift Package Manager, like the hinge and reserved-region APIs.
- Validated on the Xcode 27.1 iPhone Duo simulator in the closed pose: the end-to-end test reports `full` and `right`, and a right-to-left layout keeps the same physical edge. Split View placement is covered by native tests with left and right window frames.

## 1.0.2

- Rename the platform channels from `com.example.iphone_duo_hinge/*` to `tech.codegrower.iphone_duo_hinge/*`. Apps that use the plugin's Dart API need no changes; code that talks to the channels directly must use the new names.
- Stop shipping stray `*.log` files in the published package; `.pubignore` now also excludes `.DS_Store`, `local.properties`, and Swift build directories.

## 1.0.1

- Fix a race where iOS could report `postureSource: platform` with no hinge angle before UIKit's first hinge sample was delivered; state now derives from delivered samples only.
- Read reserved-region activity from `UIView.ReservedRegion.isActive` instead of matching frames between two queries.
- Validated on the Xcode 27.1 iPhone Duo simulator through Device Hub: closed, partially open, and open poses in all four orientations, with the end-to-end test checking posture, angle, screen identity, reserved regions, and display features.
- Add native coverage for conservative screen identity in partial (Split View or resized) windows, and an inner-camera end-to-end check that runs on hardware with a front camera.

## 1.0.0

- Fix iOS event streaming in UIScene apps (`FlutterImplicitEngineDelegate`): the plugin now resolves the Flutter view controller when it is available instead of capturing `nil` at registration, so hinge, reserved-region, and screen-role state reach Dart.
- Fix iOS builds with Xcode 27.1, where `UIHingeInteraction` and `UIHinge` require iOS 27.1.
- Document that iOS confirms hinge capability after the first hinge update; the example re-reads capabilities when the posture source changes.
- Add an iPhone Duo end-to-end test for the example app's live hinge, reserved-region, display-feature, and screen-identity state.
- Report iOS hinge angles in degrees (UIKit reports radians) and map `UIHinge.Status` values explicitly.
- Apply the detected UIKit API defines to the Swift package test target.
- Build and test with Flutter 3.47.6 and Dart 3.13.5; the example app targets iOS 15, the minimum Xcode 27.1 accepts. The plugin still supports iOS 13.

## 0.2.1

- Fix iOS builds with Xcode 27.0 SDKs that do not declare `UIHingeInteraction`.
- Detect hinge and reserved-region APIs in public UIKit headers and Swift interfaces for CocoaPods and Swift Package Manager instead of relying on toolchain version numbers.
- Check device and simulator SDKs independently in CocoaPods and keep the unsupported fallback when APIs are absent. Existing Podfile workarounds can be removed.

## 0.2.0

- Adds iOS 27.1 folding and camera reserved-region geometry with active-state metadata.
- Maps active iPhone Duo division regions into the cross-platform display-feature model.
- Makes iOS screen-role inference conservative in Split View and other ambiguous layouts.
- Positions the package as iPhone Duo-first on pub.dev with the `iphone-duo` topic and a feature screenshot.
- Expands the iPhone Duo example, documentation, compatibility guidance, and test coverage.

## 0.1.1

- Fix the README logo rendering on pub.dev.

## 0.1.0

- Adds the schema-v1 shared event stream and immutable Dart state model.
- Adds continuous Android hinge-angle telemetry and AndroidX WindowManager fold metadata.
- Adds Android rear-display transfer and dual-screen presentation with a secondary Flutter engine.
- Adds iOS 27 hinge/status and compact/regular screen-role bridging with safe iOS 13–26 fallback.
- Adds CocoaPods and Swift Package Manager integration, a full example app, documentation site, tests, and CI.
