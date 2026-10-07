import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  // ── Entrance animations
  late final AnimationController _entryController;
  late final Animation<double> _emblemScale;
  late final Animation<double> _emblemOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loadingOpacity;

  // ── Ambient levitation & orbital loop
  late final AnimationController _floatController;
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // ── Shimmer & light sweep
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  // ── Progress & dynamic loading status
  late final AnimationController _progressController;
  late final Animation<double> _progressAnim;

  final List<_CosmicStar> _stars = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate cosmic ambient star particles
    for (int i = 0; i < 28; i++) {
      _stars.add(_CosmicStar(rng: _rng));
    }

    // ── Staggered entrance
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _emblemScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _emblemOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 32.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Floating levitation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // ── Orbital rotation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // ── Radiant pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // ── Light sweep shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // ── Progress progression
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _entryController.forward();
    _progressController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
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

    final sfxOn = storage.getBool('pref_sfx') ?? true;
    final musicOn = storage.getBool('pref_music') ?? true;
    final hapticsOn = storage.getBool('pref_haptics') ?? true;
    audio.setSfxEnabled(sfxOn);
    audio.setMusicEnabled(musicOn);
    haptics.setEnabled(hapticsOn);

    if (musicOn) {
      audio.startMusic();
    }

    if (supabase.isAvailable && supabase.currentUserId == null) {
      await supabase.signInAnonymously();
    }

    // Minimum display time for seamless cinematic impression
    await Future.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;

    final hasSeenTutorial = storage.getBool('has_seen_tutorial') ?? false;
    if (!hasSeenTutorial) {
      context.go(AppRoutes.tutorial);
    } else {
      context.go(AppRoutes.home);
    }
  }

  String _getLoadingStatus(double progress) {
    if (progress < 0.28) return 'Polishing Jewel Prisms…';
    if (progress < 0.62) return 'Harmonizing Core Engine…';
    if (progress < 0.90) return 'Preparing Endless Grid…';
    return 'Ready to Play!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B17),
      body: Stack(
        children: [
          // ── 1. Cosmic Aurora Gradient Backdrop ─────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF141A38),
                    Color(0xFF0D1124),
                    Color(0xFF070913),
                  ],
                ),
              ),
            ),
          ),

          // ── 2. Subtle High-Tech Grid Floor ─────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, _) => CustomPaint(
                painter: _CosmicGridPainter(shimmer: _shimmerAnim.value),
              ),
            ),
          ),

          // ── 3. Drifting Ambient Prismatic Particles ────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbitController,
              builder: (_, _) => CustomPaint(
                painter: _CosmicStarsPainter(
                  stars: _stars,
                  progress: _orbitController.value,
                ),
              ),
            ),
          ),

          // ── 4. Central Radiant Energy Bloom ────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => Center(
                child: Container(
                  width: 320,
                  height: 320,
                  transform: Matrix4.translationValues(0, -50, 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonCyan.withAlpha(
                          (35 * _pulseAnim.value).round(),
                        ),
                        AppColors.neonPurple.withAlpha(
                          (22 * _pulseAnim.value).round(),
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Main Hero Content ───────────────────────────────────────────
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ── Hero 3D Jewel Emblem + Halo ────────────────────────
                    Opacity(
                      opacity: _emblemOpacity.value,
                      child: Transform.scale(
                        scale: _emblemScale.value,
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            final floatY =
                                math.sin(_floatController.value * math.pi) * 8.0;
                            return Transform.translate(
                              offset: Offset(0, -floatY),
                              child: child,
                            );
                          },
                          child: _HeroPrismEmblem(
                            orbitAnimation: _orbitController,
                            pulseAnimation: _pulseAnim,
                            shimmerAnimation: _shimmerAnim,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 34),

                    // ── Game Title ("PRISM BLOCKS") ────────────────────────
                    Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  const Color(0xFF00E5FF),
                                  const Color(0xFFD500F9),
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.35, 0.75, 1.0],
                                begin: Alignment(
                                  -1.5 + _shimmerAnim.value * 2.5,
                                  0,
                                ),
                                end: Alignment(
                                  -0.5 + _shimmerAnim.value * 2.5,
                                  0,
                                ),
                              ).createShader(bounds),
                              child: Text(
                                GameConstants.appTitle,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.displayLarge.copyWith(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.neonCyan.withAlpha(160),
                                      blurRadius: 28,
                                      offset: const Offset(0, 4),
                                    ),
                                    Shadow(
                                      color: AppColors.neonPurple.withAlpha(120),
                                      blurRadius: 40,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Tagline with Jewel Divider Accents ─────────────────
                    Opacity(
                      opacity: _taglineOpacity.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.neonCyan.withAlpha(180),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonCyan,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonCyan.withAlpha(200),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PURE LOGIC • INFINITE PUZZLE',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFFB0C4DE),
                              letterSpacing: 2.4,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonPurple,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonPurple.withAlpha(200),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 32,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.neonPurple.withAlpha(180),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Sleek Glassmorphic Loading Capsule ─────────────────
                    Opacity(
                      opacity: _loadingOpacity.value,
                      child: AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (context, _) {
                          final currentProgress = _progressAnim.value;
                          final percentInt = (currentProgress * 100).toInt();

                          return Column(
                            children: [
                              Container(
                                width: 220,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1426).withAlpha(200),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(120),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: AppColors.neonCyan.withAlpha(
                                        (20 * currentProgress).round(),
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Progress bar groove
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF182036),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Stack(
                                        children: [
                                          FractionallySizedBox(
                                            widthFactor: currentProgress.clamp(
                                              0.02,
                                              1.0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF00E5FF),
                                                    Color(0xFF7C4DFF),
                                                    Color(0xFFFF007F),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.neonCyan
                                                        .withAlpha(180),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getLoadingStatus(currentProgress),
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '$percentInt%',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.neonCyan,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const Spacer(flex: 1),

                    // ── Refined Engine / Version Footer ────────────────────
                    Opacity(
                      opacity: _loadingOpacity.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(14),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: AppColors.neonGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'FLAME 60 FPS • v1.0.0',
                              style: TextStyle(
                                color: Colors.white.withAlpha(140),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero 3D Prismatic Emblem with Orbital Celestial Halo
// ─────────────────────────────────────────────────────────────────────────────

class _HeroPrismEmblem extends StatelessWidget {
  final Animation<double> orbitAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> shimmerAnimation;

  const _HeroPrismEmblem({
    required this.orbitAnimation,
    required this.pulseAnimation,
    required this.shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── 1. Orbital Aura Halo with Satellite Nodes ──────────────────────
          AnimatedBuilder(
            animation: orbitAnimation,
            builder: (context, _) => CustomPaint(
              size: const Size(180, 180),
              painter: _OrbitalHaloPainter(
                angle: orbitAnimation.value * 2 * math.pi,
                glowFactor: pulseAnimation.value,
              ),
            ),
          ),

          // ── 2. Radiant Outer Prism Glow ────────────────────────────────────
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, _) => Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withAlpha(
                      (120 * pulseAnimation.value).round(),
                    ),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: AppColors.neonPurple.withAlpha(
                      (90 * pulseAnimation.value).round(),
                    ),
                    blurRadius: 55,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Main 3D Jewel Block Cluster Emblem ──────────────────────────
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141933), Color(0xFF0C0F22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withAlpha(60),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: CustomPaint(
              size: const Size(100, 100),
              painter: _PrismJewelClusterPainter(
                shimmerProgress: shimmerAnimation.value,
              ),
            ),
          ),

          // ── 4. Prismatic Glass Highlight Sheen ─────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(45),
                    Colors.white.withAlpha(10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for Splendid AAA Visuals
// ─────────────────────────────────────────────────────────────────────────────

/// Custom painter that renders a cluster of 3D jewel blocks in vibrant prism colors
class _PrismJewelClusterPainter extends CustomPainter {
  final double shimmerProgress;

  _PrismJewelClusterPainter({required this.shimmerProgress});

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 3;
    final cellSize = (size.width - 8) / cols;
    const padding = 3.0;

    // Palette for 3x3 prism cluster
    final colors = [
      const Color(0xFF00E5FF), // Cyan Top-Left
      const Color(0xFF7C4DFF), // Purple Top-Center
      const Color(0xFFFF007F), // Magenta Top-Right
      const Color(0xFF00E676), // Green Mid-Left
      const Color(0xFFFFD600), // Gold Center Jewel
      const Color(0xFF00E5FF), // Cyan Mid-Right
      const Color(0xFFFF007F), // Magenta Bottom-Left
      const Color(0xFF00E676), // Green Bottom-Center
      const Color(0xFF7C4DFF), // Purple Bottom-Right
    ];

    for (int y = 0; y < cols; y++) {
      for (int x = 0; x < cols; x++) {
        final index = y * cols + x;
        final rect = Rect.fromLTWH(
          4 + (x * cellSize) + padding,
          4 + (y * cellSize) + padding,
          cellSize - (padding * 2),
          cellSize - (padding * 2),
        );

        final baseColor = colors[index];
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(rect.width * 0.28),
        );

        // Ambient block shadow
        final shadowPaint = Paint()
          ..color = Colors.black.withAlpha(80)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawRRect(rrect.shift(const Offset(0, 1.8)), shadowPaint);

        // Jewel gradient fill
        final hsl = HSLColor.fromColor(baseColor);
        final lightColor = hsl
            .withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0))
            .toColor();
        final darkColor = hsl
            .withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0))
            .toColor();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            colors: [lightColor, baseColor, darkColor],
            stops: const [0.0, 0.45, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect);
        canvas.drawRRect(rrect, fillPaint);

        // 3D Bevel highlight stroke
        final bevelRect = rect.deflate(rect.width * 0.12);
        final bevelPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.width * 0.08
          ..color = Colors.white.withAlpha(120);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bevelRect, Radius.circular(rect.width * 0.18)),
          bevelPaint,
        );

        // Specular gleam dot (top-left)
        final gleamRect = Rect.fromLTWH(
          rect.left + rect.width * 0.2,
          rect.top + rect.height * 0.18,
          rect.width * 0.28,
          rect.height * 0.22,
        );
        final gleamPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withAlpha(220),
              Colors.white.withAlpha(0),
            ],
          ).createShader(gleamRect);
        canvas.drawOval(gleamRect, gleamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PrismJewelClusterPainter old) =>
      old.shimmerProgress != shimmerProgress;
}

/// Orbital cosmic halo with rotating satellite gem orbs
class _OrbitalHaloPainter extends CustomPainter {
  final double angle;
  final double glowFactor;

  _OrbitalHaloPainter({required this.angle, required this.glowFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;

    // Glowing orbital ring path
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = SweepGradient(
        colors: [
          AppColors.neonCyan.withAlpha(180),
          AppColors.neonPurple.withAlpha(180),
          AppColors.neonPink.withAlpha(180),
          AppColors.neonCyan.withAlpha(180),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, ringPaint);

    // Orbiting jewel satellite nodes
    const satellites = 4;
    for (int i = 0; i < satellites; i++) {
      final satelliteAngle = angle + (i * (math.pi / 2));
      final sx = center.dx + radius * math.cos(satelliteAngle);
      final sy = center.dy + radius * math.sin(satelliteAngle);

      final beadColor = i % 2 == 0 ? AppColors.neonCyan : AppColors.neonPink;

      // Glow aura
      final auraPaint = Paint()
        ..color = beadColor.withAlpha((180 * glowFactor).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(sx, sy), 4.5, auraPaint);

      // Core bead
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(sx, sy), 2.2, corePaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitalHaloPainter old) =>
      old.angle != angle || old.glowFactor != glowFactor;
}

/// Perspective geometric cosmic grid floor with light shimmer
class _CosmicGridPainter extends CustomPainter {
  final double shimmer;

  _CosmicGridPainter({required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF131830).withAlpha(110)
      ..strokeWidth = 0.6;

    const cellSize = 44.0;
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(c * cellSize, 0),
        Offset(c * cellSize, size.height),
        gridPaint,
      );
    }
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellSize),
        Offset(size.width, r * cellSize),
        gridPaint,
      );
    }

    // Dynamic diagonal light wave
    final waveRect = Rect.fromLTWH(
      shimmer * size.width - size.width * 0.35,
      0,
      size.width * 0.7,
      size.height,
    );
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.neonCyan.withAlpha(16),
          AppColors.neonPurple.withAlpha(12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
      ).createShader(waveRect);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wavePaint);
  }

  @override
  bool shouldRepaint(_CosmicGridPainter old) => old.shimmer != shimmer;
}

/// Gentle drifting stardust particles
class _CosmicStar {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;
  late Color color;
  late double drift;

  _CosmicStar({required math.Random rng}) {
    _init(rng, randomY: true);
  }

  void _init(math.Random rng, {bool randomY = false}) {
    x = rng.nextDouble();
    y = randomY ? rng.nextDouble() : 1.08;
    speed = 0.025 + rng.nextDouble() * 0.045;
    size = 1.2 + rng.nextDouble() * 2.8;
    opacity = 0.20 + rng.nextDouble() * 0.55;
    drift = -0.06 + rng.nextDouble() * 0.12;

    const colors = [
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonBlue,
      AppColors.neonPink,
      Colors.white,
    ];
    color = colors[rng.nextInt(colors.length)];
  }

  void update(math.Random rng) {
    y -= speed * 0.015;
    x += drift * 0.003;
    if (y < -0.05) _init(rng);
  }
}

class _CosmicStarsPainter extends CustomPainter {
  final List<_CosmicStar> stars;
  final double progress;
  final math.Random _rng = math.Random(1337);

  _CosmicStarsPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      star.update(_rng);
      final paint = Paint()
        ..color = star.color.withAlpha((star.opacity * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CosmicStarsPainter old) => old.progress != progress;
}
