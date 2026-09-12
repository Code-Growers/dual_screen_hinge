---
title: iPhone Duo APIs for Flutter
description: iPhone Duo-first hinge telemetry and reserved-region geometry, with cross-platform foldable support.
image: assets/logo.png
imageAlt: Abstract teal two-panel folding-device logo
---

`dual_screen_hinge` exposes iPhone Duo hinge telemetry, folding and camera
reserved regions, plus cross-platform foldable APIs.

<Info>
Use Flutter's responsive layout APIs first. Use this plugin for iPhone Duo
reserved regions and animation angles, richer fold metadata, and Android
display modes.
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
- iPhone Duo uses `UIHingeInteraction`, reserved regions, and scene-aware
  runtime checks.
- Unknown data stays nullable; future native enum values decode safely.
- No device allowlists, OEM reflection, or private APIs.

Continue with [Getting started](guides/getting-started) or inspect the
[community device matrix](guides/device-matrix).
