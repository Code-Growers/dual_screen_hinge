---
title: iPhone Duo
description: Hinge telemetry, reserved regions, adaptive layout, and build requirements.
---

Compile with Xcode 27 for hinge telemetry and Xcode 27.1 for reserved-region
geometry. The package remains safe on iOS 13–26 and older SDK builds through
availability checks and unsupported providers.

`UIHingeInteraction` supplies continuous angle and status. Apple reports
closed, partially open, and fully open, which map to `closed`, `halfOpened`,
and `flat`. Hinge angle is intended for effects and interactions, not for
placing content around the fold.

## Reserved regions

On iOS 27.1, `DualScreenState.reservedRegions` exposes the regions returned by
UIKit in Flutter logical coordinates:

- `division` is the folding region. It is active while the inner display is
  folded and can be present with zero width while inactive.
- `occlusion` represents an outer or inner camera region. The inner camera
  region becomes active with the camera.

```dart
final state = await DualScreenHinge.instance.currentState();
final activeRegions = state.reservedRegions
    .where((region) => region.isActive);
```

Active division regions are also mapped to `displayFeatures` as separating,
non-occluding folds. This lets shared layout code consume a cross-platform
shape while iOS-specific code retains camera and inactive-region details.

## Adapt the layout, not the app

Use `MediaQuery.sizeOf(context)` and flexible constraints instead of fixed
display sizes or orientation checks. Read all four edges from
`MediaQuery.paddingOf(context)` independently because safe areas can be
asymmetric, especially with side controls and Split View.

Keep functionality, navigation hierarchy, and action placement consistent as
the app resizes. A larger regular layout can reveal another level of hierarchy,
but folding the device shouldn't make controls disappear or move dramatically.

Use reserved regions for high-priority manually positioned elements:

- Keep buttons, media controls, and other interactive content clear of an
  active division.
- Prefer an even number of grid columns when an inactive division region shows
  that content may later split across the fold.
- Don't displace continuously scrolling articles, lists, or feeds merely to
  avoid the fold.
- Let decorative backgrounds extend edge-to-edge while keeping interactive
  foreground content inside safe areas.

Flutter renders its own Material and Cupertino bars, so they don't
automatically adopt UIKit's iPhone Duo vertical-bar representation. Keep symbol
and title semantics available, preserve the relative order of actions, and
ensure custom bars respect the safe area on the edge where they appear.

## Screen role

`activeScreen` is deliberately conservative. A division region proves that the
view is on the inner display. Full-screen scene geometry and size classes can
identify other common cases. In Split View or another ambiguous configuration,
the plugin returns `unknown` and a null `isInnerScreen` rather than guessing.
Use available size and safe-area data—not screen role—to choose a layout.

See Apple's [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
and [adaptive layout talk](https://developer.apple.com/videos/play/tech-talks/111463/).
