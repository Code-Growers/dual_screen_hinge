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
- iOS hinge and inner/outer screen state.

The example app places both sources side by side so discrepancies are visible.
