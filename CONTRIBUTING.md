# Contributing

Use Flutter 3.38 or newer, JDK 17, Android SDK 36, and Xcode 27 for the full
iOS suite. Fork the repository, create a focused branch, and include tests for
behavior changes.

Before opening a pull request, run:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
(cd example && flutter test)
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Public payload additions must be backwards compatible with schema v1. Do not
add model allowlists, hidden/reflected OEM APIs, or private Apple APIs. New
experimental AndroidX calls must remain behind capability and error checks.

Hardware reports are welcome through the device-matrix issue template. Never
include device identifiers, logs containing app data, or proprietary SDK files.
