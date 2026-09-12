---
title: Animation recipes
description: Turn continuous hinge angles into smooth Flutter effects.
---

Use `hingeAngleEvents` when only the raw number matters:

```dart
StreamBuilder<double>(
  stream: DualScreenHinge.instance.hingeAngleEvents,
  builder: (context, snapshot) {
    final t = ((snapshot.data ?? 180) / 180).clamp(0.0, 1.0);
    return Opacity(opacity: Curves.easeOut.transform(t), child: content);
  },
);
```

Do not use an angle to manually lay out around a fold. Use MediaQuery on
Android and the platform's adaptive layout/reserved-region behavior on iOS.
Angles are ideal for parallax, light, camera, game, and media effects.
