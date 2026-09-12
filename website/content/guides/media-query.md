---
title: MediaQuery responsibilities
description: Decide what belongs to Flutter layout and what belongs to the plugin.
---

`MediaQuery.displayFeatures` already exposes Android fold/hinge geometry and
flat/half-opened state. It participates naturally in Flutter layout and should
remain your first choice for panes, avoidance, and responsive navigation.

Use `dual_screen_hinge` for:

- Continuous angle data.
- Orientation, occlusion, separation, and native state in one model.
- Runtime supported-posture capability.
- Rear-display and dual-screen sessions.
- iOS hinge, conservative inner/outer screen state, and iOS 27.1 folding and
  camera reserved regions.

On iPhone Duo, continue using `MediaQuery.sizeOf(context)`, flexible
constraints, and each individual edge from `MediaQuery.paddingOf(context)` for
the overall layout. Use `reservedRegions` only when important custom-positioned
content needs to avoid a folding or camera region. Active division regions are
also present in `displayFeatures` so shared Android/iOS layout code can consume
one model.

The example app places both sources side by side so discrepancies are visible.
