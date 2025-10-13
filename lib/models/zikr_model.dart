// موديل الذكر
class Zikr {
  final String id;
  final String text;
  final int count;
  final String? reference;
  int currentCount;
  bool isCompleted;

  Zikr({
    required this.id,
    required this.text,
    required this.count,
    this.reference,
    this.currentCount = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      'reference': reference,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
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
    );
  }

  Zikr copyWith({
    String? id,
    String? text,
    int? count,
    String? reference,
    int? currentCount,
    bool? isCompleted,
  }) {
    return Zikr(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      reference: reference ?? this.reference,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  void reset() {
    currentCount = 0;
    isCompleted = false;
  }

  void increment() {
    if (currentCount < count) {
      currentCount++;
      if (currentCount == count) {
        isCompleted = true;
      }
    }
  }
}