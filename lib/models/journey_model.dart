// lib/models/journey_model.dart

class JourneyData {
  Map<String, bool> prayersCompleted;
  Map<String, AzkarProgress> azkarProgress;
  int currentStreak;
  int longestStreak;
  DateTime lastUpdateDate;
  List<DayCompletion> weeklyHistory;
  int totalPrayersCompleted;
  int totalAzkarCompleted;

  JourneyData({
    Map<String, bool>? prayersCompleted,
    Map<String, AzkarProgress>? azkarProgress,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastUpdateDate,
    List<DayCompletion>? weeklyHistory,
    this.totalPrayersCompleted = 0,
    this.totalAzkarCompleted = 0,
  })  : prayersCompleted = prayersCompleted ?? _getDefaultPrayers(),
        azkarProgress = azkarProgress ?? _getDefaultAzkar(),
        lastUpdateDate = lastUpdateDate ?? DateTime.now(),
        weeklyHistory = weeklyHistory ?? [];

  static Map<String, bool> _getDefaultPrayers() {
    return {
      'الفجر': false,
      'الظهر': false,
      'العصر': false,
      'المغرب': false,
      'العشاء': false,
    };
  }

  static Map<String, AzkarProgress> _getDefaultAzkar() {
    return {
      'morning': AzkarProgress(name: 'أذكار الصباح', completed: 0, total: 0),
      'evening': AzkarProgress(name: 'أذكار المساء', completed: 0, total: 0),
      'sleep': AzkarProgress(name: 'أذكار النوم', completed: 0, total: 0),
    };
  }

  double get dailyCompletionPercentage {
    int totalTasks = 5;
    int completedTasks = prayersCompleted.values.where((v) => v).length;
    totalTasks += azkarProgress.length;
    completedTasks += azkarProgress.values.where((a) => a.isCompleted).length;
    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }

  double get prayerCompletionPercentage {
    int completed = prayersCompleted.values.where((v) => v).length;
    return completed / 5.0;
  }

  bool get isDayComplete {
    return prayersCompleted.values.every((v) => v) &&
        azkarProgress.values.every((a) => a.isCompleted);
  }

  void resetForNewDay() {
    if (weeklyHistory.length >= 7) {
      weeklyHistory.removeAt(0);
    }
    weeklyHistory.add(DayCompletion(
      date: lastUpdateDate,
      isComplete: isDayComplete,
      prayersCompleted: prayersCompleted.values.where((v) => v).length,
      azkarCompleted: azkarProgress.values.where((a) => a.isCompleted).length,
    ));

    if (isDayComplete) {
      currentStreak++;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      currentStreak = 0;
    }

    prayersCompleted = _getDefaultPrayers();
    azkarProgress.forEach((key, value) {
      value.reset();
    });
    lastUpdateDate = DateTime.now();
  }

  bool needsDailyReset() {
    final now = DateTime.now();
    return now.year != lastUpdateDate.year ||
        now.month != lastUpdateDate.month ||
        now.day != lastUpdateDate.day;
  }

  Map<String, dynamic> toJson() {
    return {
      'prayersCompleted': prayersCompleted,
      'azkarProgress': azkarProgress.map((k, v) => MapEntry(k, v.toJson())),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
      'weeklyHistory': weeklyHistory.map((d) => d.toJson()).toList(),
      'totalPrayersCompleted': totalPrayersCompleted,
      'totalAzkarCompleted': totalAzkarCompleted,
    };
  }

  factory JourneyData.fromJson(Map<String, dynamic> json) {
    return JourneyData(
      prayersCompleted: Map<String, bool>.from(json['prayersCompleted'] ?? {}),
      azkarProgress: (json['azkarProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, AzkarProgress.fromJson(v)),
          ) ??
          _getDefaultAzkar(),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastUpdateDate: json['lastUpdateDate'] != null
          ? DateTime.parse(json['lastUpdateDate'])
          : DateTime.now(),
      weeklyHistory: (json['weeklyHistory'] as List?)
              ?.map((d) => DayCompletion.fromJson(d))
              .toList() ??
          [],
      totalPrayersCompleted: json['totalPrayersCompleted'] ?? 0,
      totalAzkarCompleted: json['totalAzkarCompleted'] ?? 0,
    );
  }
}

class AzkarProgress {
  String name;
  int completed;
  int total;

  AzkarProgress({
    required this.name,
    required this.completed,
    required this.total,
  });

  double get percentage => total > 0 ? completed / total : 0.0;
  bool get isCompleted => total > 0 && completed >= total;

  void reset() {
    completed = 0;
    total = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'completed': completed,
      'total': total,
    };
  }

  factory AzkarProgress.fromJson(Map<String, dynamic> json) {
    return AzkarProgress(
      name: json['name'] ?? '',
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class DayCompletion {
  DateTime date;
  bool isComplete;
  int prayersCompleted;
  int azkarCompleted;

  DayCompletion({
    required this.date,
    required this.isComplete,
    required this.prayersCompleted,
    required this.azkarCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isComplete': isComplete,
      'prayersCompleted': prayersCompleted,
      'azkarCompleted': azkarCompleted,
    };
  }

  factory DayCompletion.fromJson(Map<String, dynamic> json) {
    return DayCompletion(
      date: DateTime.parse(json['date']),
      isComplete: json['isComplete'] ?? false,
      prayersCompleted: json['prayersCompleted'] ?? 0,
      azkarCompleted: json['azkarCompleted'] ?? 0,
    );
  }
}