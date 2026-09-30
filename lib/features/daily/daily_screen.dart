import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  int _seed = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyPuzzle();
  }

  Future<void> _fetchDailyPuzzle() async {
    final nowUtc = DateTime.now().toUtc();
    final dateStr =
        '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}';
    final fallbackSeed =
        (nowUtc.year * 10000) + (nowUtc.month * 100) + nowUtc.day;

    final supabase = ref.read(supabaseServiceProvider);
    if (supabase.isAvailable) {
      try {
        final response = await supabase.client?.rpc(
          'get_daily_puzzle',
          params: {'target_date': dateStr},
        );
        if (response != null && response['seed'] != null) {
          if (mounted) {
            setState(() {
              _seed = (response['seed'] as num).toInt();
              _isLoading = false;
            });
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _seed = fallbackSeed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final progress = playerRepo.current;
    final nowUtc = DateTime.now().toUtc();
    final dateStr =
        '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}';
    final alreadyPlayedToday = progress.lastDailyDate == dateStr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daily Challenge', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.neonOrange,
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppColors.neonOrange,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text('Today\'s Puzzle', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Everyone receives the exact same piece sequence today. Test your strategy and compete on the global daily leaderboard!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                    if (alreadyPlayedToday) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neonGreen),
                        ),
                        child: Text(
                          'Ranked attempt completed today! You can still play unlimited practice attempts.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neonGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (_isLoading) ...[
                const Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan),
                ),
              ] else ...[
                GradientButton(
                  text: alreadyPlayedToday
                      ? 'PRACTICE ATTEMPT'
                      : 'PLAY RANKED CHALLENGE',
                  icon: Icons.emoji_events,
                  gradient: AppColors.fireStreakGradient,
                  onPressed: () {
                    if (!alreadyPlayedToday) {
                      playerRepo.save(
                        progress.copyWith(lastDailyDate: dateStr),
                      );
                    }
                    context.push('${AppRoutes.play}?mode=daily&seed=$_seed');
                  },
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => context.push(AppRoutes.leaderboard),
                child: const Text('VIEW DAILY LEADERBOARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
