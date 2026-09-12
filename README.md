![dual_screen_hinge geometric folding-device logo](https://raw.githubusercontent.com/Code-Growers/dual_screen_hinge/main/assets/brand/dual_screen_hinge_192.png)

# dual_screen_hinge

Day-one Flutter access to continuous hinge angles, posture, feature geometry,
screen role, and foldable display modes on Android and iOS.

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
  dual_screen_hinge: ^0.1.0
```

Requires Flutter 3.38+, Dart 3.10+, Android API 21+, or iOS 13+. iPhone Duo
hinge telemetry requires an app compiled with Xcode 27 and runs only when the
public iOS hinge API reports hardware support.

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
| Fold geometry/posture | AndroidX WindowManager 1.5.1 | Hinge posture and active screen |
| Inner/outer identity | Only while a Window Area session establishes it | Compact outer / regular inner after hinge capability is confirmed |
| Rear-display transfer | Experimental Window Area API | Unsupported |
| Dual-screen presentation | Experimental Window Area API + secondary Flutter engine | Unsupported |

No device allowlist, OEM reflection, or private API is used. Unsupported data
is nullable or reported through runtime capabilities.

## Documentation

See the [documentation site](https://code-growers.github.io/dual_screen_hinge/),
the complete [wire contract](doc/wire-contract.md), [device matrix](doc/device-matrix.md),
the [deployment guide](doc/deployment.md), and [testing guide](doc/testing.md).
The [`example/`](example/) app includes a
live fold animation and compares plugin output with `MediaQuery.displayFeatures`.

## License

MIT. See [LICENSE](LICENSE).
