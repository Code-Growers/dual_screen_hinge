---
title: Troubleshooting
description: Diagnose null angles, unsupported modes, and iOS build issues.
---

## The angle is null

This is valid. Check `hingeAngleSensor`; many devices expose layout features
without a continuous sensor. Ensure the activity is started and the event
stream has a listener.

## A display mode is unavailable

Open the device, foreground the app, and query capabilities again. Availability
is dynamic. `unsupported` means the required standard API is absent;
`unavailable` means support exists but cannot start now.

## iPhone Duo reports unsupported

Use an Xcode 27 SDK build for hinge telemetry or Xcode 27.1 for reserved
regions, run on iPhone Duo/simulator, and ensure the Flutter view is attached.
Size class alone never opts a device into hinge support.
