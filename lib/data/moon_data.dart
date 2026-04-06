import 'app_settings.dart';
import '../l10n/app_strings.dart';

enum MoonLocationState {
  available,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class MoonData {
  const MoonData({
    required this.generatedAt,
    required this.phase,
    required this.phaseLabel,
    required this.illuminationFraction,
    required this.locationState,
    this.latitude,
    this.longitude,
    this.altitudeDegrees,
  });

  final DateTime generatedAt;
  final double phase;
  final String phaseLabel;
  final double illuminationFraction;
  final MoonLocationState locationState;
  final double? latitude;
  final double? longitude;
  final double? altitudeDegrees;

  int get illuminationPercentage => (illuminationFraction * 100).round();

  bool get hasLocalObservation =>
      latitude != null && longitude != null && altitudeDegrees != null;

  bool get isAboveHorizon => hasLocalObservation && altitudeDegrees! > 0;

  String get localObservationLabel {
    return localObservationLabelFor(const AppStrings(AppLanguage.catala));
  }

  String localObservationLabelFor(AppStrings strings) {
    if (!hasLocalObservation) {
      switch (locationState) {
        case MoonLocationState.permissionDenied:
          return strings.moonPermissionDeniedLabel();
        case MoonLocationState.permissionDeniedForever:
          return strings.moonPermissionDeniedForeverLabel();
        case MoonLocationState.serviceDisabled:
          return strings.moonServiceDisabledLabel();
        case MoonLocationState.unavailable:
          return strings.moonLocationUnavailableLabel();
        case MoonLocationState.available:
          return strings.moonInsufficientLocationLabel();
      }
    }

    final int degrees = altitudeDegrees!.abs().round();

    if (degrees == 0) {
      return strings.moonAtHorizonLabel();
    }

    if (isAboveHorizon) {
      return strings.moonAboveHorizonLabel(degrees);
    }

    return strings.moonBelowHorizonLabel(degrees);
  }

  String get sourceLabel {
    return sourceLabelFor(const AppStrings(AppLanguage.catala));
  }

  String sourceLabelFor(AppStrings strings) {
    if (hasLocalObservation) {
      return strings.moonSourceWithLocation();
    }

    return strings.moonSourceWithoutLocation();
  }
}
