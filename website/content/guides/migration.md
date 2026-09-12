---
title: Migrate from dual_screen
description: Move from Microsoft's Android-only layout helpers to cross-platform telemetry.
---

Keep Flutter `MediaQuery.displayFeatures` as the replacement for layout helpers
such as hinge-aware pane placement. Add `DualScreenHinge.instance.events` only
where continuous angle, detailed feature metadata, active screen, or display
sessions are needed.

Unknowns are intentional: Android cannot generally prove inner/outer screen
identity, and not every foldable has an angle sensor. Branch on capabilities,
not brand or model strings.

This project takes API inspiration but contains no source code from
Microsoft's `dual_screen` package.
