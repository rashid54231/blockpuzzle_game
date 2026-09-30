/// Available game modes in Prism Blocks.
enum GameMode {
  /// Endless score attack, best score tracked.
  classic,

  /// Deterministic daily seed, global daily leaderboard.
  daily,

  /// Relaxed mode: auto-clears on full board, no game over.
  zen;

  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.daily:
        return 'Daily Challenge';
      case GameMode.zen:
        return 'Zen Mode';
    }
  }
}
