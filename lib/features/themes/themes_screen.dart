import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/theme/game_theme.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    final playerRepo = ref.watch(playerRepositoryProvider);
    final progress = playerRepo.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Themes & Cosmetics', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: GameThemes.all.length,
          itemBuilder: (context, index) {
            final theme = GameThemes.all[index];
            final isSelected = currentTheme.id == theme.id;
            final isUnlocked =
                theme.isDefaultUnlocked ||
                progress.unlockedThemes.contains(theme.id.name);

            return GlassCard(
              borderColor: isSelected
                  ? AppColors.neonCyan
                  : AppColors.glassBorder,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Palette Preview
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: theme.backgroundGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.gridLineColor),
                      ),
                      child: Center(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: theme.piecePalette.take(6).map((color) {
                            return Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    theme.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (isSelected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'EQUIPPED',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (isUnlocked) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.neonCyan),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      onPressed: () {
                        ref
                            .read(currentThemeIdProvider.notifier)
                            .setTheme(theme.id);
                        playerRepo.save(
                          progress.copyWith(selectedTheme: theme.id.name),
                        );
                      },
                      child: const Text('EQUIP'),
                    ),
                  ] else ...[
                    GradientButton(
                      text: theme.costCoins > 0
                          ? '${theme.costCoins} Coins'
                          : '${theme.costGems} Gems',
                      height: 36,
                      onPressed: () async {
                        bool bought = false;
                        if (theme.costCoins > 0) {
                          bought = await playerRepo.spendCoins(theme.costCoins);
                        } else {
                          bought = await playerRepo.spendGems(theme.costGems);
                        }

                        if (bought) {
                          final updatedList = List<String>.from(
                            progress.unlockedThemes,
                          )..add(theme.id.name);
                          await playerRepo.save(
                            progress.copyWith(unlockedThemes: updatedList),
                          );
                          ref
                              .read(currentThemeIdProvider.notifier)
                              .setTheme(theme.id);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Not enough currency!'),
                              ),
                            );
                          }
                        }
                      },
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
