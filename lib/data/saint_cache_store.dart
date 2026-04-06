import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'saint_data.dart';

class SaintCacheStore {
  SaintCacheStore({
    Future<SharedPreferences> Function()? preferencesLoader,
    this.maxEntries = 5,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesLoader;
  final int maxEntries;

  static const String _cachePrefix = 'saint_cache_v1_';
  static const String _cacheIndexKey = 'saint_cache_v1_index';

  Future<SaintData?> read(DateTime date) async {
    final SharedPreferences preferences = await _preferencesLoader();
    final String cacheKey = _cacheKeyFor(date);
    final String? rawValue = preferences.getString(cacheKey);

    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = json.decode(rawValue);

      if (decoded is! Map<String, dynamic>) {
        await _removeCacheKey(preferences, cacheKey);
        return null;
      }

      return SaintData.fromJson(decoded);
    } on FormatException {
      await _removeCacheKey(preferences, cacheKey);
      return null;
    }
  }

  Future<void> write(SaintData data) async {
    await writeAll(<SaintData>[data]);
  }

  Future<void> writeAll(Iterable<SaintData> dataEntries) async {
    final SharedPreferences preferences = await _preferencesLoader();
    final List<String> writtenKeys = <String>[];

    for (final SaintData data in dataEntries) {
      final String cacheKey = _cacheKeyFor(data.generatedAt);
      await preferences.setString(cacheKey, json.encode(data.toJson()));
      writtenKeys.add(cacheKey);
    }

    if (writtenKeys.isEmpty) {
      return;
    }

    await _mergeIndex(preferences, writtenKeys);
  }

  String _cacheKeyFor(DateTime date) {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String year = normalizedDate.year.toString();
    final String month = normalizedDate.month.toString().padLeft(2, '0');
    final String day = normalizedDate.day.toString().padLeft(2, '0');

    return '$_cachePrefix$year-$month-$day';
  }

  Future<void> _removeCacheKey(
    SharedPreferences preferences,
    String cacheKey,
  ) async {
    await preferences.remove(cacheKey);

    final List<String> updatedIndex =
        (preferences.getStringList(_cacheIndexKey) ?? const <String>[])
            .where((entry) => entry != cacheKey)
            .toList(growable: false);

    await preferences.setStringList(_cacheIndexKey, updatedIndex);
  }

  Future<void> _mergeIndex(
    SharedPreferences preferences,
    List<String> writtenKeys,
  ) async {
    final List<String> existingIndex =
        preferences.getStringList(_cacheIndexKey) ?? const <String>[];
    final List<String> nextIndex = <String>[];

    for (final String cacheKey in writtenKeys) {
      if (!nextIndex.contains(cacheKey)) {
        nextIndex.add(cacheKey);
      }
    }

    for (final String cacheKey in existingIndex) {
      if (!nextIndex.contains(cacheKey)) {
        nextIndex.add(cacheKey);
      }
    }

    final List<String> trimmedIndex = nextIndex
        .take(maxEntries)
        .toList(growable: false);
    final List<String> discardedKeys = nextIndex
        .skip(maxEntries)
        .toList(growable: false);

    for (final String discardedKey in discardedKeys) {
      await preferences.remove(discardedKey);
    }

    await preferences.setStringList(_cacheIndexKey, trimmedIndex);
  }
}
