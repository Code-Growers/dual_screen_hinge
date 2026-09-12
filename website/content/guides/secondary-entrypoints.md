---
title: Secondary entrypoints
description: Run Flutter content in an Android dual-screen presentation.
---

```dart
@pragma('vm:entry-point')
void dualScreenSecondaryMain(List<String> arguments) {
  runApp(SecondaryDisplayApp(arguments: arguments));
}

await DualScreenHinge.instance.startDualScreen(
  entrypoint: 'dualScreenSecondaryMain',
  arguments: ['initial payload'],
);
```

The annotation prevents tree shaking. Entrypoints must be top-level Dart
identifiers. The plugin lazily creates a secondary `FlutterEngine`, attaches a
`FlutterView` to the Window Area presenter, and destroys both on session end.
V1 has no cross-engine message bus; startup arguments are the handoff.
