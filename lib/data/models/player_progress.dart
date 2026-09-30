class PlayerProgress {
  final int coins;
  final int gems;
  final int undos;
  final int bestClassicScore;
  final int streakCount;
  final String? lastDailyDate;
  final int totalGames;
  final int totalLines;
  final int bestCombo;
  final List<String> unlockedThemes;
  final List<String> completedAchievements;
  final bool hasRemoveAds;
  final String selectedTheme;
  final int dailyDayIndex;
  final String? lastLoginDate;

  const PlayerProgress({
    this.coins = 100,
    this.gems = 10,
    this.undos = 2,
    this.bestClassicScore = 0,
    this.streakCount = 0,
    this.lastDailyDate,
    this.totalGames = 0,
    this.totalLines = 0,
    this.bestCombo = 0,
    this.unlockedThemes = const ['neon'],
    this.completedAchievements = const [],
    this.hasRemoveAds = false,
    this.selectedTheme = 'neon',
    this.dailyDayIndex = 1,
    this.lastLoginDate,
  });

  PlayerProgress copyWith({
    int? coins,
    int? gems,
    int? undos,
    int? bestClassicScore,
    int? streakCount,
    String? lastDailyDate,
    int? totalGames,
    int? totalLines,
    int? bestCombo,
    List<String>? unlockedThemes,
    List<String>? completedAchievements,
    bool? hasRemoveAds,
    String? selectedTheme,
    int? dailyDayIndex,
    String? lastLoginDate,
  }) {
    return PlayerProgress(
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      undos: undos ?? this.undos,
      bestClassicScore: bestClassicScore ?? this.bestClassicScore,
      streakCount: streakCount ?? this.streakCount,
      lastDailyDate: lastDailyDate ?? this.lastDailyDate,
      totalGames: totalGames ?? this.totalGames,
      totalLines: totalLines ?? this.totalLines,
      bestCombo: bestCombo ?? this.bestCombo,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      completedAchievements:
          completedAchievements ?? this.completedAchievements,
      hasRemoveAds: hasRemoveAds ?? this.hasRemoveAds,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      dailyDayIndex: dailyDayIndex ?? this.dailyDayIndex,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'gems': gems,
    'undos': undos,
    'bestClassicScore': bestClassicScore,
    'streakCount': streakCount,
    'lastDailyDate': lastDailyDate,
    'totalGames': totalGames,
    'totalLines': totalLines,
    'bestCombo': bestCombo,
    'unlockedThemes': unlockedThemes,
    'completedAchievements': completedAchievements,
    'hasRemoveAds': hasRemoveAds,
    'selectedTheme': selectedTheme,
    'dailyDayIndex': dailyDayIndex,
    'lastLoginDate': lastLoginDate,
  };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) => PlayerProgress(
    coins: json['coins'] as int? ?? 100,
    gems: json['gems'] as int? ?? 10,
    undos: json['undos'] as int? ?? 2,
    bestClassicScore: json['bestClassicScore'] as int? ?? 0,
    streakCount: json['streakCount'] as int? ?? 0,
    lastDailyDate: json['lastDailyDate'] as String?,
    totalGames: json['totalGames'] as int? ?? 0,
    totalLines: json['totalLines'] as int? ?? 0,
    bestCombo: json['bestCombo'] as int? ?? 0,
    unlockedThemes:
        (json['unlockedThemes'] as List?)?.cast<String>() ?? const ['neon'],
    completedAchievements:
        (json['completedAchievements'] as List?)?.cast<String>() ?? const [],
    hasRemoveAds: json['hasRemoveAds'] as bool? ?? false,
    selectedTheme: json['selectedTheme'] as String? ?? 'neon',
    dailyDayIndex: json['dailyDayIndex'] as int? ?? 1,
    lastLoginDate: json['lastLoginDate'] as String?,
  );
}
