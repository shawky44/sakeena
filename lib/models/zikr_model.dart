class Zikr {
  final String id;
  final String text;
  final int count;
  final String? reference;
  int currentCount;
  bool isCompleted;
  DateTime? lastResetDate;
  int position;

  Zikr({
    required this.id,
    required this.text,
    required this.count,
    this.reference,
    this.currentCount = 0,
    this.isCompleted = false,
    this.lastResetDate,
    this.position = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      'reference': reference,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
      'lastResetDate': lastResetDate?.toIso8601String(),
      'position': position,
    };
  }

  factory Zikr.fromJson(Map<String, dynamic> json) {
    return Zikr(
      id: json['id'],
      text: json['text'],
      count: json['count'],
      reference: json['reference'],
      currentCount: json['currentCount'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      lastResetDate: json['lastResetDate'] != null 
          ? DateTime.parse(json['lastResetDate']) 
          : null,
      position: json['position'] ?? 0,
    );
  }

  Zikr copyWith({
    String? id,
    String? text,
    int? count,
    String? reference,
    int? currentCount,
    bool? isCompleted,
    DateTime? lastResetDate,
    int? position,
  }) {
    return Zikr(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      reference: reference ?? this.reference,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      position: position ?? this.position,
    );
  }

  void reset() {
    currentCount = 0;
    isCompleted = false;
    lastResetDate = DateTime.now();
  }

  void increment() {
    if (currentCount < count) {
      currentCount++;
      if (currentCount == count) {
        isCompleted = true;
      }
    }
  }

  bool needsDailyReset() {
    if (lastResetDate == null) return false;
    
    final now = DateTime.now();
    final lastReset = lastResetDate!;
    
    return now.year != lastReset.year ||
           now.month != lastReset.month ||
           now.day != lastReset.day;
  }

  void checkAndResetIfNeeded() {
    if (needsDailyReset()) {
      reset();
    }
  }
}