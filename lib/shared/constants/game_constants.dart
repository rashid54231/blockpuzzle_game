/// Global game constants for Prism Blocks.
/// Working title is kept in a single constant for easy renaming.
abstract final class GameConstants {
  /// The official working title of the game.
  static const String appTitle = 'Prism Blocks';

  /// Default grid dimension (8x8).
  static const int boardDimension = 8;

  /// Number of pieces available in tray per round.
  static const int trayCapacity = 3;

  /// Maximum undos allowed to be stocked.
  static const int maxStoredUndos = 5;

  /// Revives allowed per game run.
  static const int maxRevivesPerRun = 1;

  /// Minimum score threshold before interstitials can be considered.
  static const int minGamesBeforeInterstitial = 3;

  /// Game cooldown seconds between interstitials.
  static const int interstitialCooldownSeconds = 90;

  /// Currency defaults
  static const int startingCoins = 100;
  static const int startingGems = 10;
  static const int startingUndos = 2;
  static const int undoCoinCost = 50;
  static const int reviveGemCost = 5;
}
