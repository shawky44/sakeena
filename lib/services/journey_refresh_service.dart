// lib/services/journey_refresh_service.dart
// ✅ Singleton stream - أي حاجة في التطبيق تقدر تبعت refresh event

import 'dart:async';

class JourneyRefreshService {
  JourneyRefreshService._();
  static final JourneyRefreshService instance = JourneyRefreshService._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onRefresh => _controller.stream;

  /// استدعي دي بعد أي تغيير في الأذكار أو أي حاجة تانية
  void notifyRefresh() => _controller.add(null);

  void dispose() => _controller.close();
}