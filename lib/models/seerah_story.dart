// lib/models/seerah_story.dart
class SeerahStory {
  final int id;
  final String title;
  final String subtitle;
  final String category; 
  final String location;
  final int readingMinutes;
  final List<String> storyParagraphs;
  final List<String> lessons;
  final String practicalApplication;
  final SeerahQuestion question;
  final List<String> relatedStories;
  final String emoji;

  SeerahStory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.location,
    required this.readingMinutes,
    required this.storyParagraphs,
    required this.lessons,
    required this.practicalApplication,
    required this.question,
    required this.relatedStories,
    required this.emoji,
  });
}

class SeerahQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  SeerahQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}