import 'package:flutter/services.dart';

import 'models.dart';
import 'platform_interface.dart';

final class MethodChannelDualScreenHinge extends DualScreenHingePlatform {
  MethodChannelDualScreenHinge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel = methodChannel ?? const MethodChannel(methodChannelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName);

  static const methodChannelName = 'com.example.iphone_duo_hinge/methods';
  static const eventChannelName = 'com.example.iphone_duo_hinge/events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  Stream<DualScreenState>? _sharedEvents;

  @override
  Stream<DualScreenState> get events => _sharedEvents ??= _eventChannel
      .receiveBroadcastStream()
      .map((event) => DualScreenState.fromMap(_map(event)))
      .distinct();

  @override
  Future<DualScreenState> currentState() async =>
      DualScreenState.fromMap(_map(await _invoke<Object?>('currentState')));

  @override
  Future<DualScreenCapabilities> capabilities() async =>
      DualScreenCapabilities.fromMap(
        _map(await _invoke<Object?>('capabilities')),
      );

  @override
  Future<void> startRearDisplay() => _invoke<void>('startRearDisplay');

  @override
  Future<void> stopRearDisplay() => _invoke<void>('stopRearDisplay');

  @override
  Future<void> startDualScreen({
    required String entrypoint,
    List<String> arguments = const <String>[],
  }) {
    if (!RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(entrypoint)) {
      throw const DualScreenException(
        'invalidEntrypoint',
        'The Dart entrypoint must be a valid top-level identifier.',
      );
    }
    return _invoke<void>('startDualScreen', <String, Object>{
      'entrypoint': entrypoint,
      'arguments': arguments,
    });
  }

  @override
  Future<void> stopDualScreen() => _invoke<void>('stopDualScreen');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw DualScreenException(
        error.code,
        error.message ?? 'Native dual-screen operation failed.',
        error.details,
      );
    }
  }
}

Map<Object?, Object?> _map(Object? value) =>
    value is Map ? value.cast<Object?, Object?>() : const <Object?, Object?>{};
