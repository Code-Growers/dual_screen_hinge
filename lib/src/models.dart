import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A normalized physical posture reported by the platform.
enum HingePosture { unknown, closed, halfOpened, flat, tent }

/// The display role currently hosting the primary Flutter view.
enum ActiveScreen { unknown, outer, inner }

/// Whether a display feature is a flexible fold or an occluding hinge.
enum FoldFeatureType { unknown, fold, hinge }

/// The axis followed by a fold feature in logical screen coordinates.
enum FoldFeatureOrientation { unknown, horizontal, vertical }

/// How much content a feature physically hides.
enum FoldFeatureOcclusion { unknown, none, full }

/// The lifecycle and availability of a controllable display mode.
enum DisplayModeState {
  unsupported,
  unavailable,
  available,
  starting,
  active,
  stopping,
  error,
}

@immutable
/// Geometry and native metadata for one physical display feature.
final class FoldFeature {
  /// Creates immutable fold feature metadata.
  const FoldFeature({
    required this.bounds,
    this.type = FoldFeatureType.unknown,
    this.orientation = FoldFeatureOrientation.unknown,
    this.occlusion = FoldFeatureOcclusion.unknown,
    this.isSeparating = false,
    this.nativeState = 'unknown',
  });

  /// Defensively decodes a StandardMessageCodec dictionary.
  factory FoldFeature.fromMap(Map<Object?, Object?> map) {
    final bounds = _map(map['bounds']);
    return FoldFeature(
      bounds: Rect.fromLTRB(
        _double(bounds['left']) ?? 0,
        _double(bounds['top']) ?? 0,
        _double(bounds['right']) ?? 0,
        _double(bounds['bottom']) ?? 0,
      ),
      type: _enumByName(FoldFeatureType.values, map['type']),
      orientation: _enumByName(
        FoldFeatureOrientation.values,
        map['orientation'],
      ),
      occlusion: _enumByName(FoldFeatureOcclusion.values, map['occlusion']),
      isSeparating: map['isSeparating'] == true,
      nativeState: _string(map['nativeState']) ?? 'unknown',
    );
  }

  /// Feature bounds in Flutter logical pixels.
  final Rect bounds;

  /// The physical feature type.
  final FoldFeatureType type;

  /// The feature's screen axis.
  final FoldFeatureOrientation orientation;

  /// The feature's content occlusion.
  final FoldFeatureOcclusion occlusion;

  /// Whether content is separated into distinct logical regions.
  final bool isSeparating;

  /// The unnormalized coarse state supplied by the native layout API.
  final String nativeState;

  @override
  bool operator ==(Object other) =>
      other is FoldFeature &&
      other.bounds == bounds &&
      other.type == type &&
      other.orientation == orientation &&
      other.occlusion == occlusion &&
      other.isSeparating == isSeparating &&
      other.nativeState == nativeState;

  @override
  int get hashCode => Object.hash(
    bounds,
    type,
    orientation,
    occlusion,
    isSeparating,
    nativeState,
  );
}

@immutable
/// A snapshot of an optional platform-controlled display mode.
final class DisplayMode {
  /// Creates an immutable display-mode snapshot.
  const DisplayMode({
    this.state = DisplayModeState.unsupported,
    this.isContentVisible = false,
    this.errorCode,
  });

  /// Defensively decodes a display-mode dictionary.
  factory DisplayMode.fromMap(Map<Object?, Object?> map) => DisplayMode(
    state: _enumByName(DisplayModeState.values, map['state']),
    isContentVisible: map['isContentVisible'] == true,
    errorCode: _string(map['errorCode']),
  );

  /// Current availability or session lifecycle.
  final DisplayModeState state;

  /// Whether the secondary presentation container is visible.
  final bool isContentVisible;

  /// Stable failure code for the latest mode error, when present.
  final String? errorCode;

  @override
  bool operator ==(Object other) =>
      other is DisplayMode &&
      other.state == state &&
      other.isContentVisible == isContentVisible &&
      other.errorCode == errorCode;

  @override
  int get hashCode => Object.hash(state, isContentVisible, errorCode);
}

@immutable
/// One coherent foldable-display snapshot emitted by the native plugin.
final class DualScreenState {
  /// Creates an immutable state snapshot.
  const DualScreenState({
    this.schemaVersion = 1,
    this.activeScreen = ActiveScreen.unknown,
    this.isInnerScreen,
    this.hingeAngle,
    this.posture = HingePosture.unknown,
    this.postureSource = 'unavailable',
    this.displayFeatures = const <FoldFeature>[],
    this.supportedPostures = const <String>[],
    this.rearDisplay = const DisplayMode(),
    this.dualScreen = const DisplayMode(),
  });

