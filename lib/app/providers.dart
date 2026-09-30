import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage/storage_service.dart';
import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/ads/ads_service.dart';
import '../services/iap/iap_service.dart';
import '../services/consent/consent_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/supabase/supabase_service.dart';
import '../services/sync/sync_service.dart';
import '../shared/theme/game_theme.dart';
import '../data/repositories/player_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesStorageService(prefs);
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AppAudioService();
  ref.onDispose(service.dispose);
  return service;
});

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return AppHapticsService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return NoOpAnalyticsService();
});

final adsServiceProvider = Provider<AdsService>((ref) {
  return MockAdsService();
});

final iapServiceProvider = Provider<IapService>((ref) {
  final service = MockIapService();
  ref.onDispose(service.dispose);
  return service;
});

final consentServiceProvider = Provider<ConsentService>((ref) {
  return AppConsentService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return AppNotificationService();
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return AppSupabaseService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return SyncService(storage, supabase);
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return PlayerRepository(storage, supabase, syncService);
});

class CurrentThemeNotifier extends Notifier<GameThemeId> {
  @override
  GameThemeId build() => GameThemeId.neon;

  void setTheme(GameThemeId themeId) {
    state = themeId;
  }
}

final currentThemeIdProvider =
    NotifierProvider<CurrentThemeNotifier, GameThemeId>(
      CurrentThemeNotifier.new,
    );

final currentThemeProvider = Provider<GameThemeData>((ref) {
  final id = ref.watch(currentThemeIdProvider);
  return GameThemes.fromId(id.name);
});

class ColorblindModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getBool('pref_colorblind_mode') ?? false;
  }

  void setMode(bool enabled) {
    state = enabled;
  }
}

final colorblindModeProvider = NotifierProvider<ColorblindModeNotifier, bool>(
  ColorblindModeNotifier.new,
);
