---
title: iPhone Duo
description: Build requirements, size-class behavior, and iOS hinge mapping.
---

Compile with Xcode 27. The package remains safe on iOS 13–26 through weak
availability checks and an unsupported provider.

The plugin attaches a zero-sized observer view to Flutter's view controller.
`UIHingeInteraction` supplies continuous angle and status. Only after a hinge
is confirmed does compact width map to `outer` and regular width to `inner`,
avoiding false positives on iPad and ordinary iPhone.

Apple's hinge statuses map to `closed`, `halfOpened`, and `flat`; `tent` is
preserved when supplied. Use adaptive layout APIs for layout and hinge data for
effects.
