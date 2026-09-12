# Testing

Unit tests use mock channels and providers. They do not replace hardware tests.

```sh
flutter test
(cd example && flutter test)
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Use an Android foldable emulator to exercise folds and Window Area sessions.
Test a physical book-style fold, flip, and dual-panel device before release.
With Xcode 27, run the iOS package tests and the iPhone Duo simulator through
compact, regular, closed, partially-open, fully-open, and tent transitions.

Release remains blocked until angle direction/endpoints, session cancellation,
backgrounding, and system-ended cleanup pass on representative physical devices.
