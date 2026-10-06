import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/constants/game_constants.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import 'daily_reward_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Ambient background grid animation
  late final AnimationController _ambientController;
  // Title glow pulse
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;
  // Buttons entrance
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceFade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      _checkDailyLoginReward();
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _checkDailyLoginReward() {
    final playerRepo = ref.read(playerRepositoryProvider);
    final audio = ref.read(audioServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final progress = playerRepo.current;

    final nowUtc = DateTime.now().toUtc();
    final todayStr =
        '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}';

    if (progress.lastLoginDate == todayStr) return;

    int newStreak = 1;
    int nextDayIndex = 1;

    if (progress.lastLoginDate != null) {
      final lastDate = DateTime.tryParse(progress.lastLoginDate!);
      if (lastDate != null) {
        final diffDays = nowUtc.difference(lastDate).inDays;
        if (diffDays == 1) {
          newStreak = progress.streakCount + 1;
          nextDayIndex = (progress.dailyDayIndex % 7) + 1;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DailyRewardDialog(
        currentDayIndex: nextDayIndex,
        onClaim: () async {
          Navigator.pop(ctx);
          final reward = DailyRewardCalendar.rewards[nextDayIndex - 1];
          await playerRepo.addCoins(reward.coins);
          if (reward.gems > 0) await playerRepo.addGems(reward.gems);
          final updatedProgress = playerRepo.current.copyWith(
            lastLoginDate: todayStr,
            streakCount: newStreak,
            dailyDayIndex: nextDayIndex,
          );
          await playerRepo.save(updatedProgress);
          syncService.enqueue('daily_reward', {
            'claim_date': todayStr,
            'day_index': nextDayIndex,
            'reward_json': {'coins': reward.coins, 'gems': reward.gems},
          });
          audio.playSfx('reward_claim');
          haptics.success();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final progress = playerRepo.current;
    final currentTheme = ref.watch(currentThemeProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated ambient background ──────────────────────────
          _AmbientBackground(controller: _ambientController, size: size),

          // ── Main content ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(gradient: currentTheme.backgroundGradient),
            child: SafeArea(
              child: FadeTransition(
                opacity: _entranceFade,
                child: SlideTransition(
                  position: _entranceSlide,
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(progress),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),

                              // Hero title + score banner
                              _buildHeroBanner(progress, _glowAnim),

                              const SizedBox(height: 24),

                              // ── PLAY CLASSIC — Hero Button ──────
                              _buildPlayClassicButton(),

                              const SizedBox(height: 14),

                              // ── Mode cards row ──────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _ModeCard(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6D00), Color(0xFFFF1744)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      icon: Icons.calendar_month_rounded,
                                      title: 'DAILY',
                                      subtitle: 'Challenge',
                                      badgeText: 'NEW',
                                      onTap: () => context.push(AppRoutes.daily),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ModeCard(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      icon: Icons.spa_rounded,
                                      title: 'ZEN',
                                      subtitle: 'Relaxed',
                                      onTap: () => context.push(
                                        '${AppRoutes.play}?mode=zen',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // ── Quick Stats ─────────────────────
                              _buildQuickStats(progress),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom Nav ───────────────────────────────
                      _buildBottomNav(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(dynamic progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
      child: Row(
        children: [
          // Logo + title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_4x4_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                GameConstants.appTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Coins chip
          _CurrencyChip(
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.goldCoin,
            value: '${progress.coins}',
          ),
          const SizedBox(width: 6),

          // Gems chip
          _CurrencyChip(
            icon: Icons.diamond_rounded,
            iconColor: AppColors.neonCyan,
            value: '${progress.gems}',
          ),
          const SizedBox(width: 2),

          // Settings
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(dynamic progress, Animation<double> glowAnim) {
    final hasScore = progress.bestClassicScore > 0;

    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color.lerp(
              AppColors.glassBorder,
              AppColors.neonCyan.withAlpha(100),
              glowAnim.value,
            )!,
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1F38),
              const Color(0xFF0F1226),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withAlpha(
                (20 + glowAnim.value * 30).toInt(),
              ),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        children: [
          // Trophy + score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST SCORE',
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 2.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                hasScore
                    ? ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          '${progress.bestClassicScore}',
                          style: AppTextStyles.scoreLarge.copyWith(
                            color: Colors.white,
                            fontSize: 44,
                          ),
                        ),
                      )
                    : Text(
                        'Play your first game!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
              ],
            ),
          ),

          // Right side decorations
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Trophy icon with glow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D2B00), Color(0xFF1A1200)],
                  ),
                  border: Border.all(
                    color: AppColors.goldCoin.withAlpha(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldCoin.withAlpha(60),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.goldCoin,
                  size: 28,
                ),
              ),

              const SizedBox(height: 10),

              // Streak badge
              if (progress.streakCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.fireStreakGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonOrange.withAlpha(100),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${progress.streakCount}d streak',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayClassicButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withAlpha(
                (60 + _glowAnim.value * 80).toInt(),
              ),
              blurRadius: 24 + _glowAnim.value * 12,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppColors.neonPurple.withAlpha(40),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => context.push('${AppRoutes.play}?mode=classic'),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF7B00FF),
                Color(0xFFFF007F),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) => ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha(30),
                        Colors.white.withAlpha(0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(
                        -1.5 + _ambientController.value * 4,
                        -0.5,
                      ),
                      end: Alignment(
                        -0.5 + _ambientController.value * 4,
                        0.5,
                      ),
                    ).createShader(bounds),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PLAY CLASSIC',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 18,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          const Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(dynamic progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'YOUR STATS',
            style: AppTextStyles.bodySmall.copyWith(
              letterSpacing: 2.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickStatTile(
                icon: Icons.swap_vert_rounded,
                label: 'Total Lines',
                value: '${progress.totalLines}',
                color: AppColors.neonGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickStatTile(
                icon: Icons.gamepad_rounded,
                label: 'Games',
                value: '${progress.totalGames}',
                color: AppColors.neonBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickStatTile(
                icon: Icons.bolt_rounded,
                label: 'Best Combo',
                value: '${progress.bestCombo}x',
                color: AppColors.neonYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10152A),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.palette_rounded,
            label: 'Themes',
            onTap: () => context.push(AppRoutes.themes),
          ),
          _BottomNavItem(
            icon: Icons.storefront_rounded,
            label: 'Shop',
            onTap: () => context.push(AppRoutes.shop),
          ),
          _BottomNavItem(
            icon: Icons.leaderboard_rounded,
            label: 'Ranks',
            onTap: () => context.push(AppRoutes.leaderboard),
          ),
          _BottomNavItem(
            icon: Icons.military_tech_rounded,
            label: 'Badges',
            onTap: () => context.push(AppRoutes.achievements),
          ),
          _BottomNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            onTap: () => context.push(AppRoutes.stats),
          ),
        ],
      ),
    );
  }
}

// ── Ambient Background Painter ────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AmbientBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: size,
        painter: _AmbientPainter(controller.value),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double t;
  _AmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Slowly drifting orbs
    final orbs = [
      _OrbData(
        cx: size.width * (0.15 + 0.1 * math.sin(t * 2 * math.pi)),
        cy: size.height * (0.12 + 0.05 * math.cos(t * 2 * math.pi)),
        radius: size.width * 0.38,
        color: const Color(0xFF00E5FF).withAlpha(18),
      ),
      _OrbData(
        cx: size.width * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 1.2)),
        cy: size.height * (0.35 + 0.08 * math.sin(t * 2 * math.pi + 1.2)),
        radius: size.width * 0.42,
        color: const Color(0xFFB300FF).withAlpha(14),
      ),
      _OrbData(
        cx: size.width * (0.5 + 0.12 * math.sin(t * 2 * math.pi + 2.4)),
        cy: size.height * (0.80 + 0.06 * math.cos(t * 2 * math.pi + 2.4)),
        radius: size.width * 0.45,
        color: const Color(0xFF00E676).withAlpha(12),
      ),
    ];

    for (final orb in orbs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, Colors.transparent],
        ).createShader(
          Rect.fromCircle(
            center: Offset(orb.cx, orb.cy),
            radius: orb.radius,
          ),
        );
      canvas.drawCircle(Offset(orb.cx, orb.cy), orb.radius, paint);
    }

    // Subtle grid dots
    final dotPaint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(c * spacing, r * spacing),
          1.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t;
}

class _OrbData {
  final double cx, cy, radius;
  final Color color;
  const _OrbData({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.color,
  });
}

// ── Currency Chip ─────────────────────────────────────────────────────────────

class _CurrencyChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _CurrencyChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(30),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 5),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode Card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  const _ModeCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      animation: _pressScale,
      builder: (context, child) => Transform.scale(
        scale: _pressScale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                widget.gradient.colors.first.withAlpha(30),
                widget.gradient.colors.last.withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.gradient.colors.first.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Big background icon
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  widget.icon,
                  size: 72,
                  color: widget.gradient.colors.first.withAlpha(25),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradient.colors.first.withAlpha(100),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 18),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // NEW badge
              if (widget.badgeText != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonOrange,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonOrange.withAlpha(150),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.badgeText!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Stat Tile ───────────────────────────────────────────────────────────

class _QuickStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav Item ───────────────────────────────────────────────────────────

class _BottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//home
//screen