import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/play/play_screen.dart';
import '../features/daily/daily_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/themes/themes_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tutorial/tutorial_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../core/models/game_mode.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String play = '/play';
  static const String daily = '/daily';
  static const String shop = '/shop';
  static const String themes = '/themes';
  static const String stats = '/stats';
  static const String achievements = '/achievements';
  static const String settings = '/settings';
  static const String tutorial = '/tutorial';
  static const String leaderboard = '/leaderboard';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.play,
      builder: (context, state) {
        final modeStr = state.uri.queryParameters['mode'] ?? 'classic';
        final seedStr = state.uri.queryParameters['seed'];
        final seed = seedStr != null ? int.tryParse(seedStr) : null;
        final mode = GameMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => GameMode.classic,
        );
        return PlayScreen(mode: mode, seed: seed);
      },
    ),
    GoRoute(
      path: AppRoutes.daily,
      builder: (context, state) => const DailyScreen(),
    ),
    GoRoute(
      path: AppRoutes.shop,
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: AppRoutes.themes,
      builder: (context, state) => const ThemesScreen(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.tutorial,
      builder: (context, state) {
        final isInteractive =
            state.uri.queryParameters['interactive'] != 'false';
        return TutorialScreen(isInteractive: isInteractive);
      },
    ),
    GoRoute(
      path: AppRoutes.leaderboard,
      builder: (context, state) => const LeaderboardScreen(),
    ),
  ],
);
