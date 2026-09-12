---
title: Android capabilities
description: Sensors, WindowManager metadata, and behavior across foldable families.
---

The Android implementation combines three documented sources:

1. `Sensor.TYPE_HINGE_ANGLE` on API 30+, only while a foreground activity and
   Dart listener both exist.
2. AndroidX WindowManager 1.5.1 `WindowLayoutInfo` and `FoldingFeature`.
3. Experimental Window Area capabilities for rear transfer and presentation.

Devices may expose any subset. A foldable without an angle sensor can still
report geometry and coarse posture. Android's active inner/outer identity stays
`unknown` unless an active Window Area session establishes a role.

Authoritative `FoldingFeature.State` wins. A near-zero angle becomes `closed`
only when no authoritative posture exists and is marked `derivedAngle`.
