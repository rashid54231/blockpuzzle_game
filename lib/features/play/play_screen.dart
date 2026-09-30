import 'dart:convert';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/engine/game_engine.dart';
import '../../core/models/game_mode.dart';
import '../../core/models/game_state.dart';
import '../../game/prism_flame_game.dart';
import '../../shared/constants/game_constants.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/animated_counter.dart';
import '../../shared/widgets/gradient_button.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  final int? seed;

  const PlayScreen({super.key, required this.mode, this.seed});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen>
    with TickerProviderStateMixin {
  late final GameEngine _engine;
  PrismFlameGame? _game;
  bool _isInitialized = false;

  // Ambient background
  late final AnimationController _ambientController;

  // Combo banner
  late final AnimationController _comboController;
  late final Animation<double> _comboScale;
  late final Animation<double> _comboOpacity;

  // Score pop
  late final AnimationController _scorePopController;
  late final Animation<double> _scorePopScale;

  // HUD entrance
  late final AnimationController _hudController;
  late final Animation<double> _hudFade;

  int _lastCombo = 0;
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _comboScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.15), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _comboController, curve: Curves.easeOut));
    _comboOpacity = CurvedAnimation(parent: _comboController, curve: Curves.easeIn);

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scorePopScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 65),
    ]).animate(CurvedAnimation(parent: _scorePopController, curve: Curves.easeOut));

    _hudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _hudFade = CurvedAnimation(parent: _hudController, curve: Curves.easeOut);

    _initializeGame();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _comboController.dispose();
    _scorePopController.dispose();
    _hudController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    final storage = ref.read(storageServiceProvider);
    final audio = ref.read(audioServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final theme = ref.read(currentThemeProvider);
    final isColorblind = ref.read(colorblindModeProvider);

    GameState? restoredState;
    if (widget.mode != GameMode.daily) {
      final savedJson = storage.getString('active_run_${widget.mode.name}');
      if (savedJson != null) {
        try {
          restoredState = GameState.fromJson(
            jsonDecode(savedJson) as Map<String, dynamic>,
          );
          if (restoredState.isGameOver) restoredState = null;
        } catch (_) {
          restoredState = null;
        }
      }
    }

    _engine = GameEngine(
      mode: widget.mode,
      seed: widget.seed,
      initialUndos: GameConstants.startingUndos,
      restoredState: restoredState,
    );

    _game = PrismFlameGame(
      engine: _engine,
      audio: audio,
      haptics: haptics,
      theme: theme,
      isColorblind: isColorblind,
      onStateChanged: _onGameStateChanged,
      onGameOver: _onGameOver,
    );

    setState(() => _isInitialized = true);
    _hudController.forward();
  }

  void _onGameStateChanged() {
    final storage = ref.read(storageServiceProvider);
    if (widget.mode != GameMode.daily) {
      storage.setString(
        'active_run_${widget.mode.name}',
        jsonEncode(_engine.state.toJson()),
      );
    }

    final newCombo = _engine.state.currentCombo;
    if (newCombo >= 2 && newCombo != _lastCombo) {
      _comboController.forward(from: 0);
    }
    _lastCombo = newCombo;

    final newScore = _engine.state.score;
    if (newScore > _lastScore) {
      _scorePopController.forward(from: 0);
    }
    _lastScore = newScore;

    setState(() {});
  }

  void _onGameOver() {
    final storage = ref.read(storageServiceProvider);
    final ads = ref.read(adsServiceProvider);
    final playerRepo = ref.read(playerRepositoryProvider);

    storage.remove('active_run_${widget.mode.name}');
    ads.recordGameCompleted();
    playerRepo.recordGameResult(
      mode: widget.mode.name,
      score: _engine.state.score,
      lines: _engine.state.linesClearedTotal,
      combo: _engine.state.bestCombo,
    );

    _showGameOverModal();
  }

  void _showPauseDialog() {
    final audio = ref.read(audioServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final storage = ref.read(storageServiceProvider);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(180),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, _2) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141828),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.neonCyan.withAlpha(60),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withAlpha(50),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pause icon with glow
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonCyan.withAlpha(40),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.neonCyan.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: AppColors.neonCyan,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PAUSED',
                    style: AppTextStyles.titleLarge.copyWith(
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progress is auto-saved',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  // Toggles
                  _PauseToggle(
                    label: 'Sound FX',
                    icon: Icons.volume_up_rounded,
                    value: audio.isSfxEnabled,
                    activeColor: AppColors.neonCyan,
                    onChanged: (val) {
                      audio.setSfxEnabled(val);
                      storage.setBool('pref_sfx', val);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _PauseToggle(
                    label: 'Music',
                    icon: Icons.music_note_rounded,
                    value: audio.isMusicEnabled,
                    activeColor: AppColors.neonPurple,
                    onChanged: (val) {
                      audio.setMusicEnabled(val);
                      storage.setBool('pref_music', val);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  _PauseToggle(
                    label: 'Haptics',
                    icon: Icons.vibration_rounded,
                    value: haptics.isEnabled,
                    activeColor: AppColors.neonGreen,
                    onChanged: (val) {
                      haptics.setEnabled(val);
                      storage.setBool('pref_haptics', val);
                      setDialogState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  GradientButton(
                    text: 'RESUME GAME',
                    icon: Icons.play_arrow_rounded,
                    height: 52,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.home);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.white38,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Exit to Home',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOverModal() {
    final playerRepo = ref.read(playerRepositoryProvider);
    final audio = ref.read(audioServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final progress = playerRepo.current;
    final isNewRecord =
        widget.mode == GameMode.classic &&
        _engine.state.score > progress.bestClassicScore;
    final coinsEarned =
        (_engine.state.score / 10).floor() +
        (_engine.state.linesClearedTotal * 2);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GameOverSheet(
        engine: _engine,
        mode: widget.mode,
        isNewRecord: isNewRecord,
        coinsEarned: coinsEarned,
        audio: audio,
        haptics: haptics,
        onRevive: () {
          Navigator.pop(ctx);
          _engine.revive();
          audio.playSfx('reward_claim');
          haptics.success();
          _onGameStateChanged();
        },
        onPlayAgain: () {
          Navigator.pop(ctx);
          context.go(
            '${AppRoutes.play}?mode=${widget.mode.name}&restart=1',
          );
        },
        onHome: () {
          Navigator.pop(ctx);
          context.go(AppRoutes.home);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _game == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.neonCyan,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final currentTheme = ref.watch(currentThemeProvider);
    final isColorblind = ref.watch(colorblindModeProvider);
    _game!.updateTheme(currentTheme, isColorblind);

    final playerRepo = ref.watch(playerRepositoryProvider);
    final bestScore = playerRepo.current.bestClassicScore;
    final currentCombo = _engine.state.currentCombo;
    final isBeatingRecord =
        widget.mode == GameMode.classic &&
        _engine.state.score > 0 &&
        _engine.state.score > bestScore;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Ambient animated background ────────────────────────────
          Container(
            decoration: BoxDecoration(gradient: currentTheme.backgroundGradient),
          ),
          _PlayAmbientBg(controller: _ambientController, size: size),

          // ── Main game layout ───────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _hudFade,
              child: Column(
                children: [
                  // HUD
                  _buildHUD(bestScore, isBeatingRecord),

                  // Combo
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: currentCombo >= 2
                        ? _buildComboBanner(currentCombo)
                        : const SizedBox(key: ValueKey('empty')),
                  ),

                  // Game canvas
                  Expanded(
                    child: ClipRect(child: GameWidget(game: _game!)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD(int bestScore, bool isBeatingRecord) {
    final score = _engine.state.score;
    final lines = _engine.state.linesClearedTotal;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x99101422),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBeatingRecord
              ? AppColors.goldCoin.withAlpha(100)
              : Colors.white.withAlpha(20),
          width: 1.2,
        ),
        boxShadow: isBeatingRecord
            ? [
                BoxShadow(
                  color: AppColors.goldCoin.withAlpha(40),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Pause
          _HudButton(
            icon: Icons.pause_rounded,
            onTap: _showPauseDialog,
          ),

          const SizedBox(width: 8),

          // Best
          _HudStatBlock(
            label: 'BEST',
            value: '$bestScore',
            valueColor: isBeatingRecord ? AppColors.goldCoin : Colors.white54,
          ),

          // Score — center, biggest
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCORE',
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 2.5,
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: _scorePopScale,
                  builder: (_, child) => Transform.scale(
                    scale: _scorePopScale.value,
                    child: child,
                  ),
                  child: AnimatedCounter(
                    count: score,
                    style: AppTextStyles.scoreMedium.copyWith(
                      fontSize: 34,
                      color: isBeatingRecord
                          ? AppColors.goldCoin
                          : AppColors.neonCyan,
                      shadows: [
                        Shadow(
                          color: (isBeatingRecord
                                  ? AppColors.goldCoin
                                  : AppColors.neonCyan)
                              .withAlpha(120),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lines
          _HudStatBlock(
            label: 'LINES',
            value: '$lines',
            valueColor: AppColors.neonGreen,
            align: CrossAxisAlignment.end,
          ),

          const SizedBox(width: 8),

          // Undo
          _buildUndoButton(),
        ],
      ),
    );
  }

  Widget _buildUndoButton() {
    final canUndo = _engine.canUndo;
    final charges = _engine.state.undoCharges;

    return GestureDetector(
      onTap: canUndo
          ? () {
              ref.read(audioServiceProvider).playSfx('pickup');
              ref.read(hapticsServiceProvider).light();
              _engine.undo();
              _onGameStateChanged();
            }
          : null,
      child: AnimatedOpacity(
        opacity: canUndo ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha(canUndo ? 40 : 15),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.undo_rounded, color: Colors.white, size: 20),
              if (charges > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.neonCyan, AppColors.neonPurple],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withAlpha(150),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$charges',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
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

  Widget _buildComboBanner(int combo) {
    // Escalating color + label
    final comboData = _ComboData.forLevel(combo);

    return AnimatedBuilder(
      animation: _comboScale,
      builder: (_, child) => Transform.scale(
        scale: _comboScale.value,
        child: Opacity(
          opacity: _comboOpacity.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey('combo_$combo'),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              comboData.color.withAlpha(220),
              comboData.color.withAlpha(120),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: comboData.color.withAlpha(160),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(comboData.emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 8),
            Text(
              '${combo}x  ${comboData.label}',
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 15,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: comboData.color.withAlpha(255),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Combo Data ────────────────────────────────────────────────────────────────

class _ComboData {
  final Color color;
  final String emoji;
  final String label;

  const _ComboData({
    required this.color,
    required this.emoji,
    required this.label,
  });

  static _ComboData forLevel(int combo) {
    if (combo <= 2) return const _ComboData(color: Color(0xFFFFD600), emoji: '⚡', label: 'COMBO!');
    if (combo == 3) return const _ComboData(color: Color(0xFFFF6D00), emoji: '🔥', label: 'ON FIRE!');
    if (combo == 4) return const _ComboData(color: Color(0xFFFF007F), emoji: '💥', label: 'BLAZING!');
    if (combo == 5) return const _ComboData(color: Color(0xFFB300FF), emoji: '🌟', label: 'UNSTOPPABLE!');
    return const _ComboData(color: Color(0xFFFFFFFF), emoji: '✨', label: 'GODLIKE!');
  }
}

// ── Ambient Background ────────────────────────────────────────────────────────

class _PlayAmbientBg extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _PlayAmbientBg({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _2) => CustomPaint(
        size: size,
        painter: _PlayAmbientPainter(controller.value),
      ),
    );
  }
}

class _PlayAmbientPainter extends CustomPainter {
  final double t;
  _PlayAmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Two slow-drifting orbs for depth
    _drawOrb(
      canvas,
      cx: size.width * (0.15 + 0.06 * math.sin(t * 2 * math.pi)),
      cy: size.height * (0.3 + 0.04 * math.cos(t * 2 * math.pi)),
      radius: size.width * 0.5,
      color: const Color(0xFF00E5FF).withAlpha(14),
    );
    _drawOrb(
      canvas,
      cx: size.width * (0.85 - 0.07 * math.sin(t * 2 * math.pi + 1.5)),
      cy: size.height * (0.6 + 0.05 * math.cos(t * 2 * math.pi + 1.5)),
      radius: size.width * 0.55,
      color: const Color(0xFFB300FF).withAlpha(12),
    );
  }

  void _drawOrb(Canvas canvas, {
    required double cx,
    required double cy,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  @override
  bool shouldRepaint(_PlayAmbientPainter old) => old.t != t;
}

// ── Game Over Sheet ───────────────────────────────────────────────────────────

class _GameOverSheet extends StatefulWidget {
  final GameEngine engine;
  final GameMode mode;
  final bool isNewRecord;
  final int coinsEarned;
  final dynamic audio;
  final dynamic haptics;
  final VoidCallback onRevive;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const _GameOverSheet({
    required this.engine,
    required this.mode,
    required this.isNewRecord,
    required this.coinsEarned,
    required this.audio,
    required this.haptics,
    required this.onRevive,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  State<_GameOverSheet> createState() => _GameOverSheetState();
}

class _GameOverSheetState extends State<_GameOverSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetController;
  late final Animation<double> _sheetScale;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sheetScale = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.elasticOut,
    );
    _sheetController.forward();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final isNew = widget.isNewRecord;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF181D30),
            const Color(0xFF0E1120),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isNew ? AppColors.goldCoin.withAlpha(100) : Colors.white.withAlpha(20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isNew
                ? AppColors.goldCoin.withAlpha(60)
                : AppColors.neonCyan.withAlpha(40),
            blurRadius: 50,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          ScaleTransition(
            scale: _sheetScale,
            child: Column(
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isNew
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1E253D), Color(0xFF141828)],
                          ),
                    border: Border.all(
                      color: isNew ? AppColors.goldCoin : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isNew
                            ? AppColors.goldCoin.withAlpha(120)
                            : Colors.black26,
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    isNew ? Icons.emoji_events_rounded : Icons.sports_esports_rounded,
                    color: isNew ? Colors.white : Colors.white54,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  isNew ? '🏆 NEW RECORD!' : 'GAME OVER',
                  style: AppTextStyles.titleLarge.copyWith(
                    letterSpacing: 2,
                    color: isNew ? AppColors.goldCoin : Colors.white,
                    shadows: isNew
                        ? [
                            Shadow(
                              color: AppColors.goldCoin.withAlpha(200),
                              blurRadius: 20,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    widget.mode.name.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Score display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withAlpha(5),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Column(
              children: [
                Text(
                  'FINAL SCORE',
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 3,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (bounds) => (isNew
                          ? AppColors.goldGradient
                          : AppColors.primaryGradient)
                      .createShader(bounds),
                  child: Text(
                    '${engine.state.score}',
                    style: AppTextStyles.scoreLarge.copyWith(
                      color: Colors.white,
                      fontSize: 60,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _SheetStat(
                  icon: Icons.swap_vert_rounded,
                  label: 'Lines',
                  value: '${engine.state.linesClearedTotal}',
                  color: AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetStat(
                  icon: Icons.bolt_rounded,
                  label: 'Best Combo',
                  value: '${engine.state.bestCombo}x',
                  color: AppColors.neonYellow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetStat(
                  icon: Icons.monetization_on_rounded,
                  label: 'Coins',
                  value: '+${widget.coinsEarned}',
                  color: AppColors.goldCoin,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Revive
          if (engine.state.canRevive) ...[
            GradientButton(
              text: 'REVIVE  (+Clear 3×3 Center)',
              icon: Icons.favorite_rounded,
              height: 52,
              gradient: AppColors.fireStreakGradient,
              onPressed: widget.onRevive,
            ),
            const SizedBox(height: 10),
          ],

          // Play again
          GradientButton(
            text: 'PLAY AGAIN',
            icon: Icons.replay_rounded,
            height: 52,
            onPressed: widget.onPlayAgain,
          ),

          const SizedBox(height: 10),

          // Share + Home
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  icon: Icons.share_rounded,
                  label: 'SHARE',
                  onTap: () {
                    // ignore: deprecated_member_use
                    Share.share(
                      'I scored ${engine.state.score} in ${GameConstants.appTitle}! 🎮',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  icon: Icons.home_rounded,
                  label: 'HOME',
                  onTap: widget.onHome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── HUD Helper Widgets ────────────────────────────────────────────────────────

class _HudButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudButton({required this.icon, required this.onTap});

  @override
  State<_HudButton> createState() => _HudButtonState();
}

class _HudButtonState extends State<_HudButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
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
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Icon(widget.icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _HudStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  const _HudStatBlock({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              letterSpacing: 1.5,
              fontSize: 9,
              color: Colors.white30,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: valueColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game Over Sheet Helpers ───────────────────────────────────────────────────

class _SheetStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SheetStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pause Dialog Helpers ──────────────────────────────────────────────────────

class _PauseToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _PauseToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? activeColor.withAlpha(15) : Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? activeColor.withAlpha(80) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: value ? activeColor : Colors.white30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: value ? Colors.white : Colors.white38,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withAlpha(60),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
