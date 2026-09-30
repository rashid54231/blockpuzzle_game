import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class DailyRewardItem {
  final int dayIndex;
  final int coins;
  final int gems;

  const DailyRewardItem({
    required this.dayIndex,
    required this.coins,
    required this.gems,
  });
}

abstract final class DailyRewardCalendar {
  static const List<DailyRewardItem> rewards = [
    DailyRewardItem(dayIndex: 1, coins: 100, gems: 0),
    DailyRewardItem(dayIndex: 2, coins: 150, gems: 0),
    DailyRewardItem(dayIndex: 3, coins: 200, gems: 5),
    DailyRewardItem(dayIndex: 4, coins: 250, gems: 0),
    DailyRewardItem(dayIndex: 5, coins: 300, gems: 10),
    DailyRewardItem(dayIndex: 6, coins: 400, gems: 10),
    DailyRewardItem(dayIndex: 7, coins: 1000, gems: 25), // Big finale
  ];
}

class DailyRewardDialog extends StatelessWidget {
  final int currentDayIndex;
  final VoidCallback onClaim;

  const DailyRewardDialog({
    super.key,
    required this.currentDayIndex,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.goldCoin),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0x33FFC107),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars,
                color: AppColors.goldCoin,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            Text('Daily Login Reward', style: AppTextStyles.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Log in each day to unlock expanding rewards and maintain your streak!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: DailyRewardCalendar.rewards.map((reward) {
                final isCurrent = reward.dayIndex == currentDayIndex;
                final isPast = reward.dayIndex < currentDayIndex;

                return GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  borderColor: isCurrent
                      ? AppColors.goldCoin
                      : AppColors.glassBorder,
                  backgroundColor: isCurrent ? const Color(0x33FFC107) : null,
                  child: Column(
                    children: [
                      Text(
                        'Day ${reward.dayIndex}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        reward.gems > 0 ? Icons.diamond : Icons.monetization_on,
                        color: reward.gems > 0
                            ? AppColors.neonCyan
                            : AppColors.goldCoin,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.gems > 0
                            ? '+${reward.gems} Gems'
                            : '+${reward.coins}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      if (isPast) ...[
                        const Icon(
                          Icons.check,
                          color: AppColors.neonGreen,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'CLAIM DAY $currentDayIndex REWARD',
              gradient: AppColors.goldGradient,
              onPressed: onClaim,
            ),
          ],
        ),
      ),
    );
  }
}
