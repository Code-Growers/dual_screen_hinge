---
title: Getting started
description: Install the plugin, listen to snapshots, and check capabilities.
---

## Requirements

- Flutter 3.38+ and Dart 3.10+
- Android API 21+; hinge sensor requires API 30+ when hardware exposes it
- iOS 13+; iPhone Duo hinge telemetry requires Xcode 27 and reserved-region
  geometry requires Xcode 27.1

## Install

```yaml
dependencies:
  dual_screen_hinge: ^0.2.0
```

## Listen

```dart
final sub = DualScreenHinge.instance.events.listen((state) {
  final angle = state.hingeAngle;
  if (angle != null) debugPrint('Hinge angle: $angle');
});

final snapshot = await DualScreenHinge.instance.currentState();
final support = await DualScreenHinge.instance.capabilities();
final activeRegionBounds = snapshot.reservedRegions
    .where((region) => region.isActive)
    .map((region) => region.bounds)
    .toList(growable: false);
```

Cancel your subscription with the owning widget or controller. Native display
sessions are independent: stop them explicitly.
