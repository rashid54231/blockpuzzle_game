import 'game_mode.dart';

/// Summarizes a completed game run.
/// Pure Dart class with zero Flutter dependencies.
class RunResult {
  final GameMode mode;
  final int score;
  final int lines;
  final int moves;
  final int bestCombo;
  final int seed;
  final bool revived;
  final DateTime endedAt;

  const RunResult({
    required this.mode,
    required this.score,
    required this.lines,
    required this.moves,
    required this.bestCombo,
    required this.seed,
    required this.revived,
    required this.endedAt,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'score': score,
    'lines': lines,
    'moves': moves,
    'bestCombo': bestCombo,
    'seed': seed,
    'revived': revived,
    'endedAt': endedAt.toIso8601String(),
  };

  factory RunResult.fromJson(Map<String, dynamic> json) => RunResult(
    mode: GameMode.values.firstWhere((m) => m.name == json['mode']),
    score: json['score'] as int,
    lines: json['lines'] as int,
    moves: json['moves'] as int,
    bestCombo: json['bestCombo'] as int,
    seed: json['seed'] as int,
    revived: json['revived'] as bool,
    endedAt: DateTime.parse(json['endedAt'] as String),
  );
}
