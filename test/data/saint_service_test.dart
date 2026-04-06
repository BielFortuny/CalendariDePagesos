import 'dart:convert';

import 'package:calendari_de_pagesos/data/saint_cache_store.dart';
import 'package:calendari_de_pagesos/data/saint_data.dart';
import 'package:calendari_de_pagesos/data/saint_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeSaintCacheStore extends SaintCacheStore {
  _FakeSaintCacheStore({this.cachedData});

  SaintData? cachedData;
  int readCount = 0;
  int writeCount = 0;
  List<SaintData> writtenEntries = <SaintData>[];

  @override
  Future<SaintData?> read(DateTime date) async {
    readCount += 1;
    return cachedData;
  }

  @override
  Future<void> write(SaintData data) async {
    writeCount += 1;
    cachedData = data;
  }

  @override
  Future<void> writeAll(Iterable<SaintData> dataEntries) async {
    final List<SaintData> entries = dataEntries.toList(growable: false);
    writeCount += 1;
    writtenEntries = entries;

    if (entries.isNotEmpty) {
      cachedData = entries.first;
    }
  }
}

void main() {
  test(
    'prioritizes nearby traditions and stores recent history locally',
    () async {
      final MockClient client = MockClient((request) async {
        expect(request.url.host, 'nameday.abalin.net');
        expect(request.url.path, '/api/V2/date');

        final String day = request.url.queryParameters['day']!;
        final String month = request.url.queryParameters['month']!;

        expect(month, '4');

        return http.Response(
          jsonEncode(<String, Object>{
            'success': true,
            'message': 'Namedays for 04-$day',
            'data': <String, String>{
              'es': 'Sant del dia $day',
              'it': 'Tradició italiana $day',
              'fr': 'Tradició francesa $day',
              'ru': 'Stand with Ukraine!',
            },
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });
      final _FakeSaintCacheStore cacheStore = _FakeSaintCacheStore();

      final SaintService service = SaintService(
        client: client,
        cacheStore: cacheStore,
        historyDaysToCache: 3,
      );
      final saintData = await service.loadSaintDataFor(DateTime(2026, 4, 6));

      expect(saintData.headline, 'Sant del dia 6');
      expect(
        saintData.entries.map((entry) => entry.title).toList(),
        orderedEquals(<String>[
          'Sant del dia 6',
          'Tradició italiana 6',
          'Tradició francesa 6',
        ]),
      );
      expect(
        saintData.entries.map((entry) => entry.sourceLabel).toList(),
        orderedEquals(<String>['Espanya', 'Itàlia', 'França']),
      );
      expect(cacheStore.writeCount, 1);
      expect(cacheStore.readCount, 0);
      expect(
        cacheStore.writtenEntries
            .map((entry) => entry.generatedAt.day)
            .toList(),
        orderedEquals(<int>[6, 5, 4]),
      );
      expect(cacheStore.cachedData?.headline, 'Sant del dia 6');
    },
  );

  test(
    'falls back to cached saint data when the network request fails',
    () async {
      final MockClient client = MockClient((request) async {
        return http.Response('offline', 503);
      });
      final _FakeSaintCacheStore cacheStore = _FakeSaintCacheStore(
        cachedData: SaintData(
          generatedAt: DateTime(2026, 4, 6),
          headline: 'Celso, Diógenes',
          entries: const <SaintEntry>[
            SaintEntry(
              title: 'Celso, Diógenes',
              countryCode: 'es',
              sourceLabel: 'Espanya',
            ),
            SaintEntry(
              title: 'Marcellin',
              countryCode: 'fr',
              sourceLabel: 'França',
            ),
          ],
        ),
      );

      final SaintService service = SaintService(
        client: client,
        cacheStore: cacheStore,
      );
      final SaintData saintData = await service.loadSaintDataFor(
        DateTime(2026, 4, 6, 9, 30),
      );

      expect(saintData.headline, 'Celso, Diógenes');
      expect(saintData.entries, hasLength(2));
      expect(cacheStore.readCount, 1);
      expect(cacheStore.writeCount, 0);
    },
  );
}
