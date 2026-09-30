import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final progress = playerRepo.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Career Stats', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Games Played',
                    value: '${progress.totalGames}',
                    icon: Icons.sports_esports_outlined,
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Lines Cleared',
                    value: '${progress.totalLines}',
                    icon: Icons.clear_all_rounded,
                    color: AppColors.neonPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Best Score',
                    value: '${progress.bestClassicScore}',
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.goldCoin,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Highest Combo',
                    value: '${progress.bestCombo}x',
                    icon: Icons.bolt,
                    color: AppColors.neonPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Score History Chart (CustomPainter)
            Text(
              'SCORE TREND',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 160,
                child: CustomPaint(
                  painter: _ScoreTrendPainter(
                    bestScore: progress.bestClassicScore,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ScoreTrendPainter extends CustomPainter {
  final int bestScore;

  _ScoreTrendPainter({required this.bestScore});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.neonCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.neonCyan.withAlpha(100), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.25, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.45),
      Offset(size.width * 0.75, size.height * 0.55),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
