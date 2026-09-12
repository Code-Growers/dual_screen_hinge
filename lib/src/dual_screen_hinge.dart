import 'models.dart';
import 'platform_interface.dart';

/// Entry point for foldable telemetry, snapshots, and display sessions.
final class DualScreenHinge {
  DualScreenHinge._();

  /// Shared plugin facade.
  static final DualScreenHinge instance = DualScreenHinge._();

  DualScreenHingePlatform get _platform => DualScreenHingePlatform.instance;

  /// Broadcast stream of deduplicated coherent native snapshots.
  Stream<DualScreenState> get events => _platform.events;

  /// Continuous non-null angle values filtered from [events].
  Stream<double> get hingeAngleEvents => events
      .where((state) => state.hingeAngle != null)
      .map((state) => state.hingeAngle!)
      .distinct();

  /// Reads a state snapshot without waiting for the next event.
  Future<DualScreenState> currentState() => _platform.currentState();

  /// Reads current runtime capabilities.
  Future<DualScreenCapabilities> capabilities() => _platform.capabilities();

  /// Requests Android rear-display activity transfer.
  Future<void> startRearDisplay() => _platform.startRearDisplay();

  /// Stops a rear-display transfer owned by this Flutter engine.
  Future<void> stopRearDisplay() => _platform.stopRearDisplay();

  /// Starts an Android secondary Flutter presentation.
  Future<void> startDualScreen({
    String entrypoint = 'dualScreenSecondaryMain',
    List<String> arguments = const <String>[],
  }) => _platform.startDualScreen(entrypoint: entrypoint, arguments: arguments);

  /// Stops the secondary presentation and destroys its engine and view.
  Future<void> stopDualScreen() => _platform.stopDualScreen();
}
