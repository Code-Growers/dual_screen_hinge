# Wire contract v1

The event channel is `com.example.iphone_duo_hinge/events`. The method channel
is `com.example.iphone_duo_hinge/methods`. Both use Flutter's
`StandardMessageCodec`.

Every event and `currentState` response is a dictionary with:

- `schemaVersion`: `1`
- `activeScreen`: `unknown`, `outer`, or `inner`
- `isInnerScreen`: Boolean on iOS; null on Android unless future APIs can prove it
- `hingeAngle`: number or null
- `posture`: `unknown`, `closed`, `halfOpened`, `flat`, or `tent`
- `postureSource`: `platform`, `foldingFeature`, `derivedAngle`, or `unavailable`
- `displayFeatures`: dictionaries containing logical-pixel `bounds`, `type`,
  `orientation`, `occlusion`, `isSeparating`, and `nativeState`
- `reservedRegions`: dictionaries containing logical-pixel `bounds`, `kind`
  (`division`, `occlusion`, or `unknown`), and `isActive`; empty on platforms
  without reserved-region geometry
- `supportedPostures`: lowercase native capability names
- `displayModes`: `rearDisplay` and `dualScreen`, each containing `state`,
  `isContentVisible`, and nullable `errorCode`

Readers must ignore unknown keys and map unknown enum strings to `unknown`.
Native writers may add optional keys without incrementing `schemaVersion`.

The `capabilities` response includes `reservedRegionGeometry`. It is true when
the current iOS runtime and SDK-compiled adapter can query native reserved
regions. An empty `reservedRegions` list means the current display has no
regions to report; it does not make the capability false.
