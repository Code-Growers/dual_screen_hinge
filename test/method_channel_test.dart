import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:dual_screen_hinge/src/method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel(MethodChannelDualScreenHinge.methodChannelName);
  const events = EventChannel(MethodChannelDualScreenHinge.eventChannelName);
  late MethodChannelDualScreenHinge platform;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    platform = MethodChannelDualScreenHinge();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'currentState':
              return <String, Object?>{
                'hingeAngle': 45,
                'posture': 'halfOpened',
                'reservedRegions': <Object?>[
                  <Object?, Object?>{'kind': 'division', 'isActive': true},
                ],
              };
            case 'capabilities':
              return <String, Object?>{
                'hingeAngleSensor': true,
                'reservedRegionGeometry': true,
              };
            default:
              return null;
          }
        });
  });

  test('snapshots and controls use the documented method contract', () async {
    final state = await platform.currentState();
    expect(state.hingeAngle, 45);
    expect(state.reservedRegions.single.kind, ReservedRegionKind.division);
    final capabilities = await platform.capabilities();
    expect(capabilities.hingeAngleSensor, isTrue);
    expect(capabilities.reservedRegionGeometry, isTrue);
    await platform.startDualScreen(
      entrypoint: 'secondaryMain',
      arguments: const <String>['demo'],
    );

    expect(calls.map((call) => call.method), <String>[
      'currentState',
      'capabilities',
      'startDualScreen',
    ]);
    expect(calls.last.arguments, <String, Object>{
      'entrypoint': 'secondaryMain',
      'arguments': <String>['demo'],
    });
  });

  test('invalid entrypoint is rejected before reaching native code', () {
    expect(
      () => platform.startDualScreen(entrypoint: 'bad entrypoint'),
      throwsA(
        isA<DualScreenException>().having(
          (error) => error.code,
          'code',
          'invalidEntrypoint',
        ),
      ),
    );
  });

  test('platform errors become stable DualScreenException values', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          throw PlatformException(
            code: 'unavailable',
            message: 'Fold the device open.',
          );
        });

    await expectLater(
      platform.startRearDisplay(),
      throwsA(
        isA<DualScreenException>().having(
          (error) => error.code,
          'code',
          'unavailable',
        ),
      ),
    );
  });

  test('one broadcast stream decodes and deduplicates state', () async {
    var listenCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          events,
          MockStreamHandler.inline(
            onListen: (_, sink) {
              listenCount += 1;
              sink.success(<String, Object?>{'hingeAngle': 10});
              sink.success(<String, Object?>{'hingeAngle': 10});
              sink.success(<String, Object?>{'hingeAngle': 20});
            },
          ),
        );

    final first = platform.events
        .map((state) => state.hingeAngle)
        .take(2)
        .toList();
    final second = platform.events
        .map((state) => state.hingeAngle)
        .take(2)
        .toList();
    expect(await first, <double?>[10, 20]);
    expect(await second, <double?>[10, 20]);
    expect(listenCount, 1);
  });
}
