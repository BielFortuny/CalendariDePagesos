import 'dart:convert';

import 'package:calendari_de_pagesos/data/field_work_cache_store.dart';
import 'package:calendari_de_pagesos/data/field_work_data.dart';
import 'package:calendari_de_pagesos/data/field_work_service.dart';
import 'package:calendari_de_pagesos/data/moon_data.dart';
import 'package:calendari_de_pagesos/data/moon_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeFieldWorkCacheStore extends FieldWorkCacheStore {
  _FakeFieldWorkCacheStore({this.cachedData});

  FieldWorkData? cachedData;
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<FieldWorkData?> read(DateTime date) async {
    readCount += 1;
    return cachedData;
  }

  @override
  Future<void> write(FieldWorkData data) async {
    writeCount += 1;
    cachedData = data;
  }
}

class _FakeMoonService extends MoonService {
  @override
  Future<MoonData> loadMoonDataFor(
    DateTime date, {
    double? latitude,
    double? longitude,
  }) async {
    return MoonData(
      generatedAt: date,
      phase: 0.24,
      phaseLabel: 'Quart Creixent',
      illuminationFraction: 0.48,
      locationState: MoonLocationState.available,
      latitude: latitude,
      longitude: longitude,
      altitudeDegrees: 12,
    );
  }
}

void main() {
  test('builds field-work guidance from weather and moon data', () async {
    final MockClient client = MockClient((request) async {
      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.path, '/v1/forecast');
      expect(request.url.queryParameters['forecast_days'], '3');

      return http.Response(
        jsonEncode(<String, Object>{
          'current': <String, Object>{
            'temperature_2m': 20.2,
            'precipitation': 0.0,
            'wind_speed_10m': 12.6,
          },
          'daily': <String, Object>{
            'temperature_2m_max': <double>[20.5, 18.9, 18.9],
            'temperature_2m_min': <double>[9.9, 8.1, 9.4],
            'precipitation_sum': <double>[0.0, 0.0, 0.0],
          },
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final FieldWorkService service = FieldWorkService(
      client: client,
      locationResolver: () async => const FieldWorkLocation(
        latitude: 41.39,
        longitude: 2.17,
        usesDeviceLocation: true,
      ),
      moonService: _FakeMoonService(),
    );

    final fieldWorkData = await service.loadFieldWorkDataFor(
      DateTime(2026, 4, 6),
    );

    expect(fieldWorkData.tasks, hasLength(2));
    expect(
      fieldWorkData.tasks.first.title,
      'Sembrar i trasplantar cultius de fulla',
    );
    expect(
      fieldWorkData.tasks.last.title,
      'Fer reg de suport i sembrar aromàtiques',
    );
    expect(fieldWorkData.weatherSummary, contains('pluja acumulada 0 mm'));
    expect(fieldWorkData.lunarSummary, contains('Quart Creixent'));
    expect(fieldWorkData.sourceLabel, contains('Open-Meteo'));
    expect(fieldWorkData.proverb, 'Abril finit, hivern destruït.');
  });

  test(
    'falls back to cached field-work data when the forecast request fails',
    () async {
      final MockClient client = MockClient((request) async {
        return http.Response('offline', 503);
      });
      final _FakeFieldWorkCacheStore cacheStore = _FakeFieldWorkCacheStore(
        cachedData: FieldWorkData(
          generatedAt: DateTime(2026, 4, 6),
          weatherSummary: 'Resum desat.',
          lunarSummary: 'Fase lunar desada.',
          sourceLabel: 'Dades recuperades del dispositiu.',
          tasks: const <FieldWorkTask>[
            FieldWorkTask(
              title: 'Treball desat',
              description: 'Consell guardat localment.',
            ),
          ],
          proverb: 'Abril finit, hivern destruït.',
        ),
      );

      final FieldWorkService service = FieldWorkService(
        client: client,
        cacheStore: cacheStore,
        locationResolver: () async => const FieldWorkLocation(
          latitude: 41.39,
          longitude: 2.17,
          usesDeviceLocation: true,
        ),
        moonService: _FakeMoonService(),
      );

      final FieldWorkData fieldWorkData = await service.loadFieldWorkDataFor(
        DateTime(2026, 4, 6),
      );

      expect(fieldWorkData.weatherSummary, 'Resum desat.');
      expect(fieldWorkData.tasks.single.title, 'Treball desat');
      expect(cacheStore.readCount, 1);
      expect(cacheStore.writeCount, 0);
    },
  );
}
