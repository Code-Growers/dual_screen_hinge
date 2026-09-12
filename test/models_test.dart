import 'dart:ui';

import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes schema v1 and accepts any numeric angle', () {
    final state = DualScreenState.fromMap(<Object?, Object?>{
      'schemaVersion': 1,
      'activeScreen': 'inner',
      'isInnerScreen': true,
      'hingeAngle': 92,
      'posture': 'halfOpened',
      'postureSource': 'platform',
      'displayFeatures': <Object?>[
        <Object?, Object?>{
          'bounds': <Object?, Object?>{
            'left': 400,
            'top': 0,
            'right': 424.5,
            'bottom': 900,
          },
          'type': 'hinge',
          'orientation': 'vertical',
          'occlusion': 'full',
          'isSeparating': true,
          'nativeState': 'HALF_OPENED',
        },
      ],
      'reservedRegions': <Object?>[
        <Object?, Object?>{
          'bounds': <Object?, Object?>{
            'left': 410,
            'top': 0,
            'right': 414,
            'bottom': 900,
          },
          'kind': 'division',
          'isActive': true,
        },
        <Object?, Object?>{
          'bounds': <Object?, Object?>{
            'left': 760,
            'top': 0,
            'right': 824,
            'bottom': 48,
          },
          'kind': 'occlusion',
          'isActive': false,
        },
      ],
      'supportedPostures': <Object?>['tabletop'],
      'displayModes': <Object?, Object?>{
        'rearDisplay': <Object?, Object?>{'state': 'available'},
        'dualScreen': <Object?, Object?>{
          'state': 'active',
          'isContentVisible': true,
        },
      },
    });

    expect(state.activeScreen, ActiveScreen.inner);
    expect(state.hingeAngle, 92.0);
    expect(state.posture, HingePosture.halfOpened);
    expect(
      state.displayFeatures.single.bounds,
      const Rect.fromLTRB(400, 0, 424.5, 900),
    );
    expect(state.displayFeatures.single.type, FoldFeatureType.hinge);
    expect(state.reservedRegions, hasLength(2));
    expect(
      state.reservedRegions.first,
      const ReservedRegion(
        bounds: Rect.fromLTRB(410, 0, 414, 900),
        kind: ReservedRegionKind.division,
        isActive: true,
      ),
    );
    expect(state.reservedRegions.last.kind, ReservedRegionKind.occlusion);
    expect(state.reservedRegions.last.isActive, isFalse);
    expect(state.dualScreen.state, DisplayModeState.active);
    expect(state.dualScreen.isContentVisible, isTrue);
  });

  test('maps future enum values and malformed fields to safe defaults', () {
    final state = DualScreenState.fromMap(<Object?, Object?>{
      'activeScreen': 'futureScreen',
      'hingeAngle': 'ninety',
      'posture': 'rolled',
      'displayFeatures': <Object?>[
        <Object?, Object?>{'type': 'crease'},
      ],
      'reservedRegions': <Object?>[
        <Object?, Object?>{
          'bounds': 'not-a-map',
          'kind': 'futureRegion',
          'isActive': 'yes',
        },
      ],
    });

    expect(state.activeScreen, ActiveScreen.unknown);
    expect(state.hingeAngle, isNull);
    expect(state.posture, HingePosture.unknown);
    expect(state.displayFeatures.single.type, FoldFeatureType.unknown);
    expect(state.reservedRegions.single.kind, ReservedRegionKind.unknown);
    expect(state.reservedRegions.single.bounds, Rect.zero);
    expect(state.reservedRegions.single.isActive, isFalse);
  });

  test('value equality supports event deduplication', () {
    const first = DualScreenState(
      hingeAngle: 180,
      posture: HingePosture.flat,
      reservedRegions: <ReservedRegion>[
        ReservedRegion(
          bounds: Rect.fromLTRB(200, 0, 204, 600),
          kind: ReservedRegionKind.division,
          isActive: true,
        ),
      ],
      supportedPostures: <String>['tabletop'],
    );
    const second = DualScreenState(
      hingeAngle: 180,
      posture: HingePosture.flat,
      reservedRegions: <ReservedRegion>[
        ReservedRegion(
          bounds: Rect.fromLTRB(200, 0, 204, 600),
          kind: ReservedRegionKind.division,
          isActive: true,
        ),
      ],
      supportedPostures: <String>['tabletop'],
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('capabilities remain false when nullable native values are absent', () {
    final capabilities = DualScreenCapabilities.fromMap(
      const <Object?, Object?>{},
    );
    expect(capabilities.platformSupported, isFalse);
    expect(capabilities.hingeAngleSensor, isFalse);
    expect(capabilities.layoutFeatures, isFalse);
    expect(capabilities.reservedRegionGeometry, isFalse);
  });

  test('missing reserved-region payload remains backwards compatible', () {
    final state = DualScreenState.fromMap(const <Object?, Object?>{});
    expect(state.reservedRegions, isEmpty);
  });
}
