import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_settings.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'ui/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppSettingsController settingsController = AppSettingsController(
    store: AppSettingsStore(),
  );
  await settingsController.load();

  runApp(CalendariDePagesosApp(settingsController: settingsController));
}

class CalendariDePagesosApp extends StatelessWidget {
  const CalendariDePagesosApp({required this.settingsController, super.key});

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        final AppSettings settings = settingsController.settings;
        final AppStrings strings = AppStrings(settings.language);

        return AppSettingsScope(
          controller: settingsController,
          child: MaterialApp(
            title: strings.appTitle,
            debugShowCheckedModeBanner: false,
            locale: strings.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.buildLightTheme(
              highContrast: settings.highContrast,
            ),
            builder: (BuildContext context, Widget? child) {
              final MediaQueryData mediaQuery =
                  MediaQuery.maybeOf(context) ?? const MediaQueryData();

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.fontSize.scaleFactor),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const MainPage(),
          ),
        );
      },
    );
  }
}
