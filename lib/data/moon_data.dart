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
    if (!hasLocalObservation) {
      switch (locationState) {
        case MoonLocationState.permissionDenied:
          return 'Activa la ubicació per saber si la lluna es veu des d\'on ets.';
        case MoonLocationState.permissionDeniedForever:
          return 'Permet la ubicació als ajustos per calcular la visibilitat local.';
        case MoonLocationState.serviceDisabled:
          return 'Activa els serveis d\'ubicació per obtenir la visibilitat real.';
        case MoonLocationState.unavailable:
          return 'No s\'ha pogut determinar la teva ubicació ara mateix.';
        case MoonLocationState.available:
          return 'No hi ha prou dades per calcular la visibilitat local.';
      }
    }

    final int degrees = altitudeDegrees!.abs().round();

    if (degrees == 0) {
      return 'Ara mateix és pràcticament a l\'horitzó.';
    }

    if (isAboveHorizon) {
      return 'Ara és a $degrees° sobre l\'horitzó.';
    }

    return 'Ara és a $degrees° sota l\'horitzó.';
  }

  String get sourceLabel {
    if (hasLocalObservation) {
      return 'Calculat des de la teva ubicació actual.';
    }

    return 'La fase és real, però falta la ubicació per calcular la visibilitat local.';
  }
}