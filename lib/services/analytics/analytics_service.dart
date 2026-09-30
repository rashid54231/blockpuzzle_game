abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
  Future<void> setUserId(String? userId);
  Future<void> logGameStart({required String mode});
  Future<void> logGameOver({
    required String mode,
    required int score,
    required int moves,
    required int lines,
  });
}

/// No-op default implementation allowing the app to build and run without Firebase/third-party services.
class NoOpAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> logGameStart({required String mode}) async {}

  @override
  Future<void> logGameOver({
    required String mode,
    required int score,
    required int moves,
    required int lines,
  }) async {}
}
