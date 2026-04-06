import 'package:calendari_de_pagesos/data/field_work_cache_store.dart';
import 'package:calendari_de_pagesos/data/field_work_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('writes and restores cached field-work data', () async {
    final FieldWorkCacheStore cacheStore = FieldWorkCacheStore();
    final FieldWorkData fieldWorkData = FieldWorkData(
      generatedAt: DateTime(2026, 4, 6),
      weatherSummary: 'Resum meteorologic.',
      lunarSummary: 'Fase lunar: Quart Creixent.',
      sourceLabel: 'Fonts combinades.',
      tasks: const <FieldWorkTask>[
        FieldWorkTask(title: 'Feina 1', description: 'Descripcio 1'),
        FieldWorkTask(title: 'Feina 2', description: 'Descripcio 2'),
      ],
      proverb: 'Abril finit, hivern destruït.',
    );

    await cacheStore.write(fieldWorkData);

    final FieldWorkData? restored = await cacheStore.read(DateTime(2026, 4, 6));

    expect(restored, isNotNull);
    expect(restored?.lunarSummary, contains('Quart Creixent'));
    expect(restored?.tasks, hasLength(2));
  });

  test('discards corrupted cached field-work data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'field_work_cache_v1_2026-04-06': '{"weatherSummary":42}',
    });
    final FieldWorkCacheStore cacheStore = FieldWorkCacheStore();

    final FieldWorkData? restored = await cacheStore.read(DateTime(2026, 4, 6));
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(restored, isNull);
    expect(preferences.getString('field_work_cache_v1_2026-04-06'), isNull);
  });

  test('keeps only the newest cached field-work entries', () async {
    final FieldWorkCacheStore cacheStore = FieldWorkCacheStore(maxEntries: 2);

    await cacheStore.writeAll(<FieldWorkData>[
      FieldWorkData(
        generatedAt: DateTime(2026, 4, 6),
        weatherSummary: 'Dia 6',
        lunarSummary: 'Lluna 6',
        sourceLabel: 'Font 6',
        tasks: const <FieldWorkTask>[
          FieldWorkTask(title: 'Feina 6', description: 'Descripcio 6'),
        ],
        proverb: 'Refrany 6',
      ),
      FieldWorkData(
        generatedAt: DateTime(2026, 4, 5),
        weatherSummary: 'Dia 5',
        lunarSummary: 'Lluna 5',
        sourceLabel: 'Font 5',
        tasks: const <FieldWorkTask>[
          FieldWorkTask(title: 'Feina 5', description: 'Descripcio 5'),
        ],
        proverb: 'Refrany 5',
      ),
      FieldWorkData(
        generatedAt: DateTime(2026, 4, 4),
        weatherSummary: 'Dia 4',
        lunarSummary: 'Lluna 4',
        sourceLabel: 'Font 4',
        tasks: const <FieldWorkTask>[
          FieldWorkTask(title: 'Feina 4', description: 'Descripcio 4'),
        ],
        proverb: 'Refrany 4',
      ),
    ]);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(preferences.getStringList('field_work_cache_v1_index'), <String>[
      'field_work_cache_v1_2026-04-06',
      'field_work_cache_v1_2026-04-05',
    ]);
    expect(await cacheStore.read(DateTime(2026, 4, 6)), isNotNull);
    expect(await cacheStore.read(DateTime(2026, 4, 5)), isNotNull);
    expect(await cacheStore.read(DateTime(2026, 4, 4)), isNull);
  });
}
