import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/constants/game_constants.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final haptics = ref.watch(hapticsServiceProvider);
    final storage = ref.watch(storageServiceProvider);
    final consent = ref.watch(consentServiceProvider);
    final supabase = ref.watch(supabaseServiceProvider);
    final iap = ref.watch(iapServiceProvider);
    final isColorblind = ref.watch(colorblindModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Settings', style: AppTextStyles.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Audio & Feedback
            Text(
              'FEEDBACK & SOUND',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Sound Effects (SFX)',
                      style: AppTextStyles.bodyLarge,
                    ),
                    value: audio.isSfxEnabled,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) {
                      audio.setSfxEnabled(val);
                      storage.setBool('pref_sfx', val);
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Divider(color: Colors.white12),
                  SwitchListTile(
                    title: Text(
                      'Ambient Music',
                      style: AppTextStyles.bodyLarge,
                    ),
                    value: audio.isMusicEnabled,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) {
                      audio.setMusicEnabled(val);
                      storage.setBool('pref_music', val);
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Divider(color: Colors.white12),
                  SwitchListTile(
                    title: Text(
                      'Haptic Vibration',
                      style: AppTextStyles.bodyLarge,
                    ),
                    value: haptics.isEnabled,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) {
                      haptics.setEnabled(val);
                      storage.setBool('pref_haptics', val);
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Accessibility
            Text(
              'ACCESSIBILITY',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: Text('Colorblind Mode', style: AppTextStyles.bodyLarge),
                subtitle: Text(
                  'Displays geometric shape marks on all block prisms',
                  style: AppTextStyles.bodySmall,
                ),
                value: isColorblind,
                activeThumbColor: AppColors.neonCyan,
                onChanged: (val) {
                  ref.read(colorblindModeProvider.notifier).setMode(val);
                  storage.setBool('pref_colorblind_mode', val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Gameplay & Help
            Text(
              'GAMEPLAY',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Interactive Tutorial',
                      style: AppTextStyles.bodyLarge,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () => context.push(AppRoutes.tutorial),
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    title: Text(
                      'Restore Purchases',
                      style: AppTextStyles.bodyLarge,
                    ),
                    trailing: const Icon(Icons.restore, color: Colors.white54),
                    onTap: () async {
                      await iap.restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchases restored successfully'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    title: Text(
                      'Privacy Options (GDPR / Ads)',
                      style: AppTextStyles.bodyLarge,
                    ),
                    trailing: const Icon(Icons.security, color: Colors.white54),
                    onTap: () => consent.showPrivacyOptions(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account & Data (GDPR)
            Text(
              'ACCOUNT & DATA',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Account ID', style: AppTextStyles.bodyLarge),
                    subtitle: Text(
                      supabase.currentUserId ?? 'Guest (Local Only)',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  ListTile(
                    title: const Text(
                      'Delete Account & Data',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    trailing: const Icon(
                      Icons.delete_forever,
                      color: AppColors.danger,
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete All Data?'),
                          content: const Text(
                            'This will erase your local saves and request cloud profile deletion. This action is permanent.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Delete Permanently',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await supabase.client?.rpc('delete_my_account');
                          await storage.clear();
                        } catch (_) {}
                        if (context.mounted) {
                          context.go(AppRoutes.splash);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About
            Center(
              child: Column(
                children: [
                  Text(
                    '${GameConstants.appTitle} v1.0.0',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Designed with Flutter & Flame',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
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
