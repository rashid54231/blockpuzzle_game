import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final String countryCode;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.score,
    this.countryCode = 'US',
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = false;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchLeaderboard();
      }
    });
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseServiceProvider);
    final playerRepo = ref.read(playerRepositoryProvider);
    final progress = playerRepo.current;

    if (supabase.isAvailable) {
      try {
        final isDaily = _tabController.index == 0;
        final rpcName = isDaily ? 'leaderboard_daily' : 'leaderboard_alltime';
        final params = isDaily
            ? {
                'target_date': DateTime.now()
                    .toUtc()
                    .toIso8601String()
                    .substring(0, 10),
                'limit_count': 50,
                'offset_count': 0,
              }
            : {'limit_count': 50, 'offset_count': 0};

        final response = await supabase.client?.rpc(rpcName, params: params);
        if (response is List) {
          final List<LeaderboardEntry> loaded = [];
          for (int i = 0; i < response.length; i++) {
            final row = response[i];
            loaded.add(
              LeaderboardEntry(
                rank: i + 1,
                username: row['username'] as String? ?? 'Player ${i + 1}',
                score: (row['score'] as num?)?.toInt() ?? 0,
                countryCode: row['country_code'] as String? ?? 'US',
                isCurrentUser: row['user_id'] == supabase.currentUserId,
              ),
            );
          }
          if (mounted) {
            setState(() {
              _entries = loaded;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (_) {}
    }

    // Offline / Demo fallback leaderboard
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final mockScores = [
      LeaderboardEntry(
        rank: 1,
        username: 'PrismNinja',
        score: 8420,
        countryCode: 'JP',
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'BlockMaster',
        score: 7150,
        countryCode: 'US',
      ),
      LeaderboardEntry(
        rank: 3,
        username: 'AuroraGlow',
        score: 6890,
        countryCode: 'CA',
      ),
      LeaderboardEntry(
        rank: 4,
        username: 'NeonRider',
        score: 5400,
        countryCode: 'GB',
      ),
      LeaderboardEntry(
        rank: 5,
        username: 'PuzzleQueen',
        score: 4950,
        countryCode: 'DE',
      ),
      LeaderboardEntry(
        rank: 6,
        username: 'PrismCadet',
        score: 3200,
        countryCode: 'FR',
      ),
    ];

    // If player has a score, include them
    if (progress.bestClassicScore > 0) {
      mockScores.add(
        LeaderboardEntry(
          rank: 7,
          username: 'You',
          score: progress.bestClassicScore,
          isCurrentUser: true,
        ),
      );
    }

    setState(() {
      _entries = mockScores;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    final myScore = playerRepo.current.bestClassicScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Leaderboard', style: AppTextStyles.titleMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'DAILY GLOBAL'),
            Tab(text: 'ALL-TIME CLASSIC'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonCyan,
                      ),
                    )
                  : _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No scores yet. Be the first!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _LeaderboardRow(entry: entry);
                      },
                    ),
            ),
            // Pinned Current User Rank Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'YOU',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Your Best Record', style: AppTextStyles.bodyLarge),
                  const Spacer(),
                  Text(
                    '$myScore',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.neonCyan,
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

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color rankColor = Colors.white70;
    if (entry.rank == 1) rankColor = AppColors.goldCoin;
    if (entry.rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (entry.rank == 3) rankColor = const Color(0xFFCD7F32);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: entry.isCurrentUser
          ? AppColors.neonCyan
          : AppColors.glassBorder,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: AppTextStyles.titleMedium.copyWith(color: rankColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.username,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: entry.isCurrentUser
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: entry.isCurrentUser ? AppColors.neonCyan : Colors.white,
            ),
          ),
          const Spacer(),
          Text('${entry.score}', style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
