import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'field_work_cache_store.dart';
import 'field_work_data.dart';
import 'moon_data.dart';
import 'moon_service.dart';

class FieldWorkLocation {
  const FieldWorkLocation({
    required this.latitude,
    required this.longitude,
    required this.usesDeviceLocation,
  });

  final double latitude;
  final double longitude;
  final bool usesDeviceLocation;
}

class FieldWorkService {
  const FieldWorkService({
    http.Client? client,
    Future<FieldWorkLocation> Function()? locationResolver,
    FieldWorkCacheStore? cacheStore,
    this.moonService = const MoonService(),
    this.historyDaysToCache = 5,
  }) : _client = client,
       _locationResolver = locationResolver,
       _cacheStore = cacheStore;

  final http.Client? _client;
  final Future<FieldWorkLocation> Function()? _locationResolver;
  final FieldWorkCacheStore? _cacheStore;
  final MoonService moonService;
  final int historyDaysToCache;

  static const double _fallbackLatitude = 41.7340;
  static const double _fallbackLongitude = 1.5200;

  Future<FieldWorkData> loadCurrentFieldWorkData() {
    return loadFieldWorkDataFor(DateTime.now());
  }

  Future<FieldWorkData> loadFieldWorkDataFor(DateTime date) async {
    final DateTime cacheDate = DateTime(date.year, date.month, date.day);
    final http.Client client = _client ?? http.Client();
    final FieldWorkCacheStore cacheStore =
        _cacheStore ?? FieldWorkCacheStore(maxEntries: historyDaysToCache);

    late Object error;
    late StackTrace stackTrace;

    try {
      final FieldWorkLocation location = await _resolveLocation();
      final _FieldForecast forecast = await _loadForecast(client, location);
      final MoonData moonData = await moonService.loadMoonDataFor(
        cacheDate,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final FieldWorkData fieldWorkData = FieldWorkData(
        generatedAt: cacheDate,
        weatherSummary: _buildWeatherSummary(forecast),
        lunarSummary: _buildLunarSummary(moonData),
        sourceLabel: _buildSourceLabel(location),
        tasks: _buildTasks(cacheDate, forecast, moonData),
        proverb: _proverbForDate(cacheDate),
      );

      try {
        await cacheStore.write(fieldWorkData);
      } catch (_) {}

      return fieldWorkData;
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    } finally {
      if (_client == null) {
        client.close();
      }
    }

    try {
      final FieldWorkData? cachedData = await cacheStore.read(cacheDate);

      if (cachedData != null) {
        return cachedData;
      }
    } catch (_) {}

    Error.throwWithStackTrace(error, stackTrace);
  }

  String _buildSourceLabel(FieldWorkLocation location) {
    final String locationLabel = location.usesDeviceLocation
        ? 'a la teva ubicació actual'
        : 'per a una ubicació de referència a Catalunya central';

    return 'Fonts: Open-Meteo per a la previsió real $locationLabel i càlcul astronòmic propi per a la fase lunar.';
  }

  Future<FieldWorkLocation> _resolveLocation() async {
    if (_locationResolver != null) {
      return _locationResolver!();
    }

    final FieldWorkLocation fallbackLocation = const FieldWorkLocation(
      latitude: _fallbackLatitude,
      longitude: _fallbackLongitude,
      usesDeviceLocation: false,
    );

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return fallbackLocation;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return fallbackLocation;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return FieldWorkLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        usesDeviceLocation: true,
      );
    } catch (_) {
      return fallbackLocation;
    }
  }

  Future<_FieldForecast> _loadForecast(
    http.Client client,
    FieldWorkLocation location,
  ) async {
    final Uri uri =
        Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
          'latitude': location.latitude.toStringAsFixed(4),
          'longitude': location.longitude.toStringAsFixed(4),
          'current': 'temperature_2m,precipitation,wind_speed_10m',
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum',
          'timezone': 'auto',
          'forecast_days': '3',
        });

    final http.Response response = await client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('No s\'ha pogut carregar la previsio agraria.');
    }

    final Object? decoded = json.decode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta meteorologica no valida.');
    }

    final Map<String, dynamic> current = Map<String, dynamic>.from(
      decoded['current'] as Map<dynamic, dynamic>,
    );
    final Map<String, dynamic> daily = Map<String, dynamic>.from(
      decoded['daily'] as Map<dynamic, dynamic>,
    );

    final List<double> maxTemperatures = _doubleList(
      daily['temperature_2m_max'],
    );
    final List<double> minTemperatures = _doubleList(
      daily['temperature_2m_min'],
    );
    final List<double> precipitation = _doubleList(daily['precipitation_sum']);

    if (maxTemperatures.isEmpty ||
        minTemperatures.isEmpty ||
        precipitation.isEmpty) {
      throw const FormatException('La previsio no porta prou dades.');
    }

    final double totalPrecipitation = precipitation
        .take(3)
        .fold<double>(0, (sum, value) => sum + value);

    return _FieldForecast(
      currentTemperature: _asDouble(current['temperature_2m']),
      currentPrecipitation: _asDouble(current['precipitation']),
      currentWindSpeed: _asDouble(current['wind_speed_10m']),
      minTemperatureWindow: minTemperatures.reduce(
        (value, element) => value < element ? value : element,
      ),
      maxTemperatureWindow: maxTemperatures.reduce(
        (value, element) => value > element ? value : element,
      ),
      precipitationWindow: totalPrecipitation,
    );
  }

  List<FieldWorkTask> _buildTasks(
    DateTime date,
    _FieldForecast forecast,
    MoonData moonData,
  ) {
    final List<FieldWorkTask> tasks = <FieldWorkTask>[
      _buildSeasonalTask(date, forecast, moonData),
      _buildConditionTask(forecast, moonData),
    ];

    return tasks;
  }

  FieldWorkTask _buildSeasonalTask(
    DateTime date,
    _FieldForecast forecast,
    MoonData moonData,
  ) {
    final _FieldSeason season = _seasonForMonth(date.month);
    final String maxTemp = _formatNumber(forecast.maxTemperatureWindow);
    final String minTemp = _formatNumber(forecast.minTemperatureWindow);
    final bool waxingMoon = _isWaxingMoon(moonData.phaseLabel);
    final String moonLabel = moonData.phaseLabel.toLowerCase();

    switch (season) {
      case _FieldSeason.spring:
        if (forecast.minTemperatureWindow <= 4) {
          return FieldWorkTask(
            title: 'Protegir el planter tendre',
            description:
                'Les minimes previstes baixen fins a $minTemp °C. Amb $moonLabel és millor protegir tomaqueres, pebrots i mongeteres a la nit i ajornar els trasplantaments mes delicats fins que el sòl recuperi temperatura.',
          );
        }

        if (waxingMoon) {
          return FieldWorkTask(
            title: 'Sembrar i trasplantar cultius de fulla',
            description:
                'La $moonLabel afavoreix l\'empenta vegetativa i, amb maximes de $maxTemp °C i minimes de $minTemp °C, tens bona finestra per enciams, bledes, alfàbrega i planter tendre. Rega a peu just després de plantar.',
          );
        }

        return FieldWorkTask(
          title: 'Aclarir i desbrotar la primavera',
          description:
              'Amb $moonLabel i temperatures entre $minTemp °C i $maxTemp °C, convé aclarir pastanagues, remolatxes i cebes, i treure brots sobrers als fruiters joves per equilibrar vigor.',
        );
      case _FieldSeason.summer:
        if (forecast.maxTemperatureWindow >= 30) {
          return FieldWorkTask(
            title: 'Regar de bon mati i encoixinar',
            description:
                'Amb puntes de $maxTemp °C i $moonLabel, concentra el reg a primera hora i protegeix el sòl amb encoixinat per reduir evaporació i estrès hídric.',
          );
        }

        if (waxingMoon) {
          return FieldWorkTask(
            title: 'Guiar el creixement dels cultius d\'estiu',
            description:
                'La $moonLabel acompanya el creixement vegetatiu. És bona finestra per emparrar tomaqueres i mongeteres, lligar brots nous i fer regs curts de suport.',
          );
        }

        return FieldWorkTask(
          title: 'Esporgar lleugerament i contenir vigor',
          description:
              'Amb $moonLabel i previsio suau, entre $minTemp °C i $maxTemp °C, pots retirar fullatge excessiu, aclarir fruits massa carregats i airejar el cultiu.',
        );
      case _FieldSeason.autumn:
        if (waxingMoon) {
          return FieldWorkTask(
            title: 'Sembrar tardor de fulla i llegum curta',
            description:
                'Amb $moonLabel i humitat moderada, és bon moment per faves primerenques, espinacs i mesclums de tardor. Dona un reg curt per ajudar a l\'arrencada.',
          );
        }

        if (forecast.precipitationWindow <= 4) {
          return FieldWorkTask(
            title: 'Plantar bulbs i treballar arrels',
            description:
                'Amb $moonLabel i poca pluja prevista, és bona finestra per alls, cebes i raves. La lluna a la baixa acompanya l\'arrelament i el treball més profund del sòl.',
          );
        }

        return FieldWorkTask(
          title: 'Preparar bancals i adobar',
          description:
              'La humitat prevista i $moonLabel ajuden a incorporar compost i fem curtit sense resecar el llit de sembra. Deixa el sòl lleuger i ben airejat.',
        );
      case _FieldSeason.winter:
        if (forecast.minTemperatureWindow <= 0) {
          return FieldWorkTask(
            title: 'Protegir brots i citrics',
            description:
                'Les minimes poden baixar fins a $minTemp °C. Amb $moonLabel, cobreix els cultius sensibles i evita podes fortes abans de les nits més fredes.',
          );
        }

        if (waxingMoon) {
          return FieldWorkTask(
            title: 'Preparar planter protegit i empelts',
            description:
                'La $moonLabel és bona per viver i brot tendre. Aprofita temperatures entre $minTemp °C i $maxTemp °C per revisar planter protegit i preparar empelts suaus.',
          );
        }

        return FieldWorkTask(
          title: 'Podar fruiters en repos',
          description:
              'Amb $moonLabel i temperatures contingudes, entre $minTemp °C i $maxTemp °C, és bona finestra per poda de formació i per retirar fusta seca en fruiters de fulla caduca.',
        );
    }
  }

  FieldWorkTask _buildConditionTask(
    _FieldForecast forecast,
    MoonData moonData,
  ) {
    final String rain = _formatNumber(forecast.precipitationWindow);
    final String wind = _formatNumber(forecast.currentWindSpeed);
    final String moonLabel = moonData.phaseLabel.toLowerCase();
    final bool waningMoon = _isWaningMoon(moonData.phaseLabel);

    if (forecast.precipitationWindow >= 12) {
      return FieldWorkTask(
        title: 'Obrir drenatges i vigilar fongs',
        description:
            'Amb uns $rain mm previstos en tres dies i $moonLabel, convé repassar solcs i drenatges, ajornar feines que compactin el terreny i vigilar l\'entrada de fongs.',
      );
    }

    if (forecast.currentWindSpeed >= 25) {
      return FieldWorkTask(
        title: 'Revisar tutors i lligams',
        description:
            'El vent actual ronda els $wind km/h. Amb $moonLabel, reforça tutors, emparrats i malles per evitar trencaments en horta, vinya o fruiters joves.',
      );
    }

    if (forecast.precipitationWindow <= 3) {
      if (waningMoon) {
        return FieldWorkTask(
          title: 'Fer reg curt i treballar arrels',
          description:
              'Amb només $rain mm previstos i $moonLabel, aprofita per fer regs de suport, escardar i dedicar la jornada a cebes, alls i cultius d\'arrel.',
        );
      }

      return FieldWorkTask(
        title: 'Fer reg de suport i sembrar aromàtiques',
        description:
            'Amb només $rain mm previstos a 72 hores i $moonLabel, val la pena fer regs curts, repassar l\'herba i sembrar o repicar aromàtiques i cultius de fulla.',
      );
    }

    return FieldWorkTask(
      title: 'Ventilar el cultiu i observar el fullatge',
      description:
          'La previsió és moderada i la $moonLabel acompanya feines fines. Aprofita per airejar plantacions denses, observar taques de fongs i retirar fulles o brots que ja no treballen bé.',
    );
  }

  String _buildWeatherSummary(_FieldForecast forecast) {
    return 'Pròximes 72 h: màx. ${_formatNumber(forecast.maxTemperatureWindow)} °C, mín. ${_formatNumber(forecast.minTemperatureWindow)} °C, temperatura actual ${_formatNumber(forecast.currentTemperature)} °C, pluja acumulada ${_formatNumber(forecast.precipitationWindow)} mm i vent actual ${_formatNumber(forecast.currentWindSpeed)} km/h.';
  }

  String _buildLunarSummary(MoonData moonData) {
    return 'Fase lunar: ${moonData.phaseLabel} amb ${moonData.illuminationPercentage}% d\'il·luminació.';
  }

  String _proverbForDate(DateTime date) {
    const Map<int, List<String>> proverbs = <int, List<String>>{
      1: <String>[
        'Pel gener, tanca la porta i encen el braser.',
        'Gener fred i seré, bon blat i bon graner.',
      ],
      2: <String>[
        'Pel febrer, un dia dolent i l\'altre tambe.',
        'Si el febrer no febreja, o mal any o mal graner.',
      ],
      3: <String>[
        'Marc marcot, mata la vella a la vora del foc.',
        'Quan el marc ve com lleo, l\'abril surt com anyell.',
      ],
      4: <String>[
        'A l\'abril, cada gota en val per mil.',
        'Abril finit, hivern destruït.',
      ],
      5: <String>['Al maig, cada dia un raig.', 'Maig humit fa el pagès ric.'],
      6: <String>['Pel juny, la falç al puny.', 'Juny brillant, any abundant.'],
      7: <String>[
        'Pel juliol, beure, suar i la fresca buscar.',
        'Juliol xafogos, blat abundos.',
      ],
      8: <String>[
        'A l\'agost, bull el mar i bull el most.',
        'Agost sec, any de molta mel i molt vi.',
      ],
      9: <String>[
        'Pel setembre, qui tingui blat que sembri.',
        'Setembre assolellat, bon most i bon sembrat.',
      ],
      10: <String>[
        'Quan l\'octubre es finit, mor la mosca i el mosquit.',
        'Octubre plujos, any abundos.',
      ],
      11: <String>[
        'Pel novembre, cava i sembra.',
        'Novembre humit, et fara ric.',
      ],
      12: <String>[
        'Pel desembre, gelades i sopes escaldades.',
        'Desembre nevat, bon any assegurat.',
      ],
    };

    final List<String> monthlyProverbs = proverbs[date.month] ?? proverbs[1]!;

    return monthlyProverbs[(date.day - 1) % monthlyProverbs.length];
  }

  _FieldSeason _seasonForMonth(int month) {
    if (month >= 3 && month <= 5) {
      return _FieldSeason.spring;
    }
    if (month >= 6 && month <= 8) {
      return _FieldSeason.summer;
    }
    if (month >= 9 && month <= 11) {
      return _FieldSeason.autumn;
    }

    return _FieldSeason.winter;
  }

  bool _isWaxingMoon(String phaseLabel) {
    return phaseLabel == 'Lluna Nova' ||
        phaseLabel == 'Lluna Creixent' ||
        phaseLabel == 'Quart Creixent' ||
        phaseLabel == 'Lluna Gibosa Creixent';
  }

  bool _isWaningMoon(String phaseLabel) {
    return phaseLabel == 'Lluna Gibosa Minvant' ||
        phaseLabel == 'Quart Minvant' ||
        phaseLabel == 'Lluna Minvant';
  }

  List<double> _doubleList(Object? value) {
    if (value is! List) {
      throw const FormatException('Llista meteorologica no valida.');
    }

    return value.map(_asDouble).toList(growable: false);
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    throw const FormatException('Valor numeric no valid.');
  }

  String _formatNumber(double value) {
    final String text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

enum _FieldSeason { spring, summer, autumn, winter }

class _FieldForecast {
  const _FieldForecast({
    required this.currentTemperature,
    required this.currentPrecipitation,
    required this.currentWindSpeed,
    required this.minTemperatureWindow,
    required this.maxTemperatureWindow,
    required this.precipitationWindow,
  });

  final double currentTemperature;
  final double currentPrecipitation;
  final double currentWindSpeed;
  final double minTemperatureWindow;
  final double maxTemperatureWindow;
  final double precipitationWindow;
}
