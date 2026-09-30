import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';

// ─── Step data model ─────────────────────────────────────────────────────────
class _TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final String badge;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.badge,
  });
}

const List<_TutorialStep> _kSteps = [
  _TutorialStep(
    title: 'Drag & Place Blocks',
    description:
        'Pick any of the 3 shapes from your tray and drag them onto the 8×8 grid. Blocks snap into place — find the perfect fit!',
    icon: Icons.pan_tool_alt_rounded,
    accentColor: AppColors.neonCyan,
    gradientColors: [Color(0xFF003A45), Color(0xFF001B22)],
    badge: '01',
  ),
  _TutorialStep(
    title: 'Clear Lines & Score',
    description:
        'Fill a complete row or column to blast it away! Clearing multiple lines in one move triggers a massive score bonus.',
    icon: Icons.view_week_rounded,
    accentColor: AppColors.neonPurple,
    gradientColors: [Color(0xFF2A0045), Color(0xFF120022)],
    badge: '02',
  ),
  _TutorialStep(
    title: 'Build Your Combo',
    description:
        'Clear lines on back-to-back moves to ignite your combo multiplier — stack up to 5× and watch your score skyrocket!',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.neonOrange,
    gradientColors: [Color(0xFF3A1500), Color(0xFF1A0900)],
    badge: '03',
  ),
  _TutorialStep(
    title: 'Daily Challenge',
    description:
        'Every day a new seeded puzzle drops worldwide. Compete against players globally and climb the leaderboard!',
    icon: Icons.emoji_events_rounded,
    accentColor: AppColors.goldCoin,
    gradientColors: [Color(0xFF332400), Color(0xFF1A1200)],
    badge: '04',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class TutorialScreen extends ConsumerStatefulWidget {
  final bool isInteractive;

  const TutorialScreen({super.key, this.isInteractive = true});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentStep = 0;

  // Per-page content animation
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<double> _contentSlide;

  // Icon bounce
  late AnimationController _iconController;
  late Animation<double> _iconBounce;

  // Background glow pulse
  late AnimationController _glowController;
  late Animation<double> _glowPulse;

  // Particle painter
  late AnimationController _particleController;
  final List<_BgParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 25; i++) {
      _particles.add(_BgParticle(rng: _rng));
    }

    _pageController = PageController();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _iconBounce = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    if (index == _currentStep) return;
    _contentController.forward(from: 0.0);
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    HapticFeedback.selectionClick();
  }

  void _next() {
    if (_currentStep < _kSteps.length - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    final storage = ref.read(storageServiceProvider);
    storage.setBool('has_seen_tutorial', true);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final step = _kSteps[_currentStep];
    final isLast = _currentStep == _kSteps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated background ─────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _TutorialBgPainter(
                particles: _particles,
                progress: _particleController.value,
                accentColor: step.accentColor,
              ),
            ),
          ),

          // ── Per-step gradient tint ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  step.gradientColors[0].withAlpha(200),
                  step.gradientColors[1].withAlpha(240),
                  AppColors.background,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Radial glow behind icon ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 0.7,
                    colors: [
                      step.accentColor
                          .withAlpha((35 * _glowPulse.value).round()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main PageView ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SKIP',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      _contentController.forward(from: 0.0);
                      setState(() => _currentStep = i);
                    },
                    itemCount: _kSteps.length,
                    itemBuilder: (_, index) {
                      final s = _kSteps[index];
                      return _StepPage(
                        step: s,
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                        iconBounce: _iconBounce,
                        glowPulse: _glowPulse,
                        isActive: index == _currentStep,
                      );
                    },
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    children: [
                      // Step dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _kSteps.length,
                          (i) => _StepDot(
                            isActive: i == _currentStep,
                            accentColor: _kSteps[i].accentColor,
                            onTap: () => _goToStep(i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA Button
                      _CtaButton(
                        isLast: isLast,
                        accentColor: step.accentColor,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step page
// ─────────────────────────────────────────────────────────────────────────────
class _StepPage extends StatelessWidget {
  final _TutorialStep step;
  final Animation<double> contentFade;
  final Animation<double> contentSlide;
  final Animation<double> iconBounce;
  final Animation<double> glowPulse;
  final bool isActive;

  const _StepPage({
    required this.step,
    required this.contentFade,
    required this.contentSlide,
    required this.iconBounce,
    required this.glowPulse,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Badge number
          AnimatedBuilder(
            animation: contentFade,
            builder: (_, _) => Opacity(
              opacity: contentFade.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: step.accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: step.accentColor.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  step.badge,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: step.accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Animated icon
          AnimatedBuilder(
            animation: Listenable.merge([iconBounce, glowPulse]),
            builder: (_, _) => Transform.translate(
              offset: Offset(0, isActive ? iconBounce.value : 0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      step.accentColor.withAlpha(60),
                      step.accentColor.withAlpha(20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: step.accentColor
                          .withAlpha((80 * glowPulse.value).round()),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.accentColor.withAlpha(25),
                      border: Border.all(
                        color: step.accentColor.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      size: 44,
                      color: step.accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          AnimatedBuilder(
            animation: contentFade,
            builder: (_, _) => Opacity(
              opacity: contentFade.value,
              child: Transform.translate(
                offset: Offset(0, contentSlide.value),
                child: Text(
                  step.title,
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          AnimatedBuilder(
            animation: contentFade,
            builder: (_, _) => Opacity(
              opacity: contentFade.value * 0.85,
              child: Transform.translate(
                offset: Offset(0, contentSlide.value * 1.3),
                child: Text(
                  step.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.65,
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider accent
          AnimatedBuilder(
            animation: contentFade,
            builder: (_, _) => Opacity(
              opacity: contentFade.value * 0.5,
              child: Container(
                width: 48,
                height: 2,
                decoration: BoxDecoration(
                  color: step.accentColor,
                  borderRadius: BorderRadius.circular(1),
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
// Step dot indicator
// ─────────────────────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _StepDot({
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 28 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.white12,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(120),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA button
// ─────────────────────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  final bool isLast;
  final Color accentColor;
  final VoidCallback onPressed;

  const _CtaButton({
    required this.isLast,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLast
                  ? [widget.accentColor, widget.accentColor.withAlpha(200)]
                  : [widget.accentColor.withAlpha(240), AppColors.neonPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isLast ? 'START PLAYING' : 'NEXT',
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: 15,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.isLast
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background particle painter
// ─────────────────────────────────────────────────────────────────────────────
class _BgParticle {
  late double x, y, speed, size, opacity, drift;
  late Color color;

  _BgParticle({required math.Random rng}) {
    _init(rng, randomY: true);
  }

  void _init(math.Random rng, {bool randomY = false}) {
    x = rng.nextDouble();
    y = randomY ? rng.nextDouble() : 1.1;
    speed = 0.025 + rng.nextDouble() * 0.04;
    size = 1.0 + rng.nextDouble() * 2.5;
    opacity = 0.08 + rng.nextDouble() * 0.3;
    drift = -0.05 + rng.nextDouble() * 0.1;
    const colors = [
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonBlue,
      AppColors.neonPink,
      AppColors.neonOrange,
    ];
    color = colors[rng.nextInt(colors.length)];
  }

  void update(math.Random rng) {
    y -= speed * 0.012;
    x += drift * 0.002;
    if (y < -0.05) _init(rng);
  }
}

class _TutorialBgPainter extends CustomPainter {
  final List<_BgParticle> particles;
  final double progress;
  final Color accentColor;
  final math.Random _rng = math.Random(77);

  _TutorialBgPainter({
    required this.particles,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid
    final gridPaint = Paint()
      ..color = const Color(0xFF161B2E)
      ..strokeWidth = 0.4;
    const cellSize = 36.0;
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

    // Particles
    for (final p in particles) {
      p.update(_rng);
      final paint = Paint()
        ..color = p.color.withAlpha((p.opacity * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TutorialBgPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

