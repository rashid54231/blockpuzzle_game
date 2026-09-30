import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class AchievementDef {
  final String key;
  final String title;
  final String description;
  final int rewardCoins;
  final int targetValue;
  final int Function(dynamic progress) getCurrentValue;

  const AchievementDef({
    required this.key,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.targetValue,
    required this.getCurrentValue,
  });
}

abstract final class AchievementCatalog {
  static final List<AchievementDef> all = [
    AchievementDef(
      key: 'first_clear',
      title: 'First Spark',
      description: 'Clear your very first line.',
      rewardCoins: 50,
      targetValue: 1,
      getCurrentValue: (p) => p.totalLines >= 1 ? 1 : 0,
    ),
    AchievementDef(
      key: 'lines_10',
      title: 'Block Buster',
      description: 'Clear a total of 10 lines.',
      rewardCoins: 100,
      targetValue: 10,
      getCurrentValue: (p) => p.totalLines,
    ),
    AchievementDef(
      key: 'lines_50',
      title: 'Grid Cleaner',
      description: 'Clear 50 total lines.',
      rewardCoins: 200,
      targetValue: 50,
      getCurrentValue: (p) => p.totalLines,
    ),
    AchievementDef(
      key: 'lines_100',
      title: 'Centurion of Blocks',
      description: 'Clear 100 total lines.',
      rewardCoins: 500,
      targetValue: 100,
      getCurrentValue: (p) => p.totalLines,
    ),
    AchievementDef(
      key: 'combo_2',
      title: 'Double Rhythm',
      description: 'Hit a 2x combo.',
      rewardCoins: 50,
      targetValue: 2,
      getCurrentValue: (p) => p.bestCombo,
    ),
    AchievementDef(
      key: 'combo_3',
      title: 'Triple Harmony',
      description: 'Hit a 3x combo.',
      rewardCoins: 100,
      targetValue: 3,
      getCurrentValue: (p) => p.bestCombo,
    ),
    AchievementDef(
      key: 'combo_5',
      title: 'Cascade Maestro',
      description: 'Reach an unbelievable 5x combo.',
      rewardCoins: 300,
      targetValue: 5,
      getCurrentValue: (p) => p.bestCombo,
    ),
    AchievementDef(
      key: 'score_500',
      title: 'Prism Cadet',
      description: 'Score 500 points in Classic mode.',
      rewardCoins: 100,
      targetValue: 500,
      getCurrentValue: (p) => p.bestClassicScore,
    ),
    AchievementDef(
      key: 'score_1000',
      title: 'Score Crusher',
      description: 'Score 1,000 points in Classic mode.',
      rewardCoins: 200,
      targetValue: 1000,
      getCurrentValue: (p) => p.bestClassicScore,
    ),
    AchievementDef(
      key: 'score_2500',
      title: 'Grand Master',
      description: 'Score 2,500 points in Classic mode.',
      rewardCoins: 500,
      targetValue: 2500,
      getCurrentValue: (p) => p.bestClassicScore,
    ),
    AchievementDef(
      key: 'score_5000',
      title: 'Prism Legend',
      description: 'Score 5,000 points in Classic mode.',
      rewardCoins: 1000,
      targetValue: 5000,
      getCurrentValue: (p) => p.bestClassicScore,
    ),
    AchievementDef(
      key: 'games_5',
      title: 'Getting Hooked',
      description: 'Play 5 full games.',
      rewardCoins: 100,
      targetValue: 5,
      getCurrentValue: (p) => p.totalGames,
    ),
    AchievementDef(
      key: 'games_20',
      title: 'Dedicated Player',
      description: 'Complete 20 games.',
      rewardCoins: 250,
      targetValue: 20,
      getCurrentValue: (p) => p.totalGames,
    ),
    AchievementDef(
      key: 'games_50',
      title: 'Prism Veteran',
      description: 'Complete 50 games.',
      rewardCoins: 600,
      targetValue: 50,
      getCurrentValue: (p) => p.totalGames,
    ),
    AchievementDef(
      key: 'streak_3',
      title: 'Daily Dedication',
      description: 'Maintain a 3-day login streak.',
      rewardCoins: 200,
      targetValue: 3,
      getCurrentValue: (p) => p.streakCount,
    ),
    AchievementDef(
      key: 'streak_7',
      title: 'Weekly Champion',
      description: 'Reach a 7-day streak.',
      rewardCoins: 500,
      targetValue: 7,
      getCurrentValue: (p) => p.streakCount,
    ),
    AchievementDef(
      key: 'theme_collector',
      title: 'Aesthetic Sense',
      description: 'Unlock at least 2 themes.',
      rewardCoins: 150,
      targetValue: 2,
      getCurrentValue: (p) => p.unlockedThemes.length,
    ),
    AchievementDef(
      key: 'theme_master',
      title: 'Prism Wardrobe',
      description: 'Unlock 4 themes.',
      rewardCoins: 400,
      targetValue: 4,
      getCurrentValue: (p) => p.unlockedThemes.length,
    ),
    AchievementDef(
      key: 'rich_player',
      title: 'Treasure Hoarder',
      description: 'Accumulate 1,000 coins.',
      rewardCoins: 200,
      targetValue: 1000,
      getCurrentValue: (p) => p.coins,
    ),
    AchievementDef(
      key: 'gem_finder',
      title: 'Gem Collector',
      description: 'Hold 25 gems.',
      rewardCoins: 300,
      targetValue: 25,
      getCurrentValue: (p) => p.gems,
    ),
  ];
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final progress = playerRepo.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Achievements', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: AchievementCatalog.all.length,
          separatorBuilder: (_, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ach = AchievementCatalog.all[index];
            final currentVal = ach.getCurrentValue(progress);
            final isCompleted = currentVal >= ach.targetValue;
            final isClaimed = progress.completedAchievements.contains(ach.key);

            return GlassCard(
              padding: const EdgeInsets.all(14),
              borderColor: isClaimed
                  ? AppColors.neonGreen.withAlpha(120)
                  : (isCompleted ? AppColors.goldCoin : AppColors.glassBorder),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.goldCoin.withAlpha(40)
                          : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isClaimed ? Icons.check_circle : Icons.military_tech,
                      color: isClaimed
                          ? AppColors.neonGreen
                          : (isCompleted ? AppColors.goldCoin : Colors.white38),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ach.title, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text(ach.description, style: AppTextStyles.bodySmall),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (currentVal / ach.targetValue).clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? AppColors.neonGreen
                                : AppColors.neonCyan,
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isClaimed) ...[
                    Text(
                      'CLAIMED',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else if (isCompleted) ...[
                    GradientButton(
                      text: '+${ach.rewardCoins}',
                      icon: Icons.monetization_on,
                      gradient: AppColors.goldGradient,
                      height: 38,
                      onPressed: () async {
                        final updatedList = List<String>.from(
                          progress.completedAchievements,
                        )..add(ach.key);
                        await playerRepo.addCoins(ach.rewardCoins);
                        await playerRepo.save(
                          progress.copyWith(completedAchievements: updatedList),
                        );
                      },
                    ),
                  ] else ...[
                    Text(
                      '${currentVal.clamp(0, ach.targetValue)}/${ach.targetValue}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
