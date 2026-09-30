import '../board/board.dart';
import '../pieces/piece_shape.dart';
import '../scoring/scoring_rules.dart';
import 'game_mode.dart';

/// Immutable snapshot of the overall puzzle game state.
/// Pure Dart class with zero Flutter dependencies.
class GameState {
  final GameMode mode;
  final Board board;
  final List<PieceShape?> tray;
  final int score;
  final int linesClearedTotal;
  final int currentCombo;
  final int bestCombo;
  final int noClearPlacementsStreak;
  final int movesCount;
  final int seed;
  final bool isGameOver;
  final int revivesUsed;
  final int undoCharges;
  final MoveScoreResult? lastScoreResult;
  final LinesToClear lastClearedLines;

  const GameState({
    required this.mode,
    required this.board,
    required this.tray,
    required this.score,
    required this.linesClearedTotal,
    required this.currentCombo,
    required this.bestCombo,
    required this.noClearPlacementsStreak,
    required this.movesCount,
    required this.seed,
    required this.isGameOver,
    required this.revivesUsed,
    required this.undoCharges,
    this.lastScoreResult,
    this.lastClearedLines = const LinesToClear(rows: [], columns: []),
  });

  bool get canRevive => revivesUsed < 1 && isGameOver && mode != GameMode.zen;

  bool get isTrayEmpty => tray.every((p) => p == null);

  GameState copyWith({
    GameMode? mode,
    Board? board,
    List<PieceShape?>? tray,
    int? score,
    int? linesClearedTotal,
    int? currentCombo,
    int? bestCombo,
    int? noClearPlacementsStreak,
    int? movesCount,
    int? seed,
    bool? isGameOver,
    int? revivesUsed,
    int? undoCharges,
    MoveScoreResult? lastScoreResult,
    LinesToClear? lastClearedLines,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      board: board ?? this.board,
      tray: tray ?? List.unmodifiable(this.tray),
      score: score ?? this.score,
      linesClearedTotal: linesClearedTotal ?? this.linesClearedTotal,
      currentCombo: currentCombo ?? this.currentCombo,
      bestCombo: bestCombo ?? this.bestCombo,
      noClearPlacementsStreak:
          noClearPlacementsStreak ?? this.noClearPlacementsStreak,
      movesCount: movesCount ?? this.movesCount,
      seed: seed ?? this.seed,
      isGameOver: isGameOver ?? this.isGameOver,
      revivesUsed: revivesUsed ?? this.revivesUsed,
      undoCharges: undoCharges ?? this.undoCharges,
      lastScoreResult: lastScoreResult,
      lastClearedLines: lastClearedLines ?? this.lastClearedLines,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'board': board.toJson(),
    'tray': tray.map((p) => p?.toJson()).toList(),
    'score': score,
    'linesClearedTotal': linesClearedTotal,
    'currentCombo': currentCombo,
    'bestCombo': bestCombo,
    'noClearPlacementsStreak': noClearPlacementsStreak,
    'movesCount': movesCount,
    'seed': seed,
    'isGameOver': isGameOver,
    'revivesUsed': revivesUsed,
    'undoCharges': undoCharges,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final trayList = (json['tray'] as List).map((p) {
      if (p == null) return null;
      return PieceShape.fromJson(p as Map<String, dynamic>);
    }).toList();

    return GameState(
      mode: GameMode.values.firstWhere((m) => m.name == json['mode']),
      board: Board.fromJson(json['board'] as Map<String, dynamic>),
      tray: List.unmodifiable(trayList),
      score: json['score'] as int,
      linesClearedTotal: json['linesClearedTotal'] as int,
      currentCombo: json['currentCombo'] as int,
      bestCombo: json['bestCombo'] as int,
      noClearPlacementsStreak: json['noClearPlacementsStreak'] as int,
      movesCount: json['movesCount'] as int,
      seed: json['seed'] as int,
      isGameOver: json['isGameOver'] as bool,
      revivesUsed: json['revivesUsed'] as int,
      undoCharges: json['undoCharges'] as int,
    );
  }
}
