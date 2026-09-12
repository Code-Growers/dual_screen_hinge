# Testing

Unit tests use mock channels and providers. They do not replace hardware tests.

```sh
flutter test
(cd example && flutter test)
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Use an Android foldable emulator to exercise folds and Window Area sessions.
Test a physical book-style fold, flip, and dual-panel device before release.
With Xcode 27, run the iOS hinge tests. With Xcode 27.1 and Device Hub, exercise
outer and inner displays; compact and regular layouts; closed, partially-open,
and fully-open transitions; both orientations; Split View; resizing; and inner
camera activation.

Release remains blocked until angle direction/endpoints, reserved-region
geometry and activity, conservative screen roles, session cancellation,
backgrounding, and system-ended cleanup pass on representative physical devices.
