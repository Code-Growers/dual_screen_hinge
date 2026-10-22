# Wire contract v1

The event channel is `tech.codegrower.iphone_duo_hinge/events`. The method
channel is `tech.codegrower.iphone_duo_hinge/methods`. Both use Flutter's
`StandardMessageCodec`.

Every event and `currentState` response is a dictionary with:

- `schemaVersion`: `1`
- `activeScreen`: `unknown`, `outer`, or `inner`
- `isInnerScreen`: Boolean on iOS; null on Android unless future APIs can prove it
- `windowPlacement` (optional, iOS only): `unknown`, `full`, `left`, or `right`.
  Says which horizontal screen edges the window touches, in the screen's
  interface-oriented coordinates. `full` spans the screen width; `left` and
  `right` touch one edge, as in Split View; `unknown` touches neither or has
  no window yet
- `verticalBarEdge` (optional, iOS only): `unknown`, `none`, `left`, or `right`.
  The physical edge where the system places its vertical bar, from UIKit's
  `UITraitCollection.verticalBarEdge` resolved with the layout direction.
  `none` means the system uses no vertical bar in this context; `unknown`
  means the SDK, OS, or view can't report it
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

Android omits `windowPlacement` and `verticalBarEdge`; readers decode a missing
key as `unknown`.

Readers must ignore unknown keys and map unknown enum strings to `unknown`.
Native writers may add optional keys without incrementing `schemaVersion`.

The `capabilities` response includes `reservedRegionGeometry`. It is true when
the current iOS runtime and SDK-compiled adapter can query native reserved
regions. An empty `reservedRegions` list means the current display has no
regions to report; it does not make the capability false.
