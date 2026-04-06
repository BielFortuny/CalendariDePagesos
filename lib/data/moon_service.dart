import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'moon_data.dart';

const double _radiansPerDegree = math.pi / 180;
const double _obliquity = 23.4397 * _radiansPerDegree;

class MoonService {
  const MoonService();

  Future<MoonData> loadCurrentMoonData() async {
    return loadMoonDataFor(DateTime.now());
  }

  Future<MoonData> loadMoonDataFor(
    DateTime date, {
    double? latitude,
    double? longitude,
  }) async {
    final DateTime generatedAt = date;
    final _MoonIllumination illumination = _calculateMoonIllumination(
      generatedAt.toUtc(),
    );

    if (latitude != null && longitude != null) {
      final _MoonPosition moonPosition = _calculateMoonPosition(
        generatedAt.toUtc(),
        latitude: latitude,
        longitude: longitude,
      );

      return MoonData(
        generatedAt: generatedAt,
        phase: illumination.phase,
        phaseLabel: _phaseLabel(illumination.phase),
        illuminationFraction: illumination.fraction.clamp(0.0, 1.0).toDouble(),
        locationState: MoonLocationState.available,
        latitude: latitude,
        longitude: longitude,
        altitudeDegrees: moonPosition.altitudeDegrees,
      );
    }

    try {
      final Position position = await _determinePosition();
      final _MoonPosition moonPosition = _calculateMoonPosition(
        generatedAt.toUtc(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return MoonData(
        generatedAt: generatedAt,
        phase: illumination.phase,
        phaseLabel: _phaseLabel(illumination.phase),
        illuminationFraction: illumination.fraction.clamp(0.0, 1.0).toDouble(),
        locationState: MoonLocationState.available,
        latitude: position.latitude,
        longitude: position.longitude,
        altitudeDegrees: moonPosition.altitudeDegrees,
      );
    } on _MoonLocationException catch (error) {
      return MoonData(
        generatedAt: generatedAt,
        phase: illumination.phase,
        phaseLabel: _phaseLabel(illumination.phase),
        illuminationFraction: illumination.fraction.clamp(0.0, 1.0).toDouble(),
        locationState: error.state,
      );
    }
  }

  Future<Position> _determinePosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const _MoonLocationException(MoonLocationState.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _MoonLocationException(MoonLocationState.permissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _MoonLocationException(
        MoonLocationState.permissionDeniedForever,
      );
    }

    if (permission == LocationPermission.unableToDetermine) {
      throw const _MoonLocationException(MoonLocationState.unavailable);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      throw const _MoonLocationException(MoonLocationState.unavailable);
    }
  }

  _MoonIllumination _calculateMoonIllumination(DateTime dateUtc) {
    final double days = _toDays(dateUtc);
    final _SunCoordinates sunCoordinates = _sunCoordinates(days);
    final _MoonCoordinates moonCoordinates = _moonCoordinates(days);
    const double sunDistance = 149598000;

    final double phaseAngle = math.acos(
      _clampUnit(
        math.sin(sunCoordinates.declination) *
                math.sin(moonCoordinates.declination) +
            math.cos(sunCoordinates.declination) *
                math.cos(moonCoordinates.declination) *
                math.cos(
                  sunCoordinates.rightAscension -
                      moonCoordinates.rightAscension,
                ),
      ),
    );

    final double incidenceAngle = math.atan2(
      sunDistance * math.sin(phaseAngle),
      moonCoordinates.distance - sunDistance * math.cos(phaseAngle),
    );

    final double angle = math.atan2(
      math.cos(sunCoordinates.declination) *
          math.sin(
            sunCoordinates.rightAscension - moonCoordinates.rightAscension,
          ),
      math.sin(sunCoordinates.declination) *
              math.cos(moonCoordinates.declination) -
          math.cos(sunCoordinates.declination) *
              math.sin(moonCoordinates.declination) *
              math.cos(
                sunCoordinates.rightAscension - moonCoordinates.rightAscension,
              ),
    );

    final double fraction = (1 + math.cos(incidenceAngle)) / 2;
    final double rawPhase =
        0.5 + 0.5 * incidenceAngle * (angle < 0 ? -1 : 1) / math.pi;
    final double normalizedPhase = rawPhase - rawPhase.floorToDouble();

    return _MoonIllumination(fraction: fraction, phase: normalizedPhase);
  }

  _MoonPosition _calculateMoonPosition(
    DateTime dateUtc, {
    required double latitude,
    required double longitude,
  }) {
    final double days = _toDays(dateUtc);
    final double longitudeWest = -longitude * _radiansPerDegree;
    final double latitudeRadians = latitude * _radiansPerDegree;
    final _MoonCoordinates moonCoordinates = _moonCoordinates(days);
    final double hourAngle =
        _siderealTime(days, longitudeWest) - moonCoordinates.rightAscension;

    double altitude = _altitude(
      hourAngle,
      latitudeRadians,
      moonCoordinates.declination,
    );
    altitude += _astronomicalRefraction(altitude);

    return _MoonPosition(altitudeDegrees: altitude / _radiansPerDegree);
  }

  String _phaseLabel(double phase) {
    if (phase < 0.03 || phase >= 0.97) {
      return 'Lluna Nova';
    }
    if (phase < 0.22) {
      return 'Lluna Creixent';
    }
    if (phase < 0.28) {
      return 'Quart Creixent';
    }
    if (phase < 0.47) {
      return 'Lluna Gibosa Creixent';
    }
    if (phase < 0.53) {
      return 'Lluna Plena';
    }
    if (phase < 0.72) {
      return 'Lluna Gibosa Minvant';
    }
    if (phase < 0.78) {
      return 'Quart Minvant';
    }

    return 'Lluna Minvant';
  }

  double _toJulian(DateTime dateUtc) {
    return dateUtc.millisecondsSinceEpoch / 86400000 - 0.5 + 2440588;
  }

  double _toDays(DateTime dateUtc) => _toJulian(dateUtc) - 2451545;

  _SunCoordinates _sunCoordinates(double days) {
    final double meanAnomaly =
        _radiansPerDegree * (357.5291 + 0.98560028 * days);
    final double equationOfCenter =
        _radiansPerDegree *
        (1.9148 * math.sin(meanAnomaly) +
            0.02 * math.sin(2 * meanAnomaly) +
            0.0003 * math.sin(3 * meanAnomaly));
    final double perihelionLongitude = _radiansPerDegree * 102.9372;
    final double eclipticLongitude =
        meanAnomaly + equationOfCenter + perihelionLongitude + math.pi;

    return _SunCoordinates(
      rightAscension: _rightAscension(eclipticLongitude, 0),
      declination: _declination(eclipticLongitude, 0),
    );
  }

  _MoonCoordinates _moonCoordinates(double days) {
    final double eclipticLongitude =
        _radiansPerDegree * (218.316 + 13.176396 * days);
    final double meanAnomaly = _radiansPerDegree * (134.963 + 13.064993 * days);
    final double meanDistance = _radiansPerDegree * (93.272 + 13.22935 * days);

    final double longitude =
        eclipticLongitude + _radiansPerDegree * 6.289 * math.sin(meanAnomaly);
    final double latitude = _radiansPerDegree * 5.128 * math.sin(meanDistance);
    final double distance = 385001 - 20905 * math.cos(meanAnomaly);

    return _MoonCoordinates(
      rightAscension: _rightAscension(longitude, latitude),
      declination: _declination(longitude, latitude),
      distance: distance,
    );
  }

  double _rightAscension(double longitude, double latitude) {
    return math.atan2(
      math.sin(longitude) * math.cos(_obliquity) -
          math.tan(latitude) * math.sin(_obliquity),
      math.cos(longitude),
    );
  }

  double _declination(double longitude, double latitude) {
    return math.asin(
      math.sin(latitude) * math.cos(_obliquity) +
          math.cos(latitude) * math.sin(_obliquity) * math.sin(longitude),
    );
  }

  double _siderealTime(double days, double longitudeWest) {
    return _radiansPerDegree * (280.16 + 360.9856235 * days) - longitudeWest;
  }

  double _altitude(double hourAngle, double latitude, double declination) {
    return math.asin(
      math.sin(latitude) * math.sin(declination) +
          math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
    );
  }

  double _astronomicalRefraction(double altitude) {
    final double safeAltitude = altitude < 0 ? 0 : altitude;

    return 0.0002967 /
        math.tan(safeAltitude + 0.00312536 / (safeAltitude + 0.08901179));
  }

  double _clampUnit(double value) => value.clamp(-1.0, 1.0).toDouble();
}

class _MoonLocationException implements Exception {
  const _MoonLocationException(this.state);

  final MoonLocationState state;
}

class _SunCoordinates {
  const _SunCoordinates({
    required this.rightAscension,
    required this.declination,
  });

  final double rightAscension;
  final double declination;
}

class _MoonCoordinates {
  const _MoonCoordinates({
    required this.rightAscension,
    required this.declination,
    required this.distance,
  });

  final double rightAscension;
  final double declination;
  final double distance;
}

class _MoonIllumination {
  const _MoonIllumination({required this.fraction, required this.phase});

  final double fraction;
  final double phase;
}

class _MoonPosition {
  const _MoonPosition({required this.altitudeDegrees});

  final double altitudeDegrees;
}
