# Community device matrix

The plugin detects APIs, never model names. This matrix records observed
capabilities and is not an allowlist.

| Device/family | Layout features | Angle | Rear transfer | Presentation | Verified |
| --- | --- | --- | --- | --- | --- |
| Ordinary Android API 21+ | Safe unsupported state | — | — | — | CI mock |
| Pixel Fold family | Expected | Device/OS dependent | Selected models | Selected models | Hardware needed |
| Galaxy Fold/Flip family | Expected | Device/OS dependent | Device dependent | Device dependent | Hardware needed |
| Surface Duo family | Expected | Device/OS dependent | — | Device dependent | Hardware needed |
| Android foldable emulator | Expected | Emulator dependent | Emulator dependent | Emulator dependent | Manual gate |
| Ordinary iPhone/iPad, iOS 13–27 | Safe unsupported state | — | — | — | Simulator |
| iPhone Duo, iOS 27.1 | Expected, including reserved regions | Expected | — | — | Release hardware gate |

Submit a matrix report with OS build, Flutter version, returned capabilities,
and sanitized event payloads. Do not include serial numbers or account data.
