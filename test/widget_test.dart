import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:calendari_de_pagesos/data/field_work_data.dart';
import 'package:calendari_de_pagesos/data/field_work_service.dart';
import 'package:calendari_de_pagesos/data/moon_data.dart';
import 'package:calendari_de_pagesos/data/moon_service.dart';
import 'package:calendari_de_pagesos/data/saint_data.dart';
import 'package:calendari_de_pagesos/data/saint_service.dart';
import 'package:calendari_de_pagesos/ui/avui_page.dart';

class _FakeMoonService extends MoonService {
  @override
  Future<MoonData> loadCurrentMoonData() async {
    return MoonData(
      generatedAt: DateTime(2026, 4, 6),
      phase: 0.5,
      phaseLabel: 'Lluna Plena',
      illuminationFraction: 1,
      locationState: MoonLocationState.available,
      latitude: 41.39,
      longitude: 2.17,
      altitudeDegrees: 18,
    );
  }
}

class _FakeSaintService extends SaintService {
  @override
  Future<SaintData> loadCurrentSaintData() async {
    return SaintData(
      generatedAt: DateTime(2026, 4, 6),
      headline: 'Celso, Diógenes',
      entries: const <SaintEntry>[
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
        SaintEntry(
          title: 'Marcellin',
          countryCode: 'fr',
          sourceLabel: 'França',
        ),
      ],
    );
  }
}

class _FakeFieldWorkService extends FieldWorkService {
  @override
  Future<FieldWorkData> loadCurrentFieldWorkData() async {
    return FieldWorkData(
      generatedAt: DateTime(2026, 4, 6),
      weatherSummary:
          'Pròximes 72 h: màx. 20,5 °C, mín. 8,1 °C, temperatura actual 20,2 °C, pluja acumulada 0 mm i vent actual 12,6 km/h.',
      lunarSummary: 'Fase lunar: Quart Creixent amb 48% d\'il·luminació.',
      sourceLabel:
          'Fonts: Open-Meteo per a la previsió real a la teva ubicació actual i càlcul astronòmic propi per a la fase lunar.',
      tasks: const <FieldWorkTask>[
        FieldWorkTask(
          title: 'Sembrar i trasplantar cultius de fulla',
          description:
              'La lluna creixent i el temps suau fan bona finestra per sembrar i trasplantar cultius de fulla.',
        ),
        FieldWorkTask(
          title: 'Fer reg de suport i sembrar aromàtiques',
          description:
              'Amb poca pluja i lluna creixent, convé fer regs curts i sembrar aromàtiques.',
        ),
      ],
      proverb: 'Abril finit, hivern destruït.',
    );
  }
}

void main() {
  testWidgets(
    'renders the today page with live-ready saints and field work data',
    (WidgetTester tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AvuiPage(
            moonService: _FakeMoonService(),
            saintService: _FakeSaintService(),
            fieldWorkService: _FakeFieldWorkService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SANTS DEL DIA'), findsOneWidget);
      expect(find.text('Celso, Diógenes'), findsNWidgets(2));
      expect(find.text('Pietro Da Verona, Martire'), findsOneWidget);
      expect(find.text('França'), findsOneWidget);
      expect(find.text('FEINES DEL CAMP'), findsOneWidget);
      expect(
        find.text('Sembrar i trasplantar cultius de fulla'),
        findsOneWidget,
      );
      expect(
        find.text('Fer reg de suport i sembrar aromàtiques'),
        findsOneWidget,
      );
      expect(find.textContaining('Quart Creixent'), findsOneWidget);
      expect(find.textContaining('Open-Meteo'), findsOneWidget);
      expect(find.text('"Abril finit, hivern destruït."'), findsOneWidget);
    },
  );
}
