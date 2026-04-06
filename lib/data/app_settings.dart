import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize {
  petita,
  mitjana,
  gran;

  String get label {
    switch (this) {
      case AppFontSize.petita:
        return 'Petita';
      case AppFontSize.mitjana:
        return 'Mitjana';
      case AppFontSize.gran:
        return 'Gran';
    }
  }

  double get scaleFactor {
    switch (this) {
      case AppFontSize.petita:
        return 0.92;
      case AppFontSize.mitjana:
        return 1.0;
      case AppFontSize.gran:
        return 1.12;
    }
  }

  static AppFontSize fromName(String? value) {
    return AppFontSize.values.firstWhere(
      (AppFontSize option) => option.name == value,
      orElse: () => AppFontSize.mitjana,
    );
  }
}

enum AppLanguage {
  catala,
  castellano,
  english;

  String get label {
    switch (this) {
      case AppLanguage.catala:
        return 'Català (Predeterminat)';
      case AppLanguage.castellano:
        return 'Castellano';
      case AppLanguage.english:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.catala:
        return 'ca';
      case AppLanguage.castellano:
        return 'es';
      case AppLanguage.english:
        return 'en';
    }
  }

  static AppLanguage fromCode(String? value) {
    return AppLanguage.values.firstWhere(
      (AppLanguage option) => option.code == value,
      orElse: () => AppLanguage.catala,
    );
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.fontSize = AppFontSize.mitjana,
    this.highContrast = false,
    this.sowingNotifications = true,
    this.weatherAlerts = false,
    this.language = AppLanguage.catala,
  });

  final AppFontSize fontSize;
  final bool highContrast;
  final bool sowingNotifications;
  final bool weatherAlerts;
  final AppLanguage language;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    AppFontSize? fontSize,
    bool? highContrast,
    bool? sowingNotifications,
    bool? weatherAlerts,
    AppLanguage? language,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      highContrast: highContrast ?? this.highContrast,
      sowingNotifications: sowingNotifications ?? this.sowingNotifications,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      language: language ?? this.language,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'fontSize': fontSize.name,
      'highContrast': highContrast,
      'sowingNotifications': sowingNotifications,
      'weatherAlerts': weatherAlerts,
      'language': language.code,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: AppFontSize.fromName(json['fontSize'] as String?),
      highContrast: json['highContrast'] as bool? ?? false,
      sowingNotifications: json['sowingNotifications'] as bool? ?? true,
      weatherAlerts: json['weatherAlerts'] as bool? ?? false,
      language: AppLanguage.fromCode(json['language'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppSettings &&
        other.fontSize == fontSize &&
        other.highContrast == highContrast &&
        other.sowingNotifications == sowingNotifications &&
        other.weatherAlerts == weatherAlerts &&
        other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      highContrast,
      sowingNotifications,
      weatherAlerts,
      language,
    );
  }
}

class AppSettingsStore {
  AppSettingsStore({Future<SharedPreferences> Function()? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesLoader;

  static const String _settingsKey = 'app_settings_v1';

  Future<AppSettings> read() async {
    final SharedPreferences preferences = await _preferencesLoader();
    final String? rawSettings = preferences.getString(_settingsKey);

    if (rawSettings == null || rawSettings.isEmpty) {
      return AppSettings.defaults;
    }

    try {
      final Object? decoded = json.decode(rawSettings);

      if (decoded is! Map<String, dynamic>) {
        await preferences.remove(_settingsKey);
        return AppSettings.defaults;
      }

      return AppSettings.fromJson(decoded);
    } on FormatException {
      await preferences.remove(_settingsKey);
      return AppSettings.defaults;
    }
  }

  Future<void> write(AppSettings settings) async {
    final SharedPreferences preferences = await _preferencesLoader();
    await preferences.setString(_settingsKey, json.encode(settings.toJson()));
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    required AppSettingsStore store,
    AppSettings initialSettings = AppSettings.defaults,
  }) : _store = store,
       _settings = initialSettings;

  final AppSettingsStore _store;

  AppSettings _settings;
  bool _isSaving = false;

  AppSettings get settings => _settings;
  bool get isSaving => _isSaving;

  Future<void> load() async {
    _settings = await _store.read();
    notifyListeners();
  }

  Future<void> save(AppSettings nextSettings) async {
    if (_isSaving) {
      return;
    }

    _settings = nextSettings;
    _isSaving = true;
    notifyListeners();

    try {
      await _store.write(nextSettings);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final AppSettingsController? controller = maybeControllerOf(context);

    assert(controller != null, 'No AppSettingsScope found in context.');
    return controller!;
  }

  static AppSettingsController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }

  static AppSettings settingsOf(BuildContext context) {
    return maybeControllerOf(context)?.settings ?? AppSettings.defaults;
  }
}
