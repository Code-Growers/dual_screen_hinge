---
title: Foldable APIs for Flutter
description: Continuous hinge angles, posture, feature geometry, and display modes on Android and iPhone Duo.
image: assets/logo.png
imageAlt: Abstract teal two-panel folding-device logo
---

`dual_screen_hinge` complements Flutter's adaptive layout APIs with continuous
fold telemetry and native display-mode controls.

<Info>
Use `MediaQuery.displayFeatures` for adaptive Android layout. Use this plugin
for animation angles, richer metadata, display modes, and iOS support.
</Info>

<HingeSimulator/>

## Start in three lines

```dart
DualScreenHinge.instance.events.listen((state) {
  print('${state.posture}: ${state.hingeAngle}°');
});
```

The stream is broadcast, immediately snapshots native state, deduplicates
unchanged payloads, and coalesces high-frequency angles to the display cadence.

## Designed for capability differences

- Android fold, flip, trifold, and dual-panel devices use standard Android APIs.
- iPhone Duo uses `UIHingeInteraction` and size classes with runtime checks.
- Unknown data stays nullable; future native enum values decode safely.
- No device allowlists, OEM reflection, or private APIs.

Continue with [Getting started](guides/getting-started) or inspect the
[community device matrix](guides/device-matrix).
