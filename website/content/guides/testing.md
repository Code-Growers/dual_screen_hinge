---
title: Testing
description: Use mocks, emulators, and physical-device release gates.
---

```sh
flutter test
(cd example && flutter test)
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Run iOS provider tests with Xcode 27. Exercise an Android foldable emulator and
iPhone Duo simulator, then repeat angle endpoint, lifecycle, cancellation,
backgrounding, and display-session tests on representative physical hardware.
CI mocks do not replace that release gate.