  /// Defensively decodes the versioned EventChannel payload.
  factory DualScreenState.fromMap(Map<Object?, Object?> map) {
    final displayModes = _map(map['displayModes']);
    return DualScreenState(
      schemaVersion: _int(map['schemaVersion']) ?? 1,
      activeScreen: _enumByName(ActiveScreen.values, map['activeScreen']),
      isInnerScreen: map['isInnerScreen'] is bool
          ? map['isInnerScreen'] as bool
          : null,
      hingeAngle: _double(map['hingeAngle']),
      posture: _enumByName(HingePosture.values, map['posture']),
      postureSource: _string(map['postureSource']) ?? 'unavailable',
      displayFeatures: _list(map['displayFeatures'])
          .whereType<Map>()
          .map((value) => FoldFeature.fromMap(_map(value)))
          .toList(growable: false),
      supportedPostures: _list(
        map['supportedPostures'],
      ).whereType<String>().toList(growable: false),
      rearDisplay: DisplayMode.fromMap(_map(displayModes['rearDisplay'])),
      dualScreen: DisplayMode.fromMap(_map(displayModes['dualScreen'])),
    );
  }

  /// Native payload schema, currently `1`.
  final int schemaVersion;

  /// Known screen role or [ActiveScreen.unknown].
  final ActiveScreen activeScreen;

  /// Whether the active iOS display is inner; normally null on Android.
  final bool? isInnerScreen;

  /// Raw platform hinge angle in degrees, when exposed.
  final double? hingeAngle;

  /// Normalized physical posture.
  final HingePosture posture;

  /// Native or derived source used to choose [posture].
  final String postureSource;

  /// Current physical folds and hinges in logical pixels.
  final List<FoldFeature> displayFeatures;

  /// Postures the native layout library reports as supported.
  final List<String> supportedPostures;

  /// Rear-display transfer capability and session state.
  final DisplayMode rearDisplay;

  /// Dual-screen presentation capability and session state.
  final DisplayMode dualScreen;

  @override
  bool operator ==(Object other) =>
      other is DualScreenState &&
      other.schemaVersion == schemaVersion &&
      other.activeScreen == activeScreen &&
      other.isInnerScreen == isInnerScreen &&
      other.hingeAngle == hingeAngle &&
      other.posture == posture &&
      other.postureSource == postureSource &&
      listEquals(other.displayFeatures, displayFeatures) &&
      listEquals(other.supportedPostures, supportedPostures) &&
      other.rearDisplay == rearDisplay &&
      other.dualScreen == dualScreen;

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    activeScreen,
    isInnerScreen,
    hingeAngle,
    posture,
    postureSource,
    Object.hashAll(displayFeatures),
    Object.hashAll(supportedPostures),
    rearDisplay,
    dualScreen,
  );
}

@immutable
/// Runtime feature support for the current device and OS state.
final class DualScreenCapabilities {
  /// Creates an immutable capability snapshot.
  const DualScreenCapabilities({
    this.platformSupported = false,
    this.hingeAngleSensor = false,
    this.layoutFeatures = false,
    this.rearDisplay = false,
    this.dualScreenPresentation = false,
  });

  /// Defensively decodes a native capability dictionary.
  factory DualScreenCapabilities.fromMap(Map<Object?, Object?> map) =>
      DualScreenCapabilities(
        platformSupported: map['platformSupported'] == true,
        hingeAngleSensor: map['hingeAngleSensor'] == true,
        layoutFeatures: map['layoutFeatures'] == true,
        rearDisplay: map['rearDisplay'] == true,
        dualScreenPresentation: map['dualScreenPresentation'] == true,
      );

  /// Whether at least one foldable API is supported.
  final bool platformSupported;

  /// Whether continuous angle telemetry is available.
  final bool hingeAngleSensor;

  /// Whether physical layout features are available.
  final bool layoutFeatures;

  /// Whether rear-display activity transfer is supported.
  final bool rearDisplay;

  /// Whether a secondary Flutter presentation is supported.
  final bool dualScreenPresentation;

  @override
  bool operator ==(Object other) =>
      other is DualScreenCapabilities &&
      other.platformSupported == platformSupported &&
      other.hingeAngleSensor == hingeAngleSensor &&
      other.layoutFeatures == layoutFeatures &&
      other.rearDisplay == rearDisplay &&
      other.dualScreenPresentation == dualScreenPresentation;

  @override
  int get hashCode => Object.hash(
    platformSupported,
    hingeAngleSensor,
    layoutFeatures,
    rearDisplay,
    dualScreenPresentation,
  );
}

/// A native channel failure with a stable machine-readable [code].
final class DualScreenException implements Exception {
  /// Creates a normalized plugin exception.
  const DualScreenException(this.code, this.message, [this.details]);

  /// Stable code such as `unsupported`, `unavailable`, or `noActivity`.
  final String code;

  /// Human-readable failure description.
  final String message;

  /// Optional native diagnostic details.
  final Object? details;

  @override
  String toString() => 'DualScreenException($code, $message)';
}

Map<Object?, Object?> _map(Object? value) =>
    value is Map ? value.cast<Object?, Object?>() : const <Object?, Object?>{};
List<Object?> _list(Object? value) =>
    value is List ? value.cast<Object?>() : const <Object?>[];
String? _string(Object? value) => value is String ? value : null;
double? _double(Object? value) => value is num ? value.toDouble() : null;
int? _int(Object? value) => value is num ? value.toInt() : null;

T _enumByName<T extends Enum>(List<T> values, Object? value) {
  final name = _string(value);
  return values.firstWhere(
    (candidate) => candidate.name == name,
    orElse: () => values.first,
  );
}
