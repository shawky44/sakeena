// lib/models/hadith_model.dart
class Hadith {
  final int number;
  final String arabicText;
  final String narrator;
  final String explanation;
  final String benefit;
  final List<String> keywords;

  Hadith({
    required this.number,
    required this.arabicText,
    required this.narrator,
    required this.explanation,
    required this.benefit,
    required this.keywords,
  });
}