import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_strings.dart';
import 'app_settings.dart';
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

  Future<FieldWorkData> loadCurrentFieldWorkData({
    AppLanguage language = AppLanguage.catala,
  }) {
    return loadFieldWorkDataFor(DateTime.now(), language: language);
  }

  Future<FieldWorkData> loadFieldWorkDataFor(
    DateTime date, {
    AppLanguage language = AppLanguage.catala,
  }) async {
    final DateTime cacheDate = DateTime(date.year, date.month, date.day);
    final http.Client client = _client ?? http.Client();
    final FieldWorkCacheStore cacheStore =
        _cacheStore ?? FieldWorkCacheStore(maxEntries: historyDaysToCache);
    final AppStrings strings = AppStrings(language);

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
        weatherSummary: _buildWeatherSummary(forecast, strings),
        lunarSummary: _buildLunarSummary(moonData, strings),
        sourceLabel: _buildSourceLabel(location, strings),
        tasks: _buildTasks(cacheDate, forecast, moonData, language),
        proverb: _proverbForDate(cacheDate, language),
        languageCode: language.code,
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

      if (cachedData != null && cachedData.languageCode == language.code) {
        return cachedData;
      }
    } catch (_) {}

    Error.throwWithStackTrace(error, stackTrace);
  }

  String _buildSourceLabel(FieldWorkLocation location, AppStrings strings) {
    final String locationLabel = location.usesDeviceLocation
        ? _localizedText(
            strings.language,
            ca: 'a la teva ubicació actual',
            es: 'en tu ubicación actual',
            en: 'for your current location',
          )
        : _localizedText(
            strings.language,
            ca: 'per a una ubicació de referència a Catalunya central',
            es: 'para una ubicación de referencia en Cataluña central',
            en: 'for a reference location in central Catalonia',
          );

    return _localizedText(
      strings.language,
      ca: 'Fonts: Open-Meteo per a la previsió real $locationLabel i càlcul astronòmic propi per a la fase lunar.',
      es: 'Fuentes: Open-Meteo para la previsión real $locationLabel y cálculo astronómico propio para la fase lunar.',
      en: 'Sources: Open-Meteo for the live forecast $locationLabel and an in-house astronomical calculation for the moon phase.',
    );
  }

  Future<FieldWorkLocation> _resolveLocation() async {
    if (_locationResolver != null) {
      return _locationResolver();
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
    AppLanguage language,
  ) {
    final List<FieldWorkTask> tasks = <FieldWorkTask>[
      _buildSeasonalTask(date, forecast, moonData, language),
      _buildConditionTask(forecast, moonData, language),
    ];

    return tasks;
  }

  FieldWorkTask _buildSeasonalTask(
    DateTime date,
    _FieldForecast forecast,
    MoonData moonData,
    AppLanguage language,
  ) {
    final _FieldSeason season = _seasonForMonth(date.month);
    final String maxTemp = _formatNumber(forecast.maxTemperatureWindow);
    final String minTemp = _formatNumber(forecast.minTemperatureWindow);
    final bool waxingMoon = _isWaxingMoon(moonData.phaseLabel);
    final AppStrings strings = AppStrings(language);
    final String moonLabel = strings
        .moonPhaseLabel(moonData.phaseLabel)
        .toLowerCase();

    switch (season) {
      case _FieldSeason.spring:
        if (forecast.minTemperatureWindow <= 4) {
          return _localizedTask(
            language,
            caTitle: 'Protegir el planter tendre',
            caDescription:
                'Les mínimes previstes baixen fins a $minTemp °C. Amb $moonLabel és millor protegir tomaqueres, pebrots i mongeteres a la nit i ajornar els trasplantaments més delicats fins que el sòl recuperi temperatura.',
            esTitle: 'Proteger el plantel tierno',
            esDescription:
                'Las mínimas previstas bajan hasta $minTemp °C. Con $moonLabel conviene proteger tomates, pimientos y judías por la noche y aplazar los trasplantes más delicados hasta que el suelo recupere temperatura.',
            enTitle: 'Protect tender seedlings',
            enDescription:
                'Forecast lows fall to $minTemp °C. With a $moonLabel it is better to protect tomatoes, peppers and beans overnight and delay the most delicate transplants until the soil warms up again.',
          );
        }

        if (waxingMoon) {
          return _localizedTask(
            language,
            caTitle: 'Sembrar i trasplantar cultius de fulla',
            caDescription:
                'La $moonLabel afavoreix l\'empenta vegetativa i, amb màximes de $maxTemp °C i mínimes de $minTemp °C, tens bona finestra per enciams, bledes, alfàbrega i planter tendre. Rega a peu just després de plantar.',
            esTitle: 'Sembrar y trasplantar cultivos de hoja',
            esDescription:
                'La $moonLabel favorece el impulso vegetativo y, con máximas de $maxTemp °C y mínimas de $minTemp °C, tienes una buena ventana para lechugas, acelgas, albahaca y plantel tierno. Riega al pie justo después de plantar.',
            enTitle: 'Sow and transplant leafy crops',
            enDescription:
                'A $moonLabel favours vegetative growth and, with highs of $maxTemp °C and lows of $minTemp °C, you have a good window for lettuce, chard, basil and tender seedlings. Water at the base right after planting.',
          );
        }

        return _localizedTask(
          language,
          caTitle: 'Aclarir i desbrotar la primavera',
          caDescription:
              'Amb $moonLabel i temperatures entre $minTemp °C i $maxTemp °C, convé aclarir pastanagues, remolatxes i cebes, i treure brots sobrers als fruiters joves per equilibrar vigor.',
          esTitle: 'Aclarar y despuntar en primavera',
          esDescription:
              'Con $moonLabel y temperaturas entre $minTemp °C y $maxTemp °C, conviene aclarar zanahorias, remolachas y cebollas, y quitar brotes sobrantes en los frutales jóvenes para equilibrar el vigor.',
          enTitle: 'Thin and tidy spring growth',
          enDescription:
              'With a $moonLabel and temperatures between $minTemp °C and $maxTemp °C, it is a good time to thin carrots, beetroot and onions, and remove excess shoots from young fruit trees to balance their vigour.',
        );
      case _FieldSeason.summer:
        if (forecast.maxTemperatureWindow >= 30) {
          return _localizedTask(
            language,
            caTitle: 'Regar de bon matí i encoixinar',
            caDescription:
                'Amb puntes de $maxTemp °C i $moonLabel, concentra el reg a primera hora i protegeix el sòl amb encoixinat per reduir evaporació i estrès hídric.',
            esTitle: 'Regar temprano y acolchar',
            esDescription:
                'Con picos de $maxTemp °C y $moonLabel, concentra el riego a primera hora y protege el suelo con acolchado para reducir la evaporación y el estrés hídrico.',
            enTitle: 'Water early and mulch',
            enDescription:
                'With peaks of $maxTemp °C and a $moonLabel, focus irrigation early in the day and protect the soil with mulch to reduce evaporation and water stress.',
          );
        }

        if (waxingMoon) {
          return _localizedTask(
            language,
            caTitle: 'Guiar el creixement dels cultius d\'estiu',
            caDescription:
                'La $moonLabel acompanya el creixement vegetatiu. És bona finestra per emparrar tomaqueres i mongeteres, lligar brots nous i fer regs curts de suport.',
            esTitle: 'Guiar el crecimiento de los cultivos de verano',
            esDescription:
                'La $moonLabel acompaña el crecimiento vegetativo. Es una buena ventana para entutorar tomates y judías, atar brotes nuevos y hacer riegos cortos de apoyo.',
            enTitle: 'Guide summer crop growth',
            enDescription:
                'A $moonLabel supports vegetative growth. It is a good window to trellis tomatoes and beans, tie new shoots and give short support irrigations.',
          );
        }

        return _localizedTask(
          language,
          caTitle: 'Esporgar lleugerament i contenir vigor',
          caDescription:
              'Amb $moonLabel i previsió suau, entre $minTemp °C i $maxTemp °C, pots retirar fullatge excessiu, aclarir fruits massa carregats i airejar el cultiu.',
          esTitle: 'Podar ligeramente y contener vigor',
          esDescription:
              'Con $moonLabel y una previsión suave, entre $minTemp °C y $maxTemp °C, puedes retirar follaje excesivo, aclarar frutos muy cargados y airear el cultivo.',
          enTitle: 'Prune lightly and contain vigour',
          enDescription:
              'With a $moonLabel and a mild forecast between $minTemp °C and $maxTemp °C, you can remove excess foliage, thin overloaded fruit and open up the crop.',
        );
      case _FieldSeason.autumn:
        if (waxingMoon) {
          return _localizedTask(
            language,
            caTitle: 'Sembrar tardor de fulla i llegum curta',
            caDescription:
                'Amb $moonLabel i humitat moderada, és bon moment per faves primerenques, espinacs i mesclums de tardor. Dona un reg curt per ajudar a l\'arrencada.',
            esTitle: 'Sembrar hoja de otoño y legumbre corta',
            esDescription:
                'Con $moonLabel y humedad moderada, es un buen momento para habas tempranas, espinacas y mezclas de otoño. Da un riego corto para ayudar al arranque.',
            enTitle: 'Sow autumn greens and quick legumes',
            enDescription:
                'With a $moonLabel and moderate moisture, it is a good moment for early broad beans, spinach and autumn salad mixes. Give a short watering to help establishment.',
          );
        }

        if (forecast.precipitationWindow <= 4) {
          return _localizedTask(
            language,
            caTitle: 'Plantar bulbs i treballar arrels',
            caDescription:
                'Amb $moonLabel i poca pluja prevista, és bona finestra per alls, cebes i raves. La lluna a la baixa acompanya l\'arrelament i el treball més profund del sòl.',
            esTitle: 'Plantar bulbos y trabajar raíces',
            esDescription:
                'Con $moonLabel y poca lluvia prevista, es una buena ventana para ajos, cebollas y rábanos. La luna a la baja acompaña el enraizamiento y el trabajo más profundo del suelo.',
            enTitle: 'Plant bulbs and work root crops',
            enDescription:
                'With a $moonLabel and little rain expected, it is a good window for garlic, onions and radishes. A waning moon supports rooting and deeper soil work.',
          );
        }

        return _localizedTask(
          language,
          caTitle: 'Preparar bancals i adobar',
          caDescription:
              'La humitat prevista i $moonLabel ajuden a incorporar compost i fem curtit sense resecar el llit de sembra. Deixa el sòl lleuger i ben airejat.',
          esTitle: 'Preparar bancales y abonar',
          esDescription:
              'La humedad prevista y $moonLabel ayudan a incorporar compost y estiércol curado sin resecar el lecho de siembra. Deja el suelo ligero y bien aireado.',
          enTitle: 'Prepare beds and fertilise',
          enDescription:
              'Expected moisture and a $moonLabel help work compost and matured manure into the bed without drying it out. Leave the soil light and well aerated.',
        );
      case _FieldSeason.winter:
        if (forecast.minTemperatureWindow <= 0) {
          return _localizedTask(
            language,
            caTitle: 'Protegir brots i cítrics',
            caDescription:
                'Les mínimes poden baixar fins a $minTemp °C. Amb $moonLabel, cobreix els cultius sensibles i evita podes fortes abans de les nits més fredes.',
            esTitle: 'Proteger brotes y cítricos',
            esDescription:
                'Las mínimas pueden bajar hasta $minTemp °C. Con $moonLabel, cubre los cultivos sensibles y evita podas fuertes antes de las noches más frías.',
            enTitle: 'Protect shoots and citrus',
            enDescription:
                'Lows may fall to $minTemp °C. With a $moonLabel, cover sensitive crops and avoid hard pruning before the coldest nights.',
          );
        }

        if (waxingMoon) {
          return _localizedTask(
            language,
            caTitle: 'Preparar planter protegit i empelts',
            caDescription:
                'La $moonLabel és bona per viver i brot tendre. Aprofita temperatures entre $minTemp °C i $maxTemp °C per revisar planter protegit i preparar empelts suaus.',
            esTitle: 'Preparar plantel protegido e injertos',
            esDescription:
                'La $moonLabel es buena para vivero y brote tierno. Aprovecha temperaturas entre $minTemp °C y $maxTemp °C para revisar plantel protegido y preparar injertos suaves.',
            enTitle: 'Prepare protected seedlings and grafts',
            enDescription:
                'A $moonLabel is favourable for nursery work and tender shoots. Use temperatures between $minTemp °C and $maxTemp °C to check protected seedlings and prepare gentle grafts.',
          );
        }

        return _localizedTask(
          language,
          caTitle: 'Podar fruiters en repòs',
          caDescription:
              'Amb $moonLabel i temperatures contingudes, entre $minTemp °C i $maxTemp °C, és bona finestra per poda de formació i per retirar fusta seca en fruiters de fulla caduca.',
          esTitle: 'Podar frutales en reposo',
          esDescription:
              'Con $moonLabel y temperaturas contenidas, entre $minTemp °C y $maxTemp °C, es una buena ventana para poda de formación y para retirar madera seca en frutales de hoja caduca.',
          enTitle: 'Prune dormant fruit trees',
          enDescription:
              'With a $moonLabel and contained temperatures between $minTemp °C and $maxTemp °C, it is a good window for training cuts and for removing dead wood from deciduous fruit trees.',
        );
    }
  }

  FieldWorkTask _buildConditionTask(
    _FieldForecast forecast,
    MoonData moonData,
    AppLanguage language,
  ) {
    final String rain = _formatNumber(forecast.precipitationWindow);
    final String wind = _formatNumber(forecast.currentWindSpeed);
    final AppStrings strings = AppStrings(language);
    final String moonLabel = strings
        .moonPhaseLabel(moonData.phaseLabel)
        .toLowerCase();
    final bool waningMoon = _isWaningMoon(moonData.phaseLabel);

    if (forecast.precipitationWindow >= 12) {
      return _localizedTask(
        language,
        caTitle: 'Obrir drenatges i vigilar fongs',
        caDescription:
            'Amb uns $rain mm previstos en tres dies i $moonLabel, convé repassar solcs i drenatges, ajornar feines que compactin el terreny i vigilar l\'entrada de fongs.',
        esTitle: 'Abrir drenajes y vigilar hongos',
        esDescription:
            'Con unos $rain mm previstos en tres días y $moonLabel, conviene repasar surcos y drenajes, aplazar labores que compacten el terreno y vigilar la entrada de hongos.',
        enTitle: 'Open drains and watch for fungi',
        enDescription:
            'With around $rain mm forecast over three days and a $moonLabel, it is worth checking furrows and drains, postponing jobs that compact the soil and watching for fungal pressure.',
      );
    }

    if (forecast.currentWindSpeed >= 25) {
      return _localizedTask(
        language,
        caTitle: 'Revisar tutors i lligams',
        caDescription:
            'El vent actual ronda els $wind km/h. Amb $moonLabel, reforça tutors, emparrats i malles per evitar trencaments en horta, vinya o fruiters joves.',
        esTitle: 'Revisar tutores y ataduras',
        esDescription:
            'El viento actual ronda los $wind km/h. Con $moonLabel, refuerza tutores, emparrados y mallas para evitar roturas en huerta, viña o frutales jóvenes.',
        enTitle: 'Check stakes and ties',
        enDescription:
            'Current wind is around $wind km/h. With a $moonLabel, reinforce stakes, trellises and mesh to avoid breakage in vegetables, vines or young fruit trees.',
      );
    }

    if (forecast.precipitationWindow <= 3) {
      if (waningMoon) {
        return _localizedTask(
          language,
          caTitle: 'Fer reg curt i treballar arrels',
          caDescription:
              'Amb només $rain mm previstos i $moonLabel, aprofita per fer regs de suport, escardar i dedicar la jornada a cebes, alls i cultius d\'arrel.',
          esTitle: 'Hacer riego corto y trabajar raíces',
          esDescription:
              'Con solo $rain mm previstos y $moonLabel, aprovecha para hacer riegos de apoyo, escardar y dedicar la jornada a cebollas, ajos y cultivos de raíz.',
          enTitle: 'Give a short irrigation and work root crops',
          enDescription:
              'With only $rain mm forecast and a $moonLabel, take the chance to give support irrigations, weed and dedicate the day to onions, garlic and root crops.',
        );
      }

      return _localizedTask(
        language,
        caTitle: 'Fer reg de suport i sembrar aromàtiques',
        caDescription:
            'Amb només $rain mm previstos a 72 hores i $moonLabel, val la pena fer regs curts, repassar l\'herba i sembrar o repicar aromàtiques i cultius de fulla.',
        esTitle: 'Hacer riego de apoyo y sembrar aromáticas',
        esDescription:
            'Con solo $rain mm previstos en 72 horas y $moonLabel, merece la pena hacer riegos cortos, repasar la hierba y sembrar o repicar aromáticas y cultivos de hoja.',
        enTitle: 'Top up irrigation and sow herbs',
        enDescription:
            'With only $rain mm forecast over 72 hours and a $moonLabel, it is worth doing short irrigations, tidying weeds and sowing or pricking out herbs and leafy crops.',
      );
    }

    return _localizedTask(
      language,
      caTitle: 'Ventilar el cultiu i observar el fullatge',
      caDescription:
          'La previsió és moderada i la $moonLabel acompanya feines fines. Aprofita per airejar plantacions denses, observar taques de fongs i retirar fulles o brots que ja no treballen bé.',
      esTitle: 'Ventilar el cultivo y observar el follaje',
      esDescription:
          'La previsión es moderada y la $moonLabel acompaña tareas finas. Aprovecha para airear plantaciones densas, observar manchas de hongos y retirar hojas o brotes que ya no trabajan bien.',
      enTitle: 'Ventilate the crop and inspect foliage',
      enDescription:
          'The forecast is moderate and a $moonLabel suits finer work. Use the moment to open up dense plantings, look for fungal spots and remove leaves or shoots that no longer perform well.',
    );
  }

  String _buildWeatherSummary(_FieldForecast forecast, AppStrings strings) {
    return _localizedText(
      strings.language,
      ca: 'Pròximes 72 h: màx. ${_formatNumber(forecast.maxTemperatureWindow)} °C, mín. ${_formatNumber(forecast.minTemperatureWindow)} °C, temperatura actual ${_formatNumber(forecast.currentTemperature)} °C, pluja acumulada ${_formatNumber(forecast.precipitationWindow)} mm i vent actual ${_formatNumber(forecast.currentWindSpeed)} km/h.',
      es: 'Próximas 72 h: máx. ${_formatNumber(forecast.maxTemperatureWindow)} °C, mín. ${_formatNumber(forecast.minTemperatureWindow)} °C, temperatura actual ${_formatNumber(forecast.currentTemperature)} °C, lluvia acumulada ${_formatNumber(forecast.precipitationWindow)} mm y viento actual ${_formatNumber(forecast.currentWindSpeed)} km/h.',
      en: 'Next 72 h: high ${_formatNumber(forecast.maxTemperatureWindow)} °C, low ${_formatNumber(forecast.minTemperatureWindow)} °C, current temperature ${_formatNumber(forecast.currentTemperature)} °C, accumulated rain ${_formatNumber(forecast.precipitationWindow)} mm and current wind ${_formatNumber(forecast.currentWindSpeed)} km/h.',
    );
  }

  String _buildLunarSummary(MoonData moonData, AppStrings strings) {
    final String phaseLabel = strings.moonPhaseLabel(moonData.phaseLabel);

    return _localizedText(
      strings.language,
      ca: 'Fase lunar: $phaseLabel amb ${moonData.illuminationPercentage}% d\'il·luminació.',
      es: 'Fase lunar: $phaseLabel con ${moonData.illuminationPercentage}% de iluminación.',
      en: 'Moon phase: $phaseLabel with ${moonData.illuminationPercentage}% illumination.',
    );
  }

  String _proverbForDate(DateTime date, AppLanguage language) {
    final Map<int, List<String>> proverbs = switch (language) {
      AppLanguage.catala => const <int, List<String>>{
        1: <String>[
          'Pel gener, tanca la porta i encén el braser.',
          'Gener fred i serè, bon blat i bon graner.',
        ],
        2: <String>[
          'Pel febrer, un dia dolent i l\'altre també.',
          'Si el febrer no febreja, o mal any o mal graner.',
        ],
        3: <String>[
          'Marc marcot, mata la vella a la vora del foc.',
          'Quan el març ve com lleó, l\'abril surt com anyell.',
        ],
        4: <String>[
          'A l\'abril, cada gota en val per mil.',
          'Abril finit, hivern destruït.',
        ],
        5: <String>[
          'Al maig, cada dia un raig.',
          'Maig humit fa el pagès ric.',
        ],
        6: <String>[
          'Pel juny, la falç al puny.',
          'Juny brillant, any abundant.',
        ],
        7: <String>[
          'Pel juliol, beure, suar i la fresca buscar.',
          'Juliol xafogós, blat abundós.',
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
          'Quan l\'octubre és finit, mor la mosca i el mosquit.',
          'Octubre plujós, any abundós.',
        ],
        11: <String>[
          'Pel novembre, cava i sembra.',
          'Novembre humit, et farà ric.',
        ],
        12: <String>[
          'Pel desembre, gelades i sopes escaldades.',
          'Desembre nevat, bon any assegurat.',
        ],
      },
      AppLanguage.castellano => const <int, List<String>>{
        1: <String>[
          'En enero, cierra la puerta y aviva el brasero.',
          'Enero frío y sereno, buen trigo y buen granero.',
        ],
        2: <String>[
          'En febrero, un día malo y el otro también.',
          'Si febrero no febrea, o mal año o mal granero.',
        ],
        3: <String>[
          'Marzo marceador, enfría hasta junto al fuego.',
          'Cuando marzo viene como león, abril sale como cordero.',
        ],
        4: <String>[
          'En abril, cada gota vale por mil.',
          'Abril acabado, invierno derrotado.',
        ],
        5: <String>[
          'En mayo, cada día un rayo.',
          'Mayo húmedo hace rico al labrador.',
        ],
        6: <String>[
          'En junio, la hoz en el puño.',
          'Junio brillante, año abundante.',
        ],
        7: <String>[
          'En julio, beber, sudar y buscar la fresca.',
          'Julio bochornoso, trigo abundoso.',
        ],
        8: <String>[
          'En agosto, hierve el mar y hierve el mosto.',
          'Agosto seco, año de mucha miel y mucho vino.',
        ],
        9: <String>[
          'En septiembre, quien tenga trigo que lo siembre.',
          'Septiembre soleado, buen mosto y buen sembrado.',
        ],
        10: <String>[
          'Cuando octubre termina, muere la mosca y el mosquito.',
          'Octubre lluvioso, año abundoso.',
        ],
        11: <String>[
          'En noviembre, cava y siembra.',
          'Noviembre húmedo te hará rico.',
        ],
        12: <String>[
          'En diciembre, heladas y sopas escaldadas.',
          'Diciembre nevado, buen año asegurado.',
        ],
      },
      AppLanguage.english => const <int, List<String>>{
        1: <String>[
          'In January, close the door and stoke the brazier.',
          'A cold, clear January fills both field and granary.',
        ],
        2: <String>[
          'In February, one day is rough and the next is no better.',
          'If February brings no bite, the year may fail in barn or field.',
        ],
        3: <String>[
          'Wild March can chill you even by the fire.',
          'When March comes like a lion, April leaves like a lamb.',
        ],
        4: <String>[
          'In April, every drop is worth a thousand.',
          'Once April is done, winter is undone.',
        ],
        5: <String>[
          'In May, every day brings a shower.',
          'A wet May makes a wealthy farmer.',
        ],
        6: <String>[
          'In June, keep the sickle close at hand.',
          'A bright June promises an abundant year.',
        ],
        7: <String>[
          'In July, drink, sweat and chase the shade.',
          'Sultry July can still mean a heavy harvest.',
        ],
        8: <String>[
          'In August, both sea and must are boiling.',
          'A dry August can bring plenty of honey and wine.',
        ],
        9: <String>[
          'In September, sow your wheat if you have it.',
          'A sunny September means good must and good sowing.',
        ],
        10: <String>[
          'When October ends, flies and mosquitoes fade away.',
          'A rainy October often brings an abundant year.',
        ],
        11: <String>[
          'In November, dig and sow.',
          'A damp November can make you rich.',
        ],
        12: <String>[
          'In December, frosts and steaming soup go together.',
          'A snowy December points to a good year ahead.',
        ],
      },
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

  String _localizedText(
    AppLanguage language, {
    required String ca,
    required String es,
    required String en,
  }) {
    switch (language) {
      case AppLanguage.catala:
        return ca;
      case AppLanguage.castellano:
        return es;
      case AppLanguage.english:
        return en;
    }
  }

  FieldWorkTask _localizedTask(
    AppLanguage language, {
    required String caTitle,
    required String caDescription,
    required String esTitle,
    required String esDescription,
    required String enTitle,
    required String enDescription,
  }) {
    switch (language) {
      case AppLanguage.catala:
        return FieldWorkTask(title: caTitle, description: caDescription);
      case AppLanguage.castellano:
        return FieldWorkTask(title: esTitle, description: esDescription);
      case AppLanguage.english:
        return FieldWorkTask(title: enTitle, description: enDescription);
    }
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
