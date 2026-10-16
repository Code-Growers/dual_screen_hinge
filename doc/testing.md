# Testing

Unit tests use mock channels and providers. They do not replace hardware tests.

```sh
flutter test
(cd example && flutter test)
ruby test/ios/sdk_api_detection_test.rb
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Native Swift tests run from the example workspace after a Swift Package
Manager build, with the Flutter framework on the search path:

```sh
(cd example && flutter config --enable-swift-package-manager && flutter build ios --simulator --debug --no-codesign)
FLUTTER_SIM="$(dirname "$(which flutter)")/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator"
(cd example/ios && xcodebuild test -workspace Runner.xcworkspace \
  -scheme dual_screen_hingeTests -destination 'platform=iOS Simulator,name=iPhone Duo' \
  FRAMEWORK_SEARCH_PATHS="$FLUTTER_SIM" LD_RUNPATH_SEARCH_PATHS="\$(inherited) $FLUTTER_SIM")
```

`RunnerTests` run with `-scheme Runner`. `xcodebuild test` boots its own
simulator instance in the closed pose, so pose-dependent checks belong in the
end-to-end test driven through Device Hub. The iOS 27.1 simulator has no front
camera; the inner-camera check skips there and runs on hardware. The example's end-to-end test drives
the dashboard against the live native stream; on an iPhone Duo, require the
iOS 27.1 checks instead of skipping them:

```sh
(cd example && flutter test integration_test -d "iPhone Duo" --dart-define=EXPECT_IPHONE_DUO=true)
```
 Xcode 27.1 requires a deployment
target of iOS 15 or later for apps; the plugin itself still compiles for iOS 13.

Use an Android foldable emulator to exercise folds and Window Area sessions.
Test a physical book-style fold, flip, and dual-panel device before release.
With a UIKit SDK that declares `UIHingeInteraction`, run the iOS hinge tests.
With an SDK that also declares `reservedRegions` and Device Hub, exercise
outer and inner displays; compact and regular layouts; closed, partially-open,
and fully-open transitions; both orientations; Split View; resizing; and inner
camera activation.

Release remains blocked until angle direction/endpoints, reserved-region
geometry and activity, conservative screen roles, session cancellation,
backgrounding, and system-ended cleanup pass on representative physical devices.
