import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final iap = ref.watch(iapServiceProvider);
    final progress = playerRepo.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Prism Store', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Currency Balances
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: AppColors.goldCoin,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${progress.coins}',
                          style: AppTextStyles.titleMedium,
                        ),
                        Text('Coins', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.diamond,
                          color: AppColors.neonCyan,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${progress.gems}',
                          style: AppTextStyles.titleMedium,
                        ),
                        Text('Gems', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Remove Ads Non-consumable
            if (!progress.hasRemoveAds) ...[
              Text(
                'PREMIUM',
                style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.neonPurple,
                child: Row(
                  children: [
                    const Icon(
                      Icons.block,
                      color: AppColors.neonPurple,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remove Ads Forever',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            'Enjoy zero ad interruptions in all modes.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    GradientButton(
                      text: '\$2.99',
                      height: 40,
                      onPressed: () async {
                        await iap.buyProduct('com.prismblocks.remove_ads');
                        await playerRepo.save(
                          progress.copyWith(hasRemoveAds: true),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Gems Packages
            Text(
              'GEM PACKS',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            _ShopItemRow(
              icon: Icons.diamond_outlined,
              iconColor: AppColors.neonCyan,
              title: '100 Gems',
              price: '\$0.99',
              onBuy: () async {
                await iap.buyProduct('com.prismblocks.gems_tier1');
                await playerRepo.addGems(100);
              },
            ),
            const SizedBox(height: 10),
            _ShopItemRow(
              icon: Icons.diamond_outlined,
              iconColor: AppColors.neonCyan,
              title: '500 Gems (Best Value)',
              price: '\$3.99',
              onBuy: () async {
                await iap.buyProduct('com.prismblocks.gems_tier2');
                await playerRepo.addGems(500);
              },
            ),
            const SizedBox(height: 24),

            // Restore Purchases
            Center(
              child: TextButton(
                onPressed: () async {
                  await iap.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchases restored successfully!'),
                      ),
                    );
                  }
                },
                child: Text(
                  'Restore Purchases',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopItemRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String price;
  final VoidCallback onBuy;

  const _ShopItemRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.bodyLarge)),
          GradientButton(text: price, height: 38, onPressed: onBuy),
        ],
      ),
    );
  }
}
