class SaintEntry {
  const SaintEntry({
    required this.title,
    required this.countryCode,
    required this.sourceLabel,
  });

  final String title;
  final String countryCode;
  final String sourceLabel;

  factory SaintEntry.fromJson(Map<String, dynamic> json) {
    final Object? title = json['title'];
    final Object? countryCode = json['countryCode'];
    final Object? sourceLabel = json['sourceLabel'];

    if (title is! String || countryCode is! String || sourceLabel is! String) {
      throw const FormatException('Entrada de santoral no vàlida.');
    }

    return SaintEntry(
      title: title,
      countryCode: countryCode,
      sourceLabel: sourceLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'countryCode': countryCode,
      'sourceLabel': sourceLabel,
    };
  }
}

class SaintData {
  const SaintData({
    required this.generatedAt,
    required this.headline,
    required this.entries,
  });

  final DateTime generatedAt;
  final String headline;
  final List<SaintEntry> entries;

  factory SaintData.fromJson(Map<String, dynamic> json) {
    final Object? generatedAt = json['generatedAt'];
    final Object? headline = json['headline'];
    final Object? entries = json['entries'];

    if (generatedAt is! String || headline is! String || entries is! List) {
      throw const FormatException(
        'Dades de santoral en memòria cau no vàlides.',
      );
    }

    return SaintData(
      generatedAt: DateTime.parse(generatedAt),
      headline: headline,
      entries: entries
          .map(
            (entry) => SaintEntry.fromJson(
              Map<String, dynamic>.from(entry as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'headline': headline,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  String get contextLabel {
    if (entries.isEmpty) {
      return 'Dades del santoral internacional.';
    }

    final String regions = entries
        .map((entry) => entry.sourceLabel)
        .join(' · ');

    return 'Dades del santoral internacional: $regions.';
  }
}
