import 'dart:convert';

import 'package:http/http.dart' as http;

import 'saint_cache_store.dart';
import 'saint_data.dart';

class SaintService {
  const SaintService({
    http.Client? client,
    SaintCacheStore? cacheStore,
    this.historyDaysToCache = 5,
  }) : _client = client,
       _cacheStore = cacheStore;

  final http.Client? _client;
  final SaintCacheStore? _cacheStore;
  final int historyDaysToCache;

  static const Map<String, String> _countryLabels = <String, String>{
    'at': 'Àustria',
    'de': 'Alemanya',
    'es': 'Espanya',
    'fr': 'França',
    'it': 'Itàlia',
    'pl': 'Polònia',
    'sk': 'Eslovàquia',
  };

  static const List<String> _preferredCountryCodes = <String>[
    'es',
    'it',
    'fr',
    'de',
    'at',
    'pl',
    'sk',
  ];

  Future<SaintData> loadCurrentSaintData() {
    return loadSaintDataFor(DateTime.now());
  }

  Future<SaintData> loadSaintDataFor(DateTime date) async {
    final DateTime cacheDate = DateTime(date.year, date.month, date.day);
    final http.Client client = _client ?? http.Client();
    final SaintCacheStore cacheStore =
        _cacheStore ?? SaintCacheStore(maxEntries: historyDaysToCache);

    late Object error;
    late StackTrace stackTrace;

    try {
      final SaintData saintData = await _fetchSaintDataFromNetwork(
        client,
        cacheDate,
      );
      final List<SaintData> historyEntries = await _fetchHistoryWindow(
        client,
        anchorDate: cacheDate,
        currentDay: saintData,
      );

      try {
        await cacheStore.writeAll(historyEntries);
      } catch (_) {}

      return saintData;
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    } finally {
      if (_client == null) {
        client.close();
      }
    }

    try {
      final SaintData? cachedSaintData = await cacheStore.read(cacheDate);

      if (cachedSaintData != null) {
        return cachedSaintData;
      }
    } catch (_) {}

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<List<SaintData>> _fetchHistoryWindow(
    http.Client client, {
    required DateTime anchorDate,
    required SaintData currentDay,
  }) async {
    if (historyDaysToCache <= 1) {
      return <SaintData>[currentDay];
    }

    final List<Future<SaintData?>> historyFutures = <Future<SaintData?>>[];

    for (int offset = 1; offset < historyDaysToCache; offset += 1) {
      final DateTime historyDate = anchorDate.subtract(Duration(days: offset));
      historyFutures.add(_tryFetchSaintDataFromNetwork(client, historyDate));
    }

    final List<SaintData?> resolvedHistory = await Future.wait(historyFutures);

    return <SaintData>[currentDay, ...resolvedHistory.whereType<SaintData>()];
  }

  Future<SaintData?> _tryFetchSaintDataFromNetwork(
    http.Client client,
    DateTime date,
  ) async {
    try {
      return await _fetchSaintDataFromNetwork(client, date);
    } catch (_) {
      return null;
    }
  }

  Future<SaintData> _fetchSaintDataFromNetwork(
    http.Client client,
    DateTime date,
  ) async {
    final Uri uri = Uri.https(
      'nameday.abalin.net',
      '/api/V2/date',
      <String, String>{'day': '${date.day}', 'month': '${date.month}'},
    );
    final http.Response response = await client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Fail');
    }

    final Object? decoded = json.decode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta de santoral no vàlida.');
    }

    return _parseSaintData(decoded, date);
  }

  SaintData _parseSaintData(Map<String, dynamic> payload, DateTime date) {
    final Object? rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('No s\'han rebut dades del santoral.');
    }

    final List<SaintEntry> preferredEntries = _collectEntries(
      rawData,
      _preferredCountryCodes,
    );
    final List<SaintEntry> selectedEntries = preferredEntries.isNotEmpty
        ? preferredEntries
        : _collectEntries(rawData, rawData.keys.toList());

    if (selectedEntries.isEmpty) {
      throw const FormatException('El santoral del dia ha arribat buit.');
    }

    return SaintData(
      generatedAt: date,
      headline: selectedEntries.first.title,
      entries: selectedEntries.take(3).toList(growable: false),
    );
  }

  List<SaintEntry> _collectEntries(
    Map<String, dynamic> rawData,
    List<String> countryCodes,
  ) {
    final List<SaintEntry> entries = <SaintEntry>[];
    final Set<String> seenTitles = <String>{};

    for (final String countryCode in countryCodes) {
      final Object? rawValue = rawData[countryCode];

      if (rawValue is! String) {
        continue;
      }

      final String title = _normalizeTitle(rawValue);

      if (!_isUsableTitle(title)) {
        continue;
      }

      final String normalizedTitle = title.toLowerCase();

      if (!seenTitles.add(normalizedTitle)) {
        continue;
      }

      entries.add(
        SaintEntry(
          title: title,
          countryCode: countryCode,
          sourceLabel: _countryLabels[countryCode] ?? countryCode.toUpperCase(),
        ),
      );

      if (entries.length == 3) {
        break;
      }
    }

    return entries;
  }

  String _normalizeTitle(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isUsableTitle(String value) {
    final String lowered = value.toLowerCase();

    if (value.isEmpty || lowered == 'n/a' || lowered.contains('ukraine')) {
      return false;
    }

    return RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(value);
  }
}
