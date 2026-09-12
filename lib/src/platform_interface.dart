import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';
import 'models.dart';

/// Injectable native platform contract used by the `DualScreenHinge` facade.
abstract class DualScreenHingePlatform extends PlatformInterface {
  DualScreenHingePlatform() : super(token: _token);

  static final Object _token = Object();
  static DualScreenHingePlatform _instance = MethodChannelDualScreenHinge();

  /// Active implementation, injectable for tests.
  static DualScreenHingePlatform get instance => _instance;

  static set instance(DualScreenHingePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<DualScreenState> get events;
  Future<DualScreenState> currentState();
  Future<DualScreenCapabilities> capabilities();
  Future<void> startRearDisplay();
  Future<void> stopRearDisplay();
  Future<void> startDualScreen({
    required String entrypoint,
    List<String> arguments = const <String>[],
  });
  Future<void> stopDualScreen();
}
