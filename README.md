![dual_screen_hinge geometric folding-device logo](https://raw.githubusercontent.com/Code-Growers/dual_screen_hinge/main/assets/brand/dual_screen_hinge_192.png)

# dual_screen_hinge

iPhone Duo-first foldable support for Flutter: continuous hinge angles,
posture, reserved regions, screen role, and Android display modes.

[![pub package](https://img.shields.io/pub/v/dual_screen_hinge.svg)](https://pub.dev/packages/dual_screen_hinge)
[![CI](https://github.com/Code-Growers/dual_screen_hinge/actions/workflows/ci.yml/badge.svg)](https://github.com/Code-Growers/dual_screen_hinge/actions/workflows/ci.yml)

## Use it alongside MediaQuery

On Android, prefer `MediaQuery.displayFeatures` for adaptive layout and the
basic opened/half-opened state Flutter already exposes. Use this plugin when
you need continuous angles for animation, richer fold/hinge metadata,
supported postures, rear/dual-screen display sessions, or iOS support.

## Install

```yaml
dependencies:
  dual_screen_hinge: ^0.2.0
```

Requires Flutter 3.38+, Dart 3.10+, Android API 21+, or iOS 13+. iPhone Duo
hinge telemetry requires Xcode 27. Reserved-region geometry and full Duo
validation require Xcode 27.1. Older Xcode and iOS versions keep a safe,
unsupported fallback.

## Read state and animate

```dart
final subscription = DualScreenHinge.instance.events.listen((state) {
  print('${state.posture} ${state.hingeAngle}°');
});

StreamBuilder<double>(
  stream: DualScreenHinge.instance.hingeAngleEvents,
  builder: (context, snapshot) {
    final angle = snapshot.data ?? 180;
    return Transform.rotate(
      angle: (180 - angle) * math.pi / 180,
      child: const MyFoldEffect(),
    );
  },
);
```

The native event stream is shared by all Dart listeners, sends a snapshot on
listen, deduplicates state, and coalesces sensor updates to approximately one
per display frame.

## Read regions for custom layout

```dart
final state = await DualScreenHinge.instance.currentState();
final activeRegionBounds = state.reservedRegions
    .where((region) => region.isActive)
    .map((region) => region.bounds)
    .toList(growable: false);
```

On iOS 27.1, `reservedRegions` contains the folding region (`division`) and
camera regions (`occlusion`) in Flutter logical coordinates. Inactive regions
are included so a grid can, for example, prefer an even number of columns
before the fold becomes active. Active division regions are also exposed in
`displayFeatures` for cross-platform layout code.

Use `MediaQuery.sizeOf(context)`, `MediaQuery.paddingOf(context)`, and flexible
constraints for the overall layout. Use reserved regions only to displace
important custom-positioned elements using `activeRegionBounds`; don't drive
layout from the hinge angle or fixed iPhone Duo dimensions. See Apple's
[iPhone Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo).

## Display modes (Android)

```dart
final capabilities = await DualScreenHinge.instance.capabilities();

if (capabilities.rearDisplay) {
  await DualScreenHinge.instance.startRearDisplay();
}

if (capabilities.dualScreenPresentation) {
  await DualScreenHinge.instance.startDualScreen(
    entrypoint: 'dualScreenSecondaryMain',
    arguments: ['initial payload'],
  );
}

@pragma('vm:entry-point')
void dualScreenSecondaryMain(List<String> arguments) {
  runApp(SecondaryDisplayApp(arguments: arguments));
}
```

Only one display session can be pending or active. V1 deliberately supports
startup arguments, not a cross-engine message bus. On iOS, display-mode methods
return `DualScreenException(code: 'unsupported')` because there is no equivalent
app-controlled public session API.

## Platform behavior

| Capability | Android | iOS |
| --- | --- | --- |
| Continuous angle | API 30+ `TYPE_HINGE_ANGLE` when present | iOS 27 `UIHingeInteraction` on supported hardware |
| Fold geometry/posture | AndroidX WindowManager 1.5.1 | iOS 27 hinge status; iOS 27.1 reserved regions |
| Camera/fold avoidance | Flutter `MediaQuery.displayFeatures` | Division and occlusion reserved regions on iOS 27.1 |
| Inner/outer identity | Only while a Window Area session establishes it | Region and scene evidence; unknown when multitasking is ambiguous |
| Rear-display transfer | Experimental Window Area API | Unsupported |
| Dual-screen presentation | Experimental Window Area API + secondary Flutter engine | Unsupported |

No device allowlist, OEM reflection, or private API is used. Unsupported data
is nullable or reported through runtime capabilities.

Flutter-rendered toolbars don't automatically become UIKit's iPhone Duo
vertical bars. Keep controls inside each independent safe-area edge, preserve
their relative order across sizes, and let decorative backgrounds extend
edge-to-edge separately from interactive content.

## Documentation

See the [documentation site](https://code-growers.github.io/dual_screen_hinge/),
the complete [wire contract](doc/wire-contract.md), [device matrix](doc/device-matrix.md),
the [deployment guide](doc/deployment.md), and [testing guide](doc/testing.md).
The [`example/`](example/) app includes a
live fold animation and compares plugin output with `MediaQuery.displayFeatures`.

## License

MIT. See [LICENSE](LICENSE).
