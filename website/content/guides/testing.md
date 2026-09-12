---
title: Testing
description: Use mocks, emulators, and physical-device release gates.
---

```sh
flutter test
(cd example && flutter test)
(cd example/android && ./gradlew :dual_screen_hinge:testDebugUnitTest)
```

Run hinge-provider tests with Xcode 27 and reserved-region tests with Xcode
27.1. In Device Hub, exercise the outer and inner displays, flat, closed, and
partially folded poses, both orientations, Split View, resizing, and inner-camera
activation. Verify ambiguous multitasking layouts report an unknown screen role
instead of an incorrect outer role.

Repeat angle endpoint, lifecycle, cancellation, backgrounding, region, and
display-session tests on representative physical hardware. CI mocks do not
replace that release gate.
