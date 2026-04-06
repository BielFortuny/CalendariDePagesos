class FieldWorkTask {
  const FieldWorkTask({required this.title, required this.description});

  final String title;
  final String description;

  factory FieldWorkTask.fromJson(Map<String, dynamic> json) {
    final Object? title = json['title'];
    final Object? description = json['description'];

    if (title is! String || description is! String) {
      throw const FormatException('Feina del camp no valida.');
    }

    return FieldWorkTask(title: title, description: description);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'description': description};
  }
}

class FieldWorkData {
  const FieldWorkData({
    required this.generatedAt,
    required this.weatherSummary,
    required this.lunarSummary,
    required this.sourceLabel,
    required this.tasks,
    required this.proverb,
    this.languageCode = 'ca',
  });

  final DateTime generatedAt;
  final String weatherSummary;
  final String lunarSummary;
  final String sourceLabel;
  final List<FieldWorkTask> tasks;
  final String proverb;
  final String languageCode;

  factory FieldWorkData.fromJson(Map<String, dynamic> json) {
    final Object? generatedAt = json['generatedAt'];
    final Object? weatherSummary = json['weatherSummary'];
    final Object? lunarSummary = json['lunarSummary'];
    final Object? sourceLabel = json['sourceLabel'];
    final Object? tasks = json['tasks'];
    final Object? proverb = json['proverb'];
    final Object? languageCode = json['languageCode'];

    if (generatedAt is! String ||
        weatherSummary is! String ||
        lunarSummary is! String ||
        sourceLabel is! String ||
        tasks is! List ||
        proverb is! String) {
      throw const FormatException('Dades de feines del camp no valides.');
    }

    return FieldWorkData(
      generatedAt: DateTime.parse(generatedAt),
      weatherSummary: weatherSummary,
      lunarSummary: lunarSummary,
      sourceLabel: sourceLabel,
      tasks: tasks
          .map(
            (entry) => FieldWorkTask.fromJson(
              Map<String, dynamic>.from(entry as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false),
      proverb: proverb,
      languageCode: languageCode is String && languageCode.isNotEmpty
          ? languageCode
          : 'ca',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'weatherSummary': weatherSummary,
      'lunarSummary': lunarSummary,
      'sourceLabel': sourceLabel,
      'tasks': tasks.map((entry) => entry.toJson()).toList(growable: false),
      'proverb': proverb,
      'languageCode': languageCode,
    };
  }
}
