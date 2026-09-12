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
    });

    expect(state.activeScreen, ActiveScreen.unknown);
    expect(state.hingeAngle, isNull);
    expect(state.posture, HingePosture.unknown);
    expect(state.displayFeatures.single.type, FoldFeatureType.unknown);
  });

  test('value equality supports event deduplication', () {
    const first = DualScreenState(
      hingeAngle: 180,
      posture: HingePosture.flat,
      supportedPostures: <String>['tabletop'],
    );
    const second = DualScreenState(
      hingeAngle: 180,
      posture: HingePosture.flat,
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
  });
}
