import 'package:calendari_de_pagesos/data/app_settings.dart';
import 'package:calendari_de_pagesos/data/app_version_info.dart';
import 'package:calendari_de_pagesos/theme/app_theme.dart';
import 'package:calendari_de_pagesos/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('renders settings sections and enables save after a change', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final AppSettingsController controller = AppSettingsController(
      store: AppSettingsStore(),
    );

    await tester.pumpWidget(
      AppSettingsScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.buildLightTheme(),
          home: SettingsPage(
            versionLoader: () async => const AppVersionInfo(
              appName: 'Terra i Sol',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Configuració'), findsOneWidget);
    expect(find.text('Mida de la lletra'), findsOneWidget);
    expect(find.text('Notificacions de feines del camp'), findsOneWidget);
    expect(find.text('Configuració desada'), findsOneWidget);
    expect(find.textContaining('1.0.0+1'), findsOneWidget);

    await tester.tap(find.text('Gran'));
    await tester.pumpAndSettle();

    expect(find.text('Desar canvis'), findsOneWidget);
  });
}
