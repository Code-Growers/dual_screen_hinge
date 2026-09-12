import 'dart:async';

import 'package:dual_screen_hinge/dual_screen_hinge.dart';
import 'package:dual_screen_hinge/src/method_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class FakePlatform extends DualScreenHingePlatform
    with MockPlatformInterfaceMixin {
  final controller = StreamController<DualScreenState>.broadcast();
  String? entrypoint;
  List<String>? arguments;

  @override
  Stream<DualScreenState> get events => controller.stream;
  @override
  Future<DualScreenCapabilities> capabilities() async =>
      const DualScreenCapabilities();
  @override
  Future<DualScreenState> currentState() async => const DualScreenState();
  @override
  Future<void> startDualScreen({
    required String entrypoint,
    List<String> arguments = const [],
  }) async {
    this.entrypoint = entrypoint;
    this.arguments = arguments;
  }

  @override
  Future<void> startRearDisplay() async {}
  @override
  Future<void> stopDualScreen() async {}
  @override
  Future<void> stopRearDisplay() async {}
}

void main() {
  test('method channel implementation is the default', () {
    expect(
      DualScreenHingePlatform.instance,
      isA<MethodChannelDualScreenHinge>(),
    );
  });

  test('facade forwards startup arguments and filters angle events', () async {
    final original = DualScreenHingePlatform.instance;
    final fake = FakePlatform();
    DualScreenHingePlatform.instance = fake;
    addTearDown(() {
      DualScreenHingePlatform.instance = original;
      fake.controller.close();
    });

    final angle = DualScreenHinge.instance.hingeAngleEvents.first;
    fake.controller
      ..add(const DualScreenState())
      ..add(const DualScreenState(hingeAngle: 71));
    expect(await angle, 71);

    await DualScreenHinge.instance.startDualScreen(
      arguments: const <String>['one'],
    );
    expect(fake.entrypoint, 'dualScreenSecondaryMain');
    expect(fake.arguments, <String>['one']);
  });
}
