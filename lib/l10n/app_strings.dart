import 'package:flutter/material.dart';

import '../data/app_settings.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('es'),
    Locale('en'),
  ];

  static AppStrings of(BuildContext context) {
    return AppStrings(AppSettingsScope.settingsOf(context).language);
  }

  Locale get locale => Locale(language.code);

  String get appTitle {
    switch (language) {
      case AppLanguage.catala:
        return 'Terra i Sol';
      case AppLanguage.castellano:
        return 'Tierra y Sol';
      case AppLanguage.english:
        return 'Earth and Sun';
    }
  }

  String get calendar => _t('Calendari', 'Calendario', 'Calendar');
  String get today => _t('Avui', 'Hoy', 'Today');
  String get todayUppercase => _t('AVUI', 'HOY', 'TODAY');
  String get tips => _t('Consells', 'Consejos', 'Tips');
  String get comingSoon => _t(
    'Aviat hi haurà contingut en aquest apartat.',
    'Pronto habrá contenido en este apartado.',
    'Content for this section is coming soon.',
  );

  String get settingsTitle => _t('Configuració', 'Configuración', 'Settings');
  String get settingsIntro => _t(
    'Ajustos personals per a la vostra lectura',
    'Ajustes personales para vuestra lectura',
    'Personal settings for your reading experience',
  );
  String get settingsSavedSnackBar =>
      _t('Configuració desada.', 'Configuración guardada.', 'Settings saved.');
  String get saveChanges =>
      _t('Desar canvis', 'Guardar cambios', 'Save changes');
  String get settingsAlreadySaved =>
      _t('Configuració desada', 'Configuración guardada', 'Settings saved');
  String get fontSizeTitle =>
      _t('Mida de la lletra', 'Tamaño de letra', 'Font size');
  String get highContrastTitle =>
      _t('Contrast alt', 'Contraste alto', 'High contrast');
  String get highContrastSubtitle => _t(
    'Millora la llegibilitat amb colors més forts.',
    'Mejora la legibilidad con colores más fuertes.',
    'Improves readability with stronger colors.',
  );
  String get fieldNotificationsTitle => _t(
    'Notificacions de feines del camp',
    'Notificaciones de labores del campo',
    'Field work notifications',
  );
  String get sowingNotificationsLabel => _t(
    'Avisos de sembra i collita',
    'Avisos de siembra y cosecha',
    'Sowing and harvest alerts',
  );
  String get weatherAlertsLabel =>
      _t('Alertes meteorològiques', 'Alertas meteorológicas', 'Weather alerts');
  String get languageTitle => _t('Idioma', 'Idioma', 'Language');
  String get aboutCalendarTitle =>
      _t('Sobre el Calendari', 'Sobre el Calendario', 'About the Calendar');
  String get settingsAboutBody => _t(
    'Els canvis queden guardats al dispositiu i s\'apliquen a la lectura de l\'app.',
    'Los cambios se guardan en el dispositivo y se aplican a la lectura de la app.',
    'Changes are stored on the device and applied throughout the app.',
  );

  String appVersionLine({
    required String appName,
    required String version,
    required String buildNumber,
  }) {
    final String versionLabel = buildNumber.isEmpty
        ? version
        : '$version+$buildNumber';

    switch (language) {
      case AppLanguage.catala:
        return '$appName · versió $versionLabel';
      case AppLanguage.castellano:
        return '$appName · versión $versionLabel';
      case AppLanguage.english:
        return '$appName · version $versionLabel';
    }
  }

  String fontSizeLabel(AppFontSize value) {
    switch (value) {
      case AppFontSize.petita:
        return _t('Petita', 'Pequeña', 'Small');
      case AppFontSize.mitjana:
        return _t('Mitjana', 'Mediana', 'Medium');
      case AppFontSize.gran:
        return _t('Gran', 'Grande', 'Large');
    }
  }

  String languageOptionLabel(AppLanguage value) {
    switch (value) {
      case AppLanguage.catala:
        return _t(
          'Català (Predeterminat)',
          'Catalán (Predeterminado)',
          'Catalan (Default)',
        );
      case AppLanguage.castellano:
        return _t('Castellano', 'Castellano', 'Spanish');
      case AppLanguage.english:
        return 'English';
    }
  }

  String get moonPhaseSection =>
      _t('FASE DE LA LLUNA', 'FASE DE LA LUNA', 'MOON PHASE');
  String get saintsOfDaySection =>
      _t('SANTS DEL DIA', 'SANTOS DEL DÍA', 'SAINTS OF THE DAY');
  String get fieldWorkSection =>
      _t('FEINES DEL CAMP', 'LABORES DEL CAMPO', 'FIELD WORK');
  String get update => _t('Actualitza', 'Actualizar', 'Refresh');
  String get updateData =>
      _t('Actualitza dades', 'Actualizar datos', 'Refresh data');
  String get retry => _t('Reintenta', 'Reintentar', 'Retry');
  String get loadingSaints => _t(
    'Carregant santoral...',
    'Cargando santoral...',
    'Loading saint calendar...',
  );
  String get saintUnavailable => _t(
    'Santoral no disponible ara mateix',
    'Santoral no disponible ahora mismo',
    'Saint calendar unavailable right now',
  );
  String get moonVisibilityPrefix =>
      _t('Visibilitat', 'Visibilidad', 'Visibility');
  String moonVisibility(int percentage) {
    return '$moonVisibilityPrefix: $percentage%';
  }

  String get proverbAttribution =>
      _t('— REFRANYER POPULAR', '— REFRANERO POPULAR', '— TRADITIONAL SAYING');

  String get moonLoading => _t(
    'Calculant les dades lunars...',
    'Calculando los datos lunares...',
    'Calculating lunar data...',
  );
  String get moonLoadErrorTitle => _t(
    'No s\'han pogut carregar les dades de la lluna.',
    'No se han podido cargar los datos de la luna.',
    'Moon data could not be loaded.',
  );
  String get moonLoadErrorBody => _t(
    'Torna-ho a provar per recalcular la fase i la visibilitat local.',
    'Vuelve a intentarlo para recalcular la fase y la visibilidad local.',
    'Try again to recalculate the phase and local visibility.',
  );
  String get saintsLoading => _t(
    'Buscant el santoral d\'avui...',
    'Buscando el santoral de hoy...',
    'Fetching today\'s saint calendar...',
  );
  String get saintsLoadErrorTitle => _t(
    'No s\'ha pogut carregar el santoral.',
    'No se ha podido cargar el santoral.',
    'The saint calendar could not be loaded.',
  );
  String get saintsLoadErrorBody => _t(
    'Reintenta-ho per recuperar els noms del dia segons la data actual.',
    'Reinténtalo para recuperar los nombres del día según la fecha actual.',
    'Try again to recover today\'s names for the current date.',
  );
  String get fieldWorkLoading => _t(
    'Carregant previsió agrària real...',
    'Cargando previsión agraria real...',
    'Loading live field forecast...',
  );
  String get fieldWorkLoadErrorTitle => _t(
    'No s\'ha pogut carregar la previsió del camp.',
    'No se ha podido cargar la previsión del campo.',
    'The field forecast could not be loaded.',
  );
  String get fieldWorkLoadErrorBody => _t(
    'Torna-ho a provar per obtenir recomanacions basades en meteorologia real.',
    'Vuelve a intentarlo para obtener recomendaciones basadas en meteorología real.',
    'Try again to get recommendations based on live weather.',
  );

  String moonPermissionDeniedLabel() => _t(
    'Activa la ubicació per saber si la lluna es veu des d\'on ets.',
    'Activa la ubicación para saber si la luna se ve desde donde estás.',
    'Enable location to know whether the moon is visible from where you are.',
  );
  String moonPermissionDeniedForeverLabel() => _t(
    'Permet la ubicació als ajustos per calcular la visibilitat local.',
    'Permite la ubicación en los ajustes para calcular la visibilidad local.',
    'Allow location in settings to calculate local visibility.',
  );
  String moonServiceDisabledLabel() => _t(
    'Activa els serveis d\'ubicació per obtenir la visibilitat real.',
    'Activa los servicios de ubicación para obtener la visibilidad real.',
    'Enable location services to get real visibility.',
  );
  String moonLocationUnavailableLabel() => _t(
    'No s\'ha pogut determinar la teva ubicació ara mateix.',
    'No se ha podido determinar tu ubicación en este momento.',
    'Your location could not be determined right now.',
  );
  String moonInsufficientLocationLabel() => _t(
    'No hi ha prou dades per calcular la visibilitat local.',
    'No hay suficientes datos para calcular la visibilidad local.',
    'There is not enough data to calculate local visibility.',
  );
  String moonAtHorizonLabel() => _t(
    'Ara mateix és pràcticament a l\'horitzó.',
    'Ahora mismo está prácticamente en el horizonte.',
    'Right now it is practically on the horizon.',
  );
  String moonAboveHorizonLabel(int degrees) => _t(
    'Ara és a $degrees° sobre l\'horitzó.',
    'Ahora está a $degrees° sobre el horizonte.',
    'It is now $degrees° above the horizon.',
  );
  String moonBelowHorizonLabel(int degrees) => _t(
    'Ara és a $degrees° sota l\'horitzó.',
    'Ahora está a $degrees° bajo el horizonte.',
    'It is now $degrees° below the horizon.',
  );
  String moonSourceWithLocation() => _t(
    'Calculat des de la teva ubicació actual.',
    'Calculado desde tu ubicación actual.',
    'Calculated from your current location.',
  );
  String moonSourceWithoutLocation() => _t(
    'La fase és real, però falta la ubicació per calcular la visibilitat local.',
    'La fase es real, pero falta la ubicación para calcular la visibilidad local.',
    'The phase is real, but location is missing to calculate local visibility.',
  );

  String saintContextNoRegions() => _t(
    'Dades del santoral internacional.',
    'Datos del santoral internacional.',
    'International saint calendar data.',
  );
  String saintContextWithRegions(List<String> regions) {
    final String joined = regions.join(' · ');
    switch (language) {
      case AppLanguage.catala:
        return 'Dades del santoral internacional: $joined.';
      case AppLanguage.castellano:
        return 'Datos del santoral internacional: $joined.';
      case AppLanguage.english:
        return 'International saint calendar data: $joined.';
    }
  }

  String countryLabel(String countryCode) {
    switch (countryCode.toLowerCase()) {
      case 'at':
        return _t('Àustria', 'Austria', 'Austria');
      case 'de':
        return _t('Alemanya', 'Alemania', 'Germany');
      case 'es':
        return _t('Espanya', 'España', 'Spain');
      case 'fr':
        return _t('França', 'Francia', 'France');
      case 'it':
        return _t('Itàlia', 'Italia', 'Italy');
      case 'pl':
        return _t('Polònia', 'Polonia', 'Poland');
      case 'sk':
        return _t('Eslovàquia', 'Eslovaquia', 'Slovakia');
      default:
        return countryCode.toUpperCase();
    }
  }

  String moonPhaseLabel(String canonicalCatalanLabel) {
    switch (canonicalCatalanLabel) {
      case 'Lluna Nova':
        return _t('Lluna Nova', 'Luna nueva', 'New Moon');
      case 'Lluna Creixent':
        return _t('Lluna Creixent', 'Luna creciente', 'Waxing Crescent');
      case 'Quart Creixent':
        return _t('Quart Creixent', 'Cuarto creciente', 'First Quarter');
      case 'Lluna Gibosa Creixent':
        return _t(
          'Lluna Gibosa Creixent',
          'Luna gibosa creciente',
          'Waxing Gibbous',
        );
      case 'Lluna Plena':
        return _t('Lluna Plena', 'Luna llena', 'Full Moon');
      case 'Lluna Gibosa Minvant':
        return _t(
          'Lluna Gibosa Minvant',
          'Luna gibosa menguante',
          'Waning Gibbous',
        );
      case 'Quart Minvant':
        return _t('Quart Minvant', 'Cuarto menguante', 'Last Quarter');
      case 'Lluna Minvant':
        return _t('Lluna Minvant', 'Luna menguante', 'Waning Crescent');
      default:
        return canonicalCatalanLabel;
    }
  }

  String formatHeadlineDate(DateTime date) {
    final String weekday = _weekdayName(date.weekday);
    final String month = _monthName(date.month);

    switch (language) {
      case AppLanguage.catala:
        const String vowels = 'aeiou';
        final String prefix = vowels.contains(month[0].toLowerCase())
            ? 'd\''
            : 'de ';
        return '$weekday, ${date.day}\n$prefix$month';
      case AppLanguage.castellano:
        return '$weekday, ${date.day}\nde $month';
      case AppLanguage.english:
        return '$weekday,\n$month ${date.day}';
    }
  }

  String _weekdayName(int weekday) {
    const List<String> ca = <String>[
      'Dilluns',
      'Dimarts',
      'Dimecres',
      'Dijous',
      'Divendres',
      'Dissabte',
      'Diumenge',
    ];
    const List<String> es = <String>[
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const List<String> en = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return switch (language) {
      AppLanguage.catala => ca[weekday - 1],
      AppLanguage.castellano => es[weekday - 1],
      AppLanguage.english => en[weekday - 1],
    };
  }

  String _monthName(int month) {
    const List<String> ca = <String>[
      'gener',
      'febrer',
      'març',
      'abril',
      'maig',
      'juny',
      'juliol',
      'agost',
      'setembre',
      'octubre',
      'novembre',
      'desembre',
    ];
    const List<String> es = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const List<String> en = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return switch (language) {
      AppLanguage.catala => ca[month - 1],
      AppLanguage.castellano => es[month - 1],
      AppLanguage.english => en[month - 1],
    };
  }

  String _t(String ca, String es, String en) {
    switch (language) {
      case AppLanguage.catala:
        return ca;
      case AppLanguage.castellano:
        return es;
      case AppLanguage.english:
        return en;
    }
  }
}
