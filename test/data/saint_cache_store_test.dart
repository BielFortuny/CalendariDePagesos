import 'package:calendari_de_pagesos/data/saint_cache_store.dart';
import 'package:calendari_de_pagesos/data/saint_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('writes and restores saint data for the same day', () async {
    final SaintCacheStore cacheStore = SaintCacheStore();
    final SaintData saintData = SaintData(
      generatedAt: DateTime(2026, 4, 6, 7, 15),
      headline: 'Celso, Diógenes',
      entries: <SaintEntry>[
        SaintEntry(
          title: 'Celso, Diógenes',
          countryCode: 'es',
          sourceLabel: 'Espanya',
        ),
        SaintEntry(
          title: 'Pietro Da Verona, Martire',
          countryCode: 'it',
          sourceLabel: 'Itàlia',
        ),
      ],
    );

    await cacheStore.write(saintData);

    final SaintData? restored = await cacheStore.read(DateTime(2026, 4, 6));

    expect(restored, isNotNull);
    expect(restored?.headline, 'Celso, Diógenes');
    expect(
      restored?.entries.map((entry) => entry.sourceLabel).toList(),
      <String>['Espanya', 'Itàlia'],
    );
  });

  test('discards corrupted cached saint data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'saint_cache_v1_2026-04-06': '{"headline":42}',
    });
    final SaintCacheStore cacheStore = SaintCacheStore();

    final SaintData? restored = await cacheStore.read(DateTime(2026, 4, 6));
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(restored, isNull);
    expect(preferences.getString('saint_cache_v1_2026-04-06'), isNull);
  });

  test('keeps only the most recent cached history window', () async {
    final SaintCacheStore cacheStore = SaintCacheStore(maxEntries: 3);

    await cacheStore.writeAll(<SaintData>[
      SaintData(
        generatedAt: DateTime(2026, 4, 6),
        headline: 'Dia 6',
        entries: const <SaintEntry>[
          SaintEntry(title: 'Dia 6', countryCode: 'es', sourceLabel: 'Espanya'),
        ],
      ),
      SaintData(
        generatedAt: DateTime(2026, 4, 5),
        headline: 'Dia 5',
        entries: const <SaintEntry>[
          SaintEntry(title: 'Dia 5', countryCode: 'es', sourceLabel: 'Espanya'),
        ],
      ),
      SaintData(
        generatedAt: DateTime(2026, 4, 4),
        headline: 'Dia 4',
        entries: const <SaintEntry>[
          SaintEntry(title: 'Dia 4', countryCode: 'es', sourceLabel: 'Espanya'),
        ],
      ),
      SaintData(
        generatedAt: DateTime(2026, 4, 3),
        headline: 'Dia 3',
        entries: const <SaintEntry>[
          SaintEntry(title: 'Dia 3', countryCode: 'es', sourceLabel: 'Espanya'),
        ],
      ),
    ]);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(preferences.getStringList('saint_cache_v1_index'), <String>[
      'saint_cache_v1_2026-04-06',
      'saint_cache_v1_2026-04-05',
      'saint_cache_v1_2026-04-04',
    ]);
    expect(await cacheStore.read(DateTime(2026, 4, 6)), isNotNull);
    expect(await cacheStore.read(DateTime(2026, 4, 5)), isNotNull);
    expect(await cacheStore.read(DateTime(2026, 4, 4)), isNotNull);
    expect(await cacheStore.read(DateTime(2026, 4, 3)), isNull);
  });
}
