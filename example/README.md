# dual_screen_hinge example

Run the mobile example to inspect live hinge telemetry, feature geometry,
capabilities, and Android display-mode sessions:

```sh
flutter run
```

The dashboard includes an angle-driven fold animation, a reserved-region
overlay with activity and bounds diagnostics, and
`MediaQuery.displayFeatures` beside the richer plugin state. Rear-display and
dual-screen buttons enable themselves only when the native capability is
available.

The secondary Android display starts the annotated
`dualScreenSecondaryMain(List<String>)` entrypoint in `lib/main.dart`. iPhone
Duo hinge telemetry requires Xcode 27, reserved regions require Xcode 27.1,
and both require supported hardware; ordinary iOS
devices return the safe unsupported snapshot.
