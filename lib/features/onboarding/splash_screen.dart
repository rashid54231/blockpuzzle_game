import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/constants/game_constants.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _opacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _animController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(storageServiceProvider);
    final audio = ref.read(audioServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    final playerRepo = ref.read(playerRepositoryProvider);
    final syncService = ref.read(syncServiceProvider);
    final consent = ref.read(consentServiceProvider);
    final notifications = ref.read(notificationServiceProvider);

    await Future.wait([
      audio.init(),
      supabase.init(),
      playerRepo.init(),
      syncService.init(),
      consent.requestConsent(),
      notifications.init(),
    ]);

    // Read stored preferences
    final sfxOn = storage.getBool('pref_sfx') ?? true;
    final musicOn = storage.getBool('pref_music') ?? true;
    final hapticsOn = storage.getBool('pref_haptics') ?? true;
    audio.setSfxEnabled(sfxOn);
    audio.setMusicEnabled(musicOn);
    haptics.setEnabled(hapticsOn);

    if (musicOn) {
      audio.startMusic();
    }

    // Anonymous sign in if configured
    if (supabase.isAvailable && supabase.currentUserId == null) {
      await supabase.signInAnonymously();
    }

    // Delay slightly for splash brand experience
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final hasSeenTutorial = storage.getBool('has_seen_tutorial') ?? false;
    if (!hasSeenTutorial) {
      context.go(AppRoutes.tutorial);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(scale: _scaleAnim.value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withAlpha(120),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(GameConstants.appTitle, style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Pure Logic. Infinite Puzzle.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neonCyan,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
