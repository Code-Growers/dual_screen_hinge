import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:dual_screen_hinge_example/src/app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pass `--dart-define=EXPECT_IPHONE_DUO=true` on an iPhone Duo (simulator or
/// hardware) so missing iOS 27.1 support fails instead of being skipped.
const expectIPhoneDuo = bool.fromEnvironment('EXPECT_IPHONE_DUO');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every device returns a safe snapshot', (tester) async {
    final state = await DualScreenHinge.instance.currentState();
    final capabilities = await DualScreenHinge.instance.capabilities();
    expect(state.schemaVersion, 1);
    expect(capabilities.platformSupported, isA<bool>());
  });

  testWidgets('iPhone Duo streams platform hinge and reserved-region state', (
    tester,
  ) async {
    final initial = await DualScreenHinge.instance.capabilities();
    if (!initial.reservedRegionGeometry) {
      expect(expectIPhoneDuo, isFalse, reason: 'iOS 27.1 support missing');
      markTestSkipped('Not an iPhone Duo with iOS 27.1 support.');
      return;
    }

    // The example app is the stream listener, exactly as in production.
    await tester.pumpWidget(const HingeExampleApp());
    final state = await _firstPlatformState(tester);

    final capabilities = await DualScreenHinge.instance.capabilities();
    expect(capabilities.platformSupported, isTrue);
    expect(capabilities.layoutFeatures, isTrue);
    expect(capabilities.hingeAngleSensor, isTrue);

    expect(state.posture, isNot(HingePosture.unknown));
    expect(state.hingeAngle, isNotNull);
    expect(state.hingeAngle, inInclusiveRange(0, 180));
    if (state.posture == HingePosture.closed) {
      expect(state.hingeAngle, lessThan(30));
    }
    if (state.posture == HingePosture.flat) {
      expect(state.hingeAngle, greaterThan(150));
    }

    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    final viewport = Offset.zero & view;
    for (final region in state.reservedRegions) {
      expect(region.kind, isNot(ReservedRegionKind.unknown));
      expect(region.bounds.isEmpty, isFalse, reason: '$region');
      expect(
        viewport.inflate(0.5).contains(region.bounds.topLeft) &&
            viewport.inflate(0.5).contains(region.bounds.bottomRight),
        isTrue,
        reason: '$region outside $viewport',
      );
    }

    final activeDivisions = state.reservedRegions
        .where((r) => r.kind == ReservedRegionKind.division && r.isActive)
        .map((r) => r.bounds)
        .toList();
    expect(
      state.displayFeatures.map((f) => f.bounds).toList(),
      unorderedEquals(activeDivisions),
    );
    for (final feature in state.displayFeatures) {
      expect(feature.type, FoldFeatureType.fold);
      expect(feature.isSeparating, isTrue);
    }

    final hasDivision = state.reservedRegions.any(
      (r) => r.kind == ReservedRegionKind.division,
    );
    if (hasDivision) {
      expect(state.activeScreen, ActiveScreen.inner);
    }
    switch (state.activeScreen) {
      case ActiveScreen.inner:
        expect(state.isInnerScreen, isTrue);
      case ActiveScreen.outer:
        expect(state.isInnerScreen, isFalse);
        expect(hasDivision, isFalse);
      case ActiveScreen.unknown:
        expect(state.isInnerScreen, isNull);
    }

    // The example renders the live stream.
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('source · platform'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('source · platform'), findsOneWidget);

    debugPrint(
      'iPhone Duo e2e: posture=${state.posture.name} '
      'angle=${state.hingeAngle} screen=${state.activeScreen.name} '
      'regions=${state.reservedRegions.map((r) => '${r.kind.name}:'
          '${r.isActive ? 'active' : 'inactive'}:${r.bounds}').toList()} '
      'features=${state.displayFeatures.length}',
    );
  });

  testWidgets('iPhone Duo inner camera toggles its reserved region', (
    tester,
  ) async {
    final capabilities = await DualScreenHinge.instance.capabilities();
    if (!capabilities.reservedRegionGeometry) {
      markTestSkipped('Not an iPhone Duo with iOS 27.1 support.');
      return;
    }
    await tester.pumpWidget(const HingeExampleApp());
    final state = await _firstPlatformState(tester);
    if (state.activeScreen != ActiveScreen.inner) {
      markTestSkipped('Inner camera applies to the inner display only.');
      return;
    }
    final camera = state.reservedRegions
        .where((r) => r.kind == ReservedRegionKind.occlusion && !r.isActive)
        .toList();
    expect(camera, isNotEmpty, reason: 'No idle inner camera region');

    const probe = MethodChannel('dual_screen_hinge_example/camera_probe');
    final status = await probe
        .invokeMethod<String>('start')
        .timeout(const Duration(seconds: 15), onTimeout: () => 'timedOut');
    if (status == 'noFrontCamera') {
      markTestSkipped('This device exposes no front camera.');
      return;
    }
    expect(status, 'running', reason: 'Camera probe could not start');
    try {
      final active = await _waitForRegion(tester, camera.first.bounds, true);
      expect(active, isTrue, reason: 'Camera region never became active');
    } finally {
      await probe.invokeMethod<void>('stop');
    }
    final idle = await _waitForRegion(tester, camera.first.bounds, false);
    expect(idle, isTrue, reason: 'Camera region never became inactive');
  });
}

Future<bool> _waitForRegion(
  WidgetTester tester,
  Rect bounds,
  bool active,
) async {
  var matched = false;
  final subscription = DualScreenHinge.instance.events.listen((state) {
    matched = state.reservedRegions.any(
      (r) => r.bounds == bounds && r.isActive == active,
    );
  });
  try {
    for (var i = 0; i < 100 && !matched; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return matched;
  } finally {
    await subscription.cancel();
  }
}

Future<DualScreenState> _firstPlatformState(WidgetTester tester) async {
  final seen = <String>[];
  DualScreenState? settled;
  final subscription = DualScreenHinge.instance.events.listen((state) {
    seen.add(
      '${state.postureSource}/${state.posture.name}/${state.hingeAngle}/'
      '${state.activeScreen.name}',
    );
    if (state.postureSource == 'platform' &&
        state.posture != HingePosture.unknown) {
      settled ??= state;
    }
  });
  try {
    for (var i = 0; i < 100 && settled == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    debugPrint('iPhone Duo e2e states: $seen');
    // A platform posture source must always carry the sample that proved it.
    expect(
      seen.where((s) => s.startsWith('platform/') && s.contains('/null/')),
      isEmpty,
      reason: 'Platform state without a hinge sample: $seen',
    );
    expect(
      settled,
      isNotNull,
      reason: 'No settled platform hinge state within 10 seconds: $seen',
    );
    return settled!;
  } finally {
    await subscription.cancel();
  }
}
