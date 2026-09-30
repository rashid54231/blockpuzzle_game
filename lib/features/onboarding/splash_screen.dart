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
  // ── Staggered entry
  late final AnimationController _entryController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loadingOpacity;

  // ── Glow pulse
  late final AnimationController _glowController;
  late final Animation<double> _glowPulse;

  // ── Floating particles
  late final AnimationController _particleController;

  // ── Grid shimmer sweep
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  // ── Progress bar
  late final AnimationController _progressController;
  late final Animation<double> _progressAnim;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(rng: _rng));
    }

    // ── Entry (staggered)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.80, curve: Curves.easeOut),
      ),
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // ── Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ── Shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // ── Progress
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _progressController.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _particleController.dispose();
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

    // Minimum brand display time
    await Future.delayed(const Duration(milliseconds: 2400));

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated grid background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, _) => CustomPaint(
                painter: _GridPainter(shimmer: _shimmerAnim.value),
              ),
            ),
          ),

          // ── Floating neon particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, _) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  canvasSize: size,
                ),
              ),
            ),
          ),

          // ── Radial ambient glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.85,
                    colors: [
                      AppColors.neonCyan
                          .withAlpha((22 * _glowPulse.value).round()),
                      AppColors.neonPurple
                          .withAlpha((14 * _glowPulse.value).round()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content
          Center(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (_, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _LogoWidget(glowPulse: _glowPulse),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  Opacity(
                    opacity: _titleOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.neonCyan,
                            Colors.white,
                            AppColors.neonPurple,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          GameConstants.appTitle,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tagline with flanking lines
                  Opacity(
                    opacity: _taglineOpacity.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
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
                        Text(
                          'Pure Logic. Infinite Puzzle.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neonCyan,
                            letterSpacing: 1.8,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.neonCyan.withAlpha(180),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Progress bar + label
                  Opacity(
                    opacity: _loadingOpacity.value,
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, _) => FractionallySizedBox(
                              widthFactor: _progressAnim.value,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.neonCyan,
                                      AppColors.neonPurple,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonCyan.withAlpha(180),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Initializing…',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 1.4,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Version badge
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _loadingOpacity,
              builder: (_, _) => Opacity(
                opacity: _loadingOpacity.value,
                child: const Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Color(0xFF3A4460),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
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
// Logo with inner grid + glow
// ─────────────────────────────────────────────────────────────────────────────
class _LogoWidget extends StatelessWidget {
  final Animation<double> glowPulse;
  const _LogoWidget({required this.glowPulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowPulse,
      builder: (_, _) => Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.neonCyan, AppColors.neonPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan
                  .withAlpha((145 * glowPulse.value).round()),
              blurRadius: 44,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: AppColors.neonPurple
                  .withAlpha((80 * glowPulse.value).round()),
              blurRadius: 64,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle inner grid
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                size: const Size(112, 112),
                painter: _LogoGridPainter(),
              ),
            ),
            // Highlight overlay
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(30),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const Icon(Icons.grid_view_rounded, size: 60, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double shimmer;
  _GridPainter({required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1A2035)
      ..strokeWidth = 0.5;

    const cellSize = 40.0;
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(c * cellSize, 0),
        Offset(c * cellSize, size.height),
        linePaint,
      );
    }
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellSize),
        Offset(size.width, r * cellSize),
        linePaint,
      );
    }

    // Diagonal shimmer sweep
    final sweepRect = Rect.fromLTWH(
      shimmer * size.width - size.width * 0.3,
      0,
      size.width * 0.6,
      size.height,
    );
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.neonCyan.withAlpha(18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(sweepRect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmerPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.shimmer != shimmer;
}

class _LogoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(28)
      ..strokeWidth = 1.0;

    const cells = 4;
    final cellSize = size.width / cells;
    for (int i = 1; i < cells; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 8),
        Offset(i * cellSize, size.height - 8),
        paint,
      );
      canvas.drawLine(
        Offset(8, i * cellSize),
        Offset(size.width - 8, i * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoGridPainter _) => false;
}

class _Particle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;
  late Color color;
  late double drift;

  _Particle({required math.Random rng}) {
    _init(rng, randomY: true);
  }

  void _init(math.Random rng, {bool randomY = false}) {
    x = rng.nextDouble();
    y = randomY ? rng.nextDouble() : 1.1;
    speed = 0.03 + rng.nextDouble() * 0.05;
    size = 1.5 + rng.nextDouble() * 3.0;
    opacity = 0.15 + rng.nextDouble() * 0.45;
    drift = -0.08 + rng.nextDouble() * 0.16;
    const colors = [
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonBlue,
      AppColors.neonPink,
    ];
    color = colors[rng.nextInt(colors.length)];
  }

  void update(math.Random rng) {
    y -= speed * 0.015;
    x += drift * 0.003;
    if (y < -0.05) _init(rng);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Size canvasSize;
  final math.Random _rng = math.Random(99);

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.update(_rng);
      final paint = Paint()
        ..color = p.color.withAlpha((p.opacity * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
