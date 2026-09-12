---
title: Display modes
description: Transfer an Android activity or present a secondary Flutter view.
---

Check capabilities immediately before showing controls because availability
changes with device posture, foreground state, thermal limits, and OS policy.

```dart
final caps = await DualScreenHinge.instance.capabilities();
if (caps.rearDisplay) await DualScreenHinge.instance.startRearDisplay();
```

Only one session may be active or pending. States progress through `starting`,
`active`, and `stopping`; OS termination can produce `error`. Transfer sessions
survive Android configuration changes but close with permanent activity/engine
detach. iOS controls return `unsupported`.
