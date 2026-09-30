import '../board/board.dart';
import '../board/board_point.dart';
import '../generator/fair_piece_generator.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/move_record.dart';
import '../models/run_result.dart';
import '../pieces/piece_shape.dart';
import '../scoring/scoring_rules.dart';

/// Central state machine managing block puzzle gameplay.
/// Pure Dart class with ZERO Flutter or Flame imports.
class GameEngine {
  final FairPieceGenerator _generator;
  final List<MoveRecord> _history = [];
  late GameState _state;

  GameEngine({
    required GameMode mode,
    int? seed,
    int initialUndos = 2,
    GameState? restoredState,
  }) : _generator = FairPieceGenerator(
         seed ?? DateTime.now().millisecondsSinceEpoch,
       ) {
    if (restoredState != null) {
      _state = restoredState;
    } else {
      final initialSeed = seed ?? _generator.prng.state;
      final initialBoard = Board();
      final initialTray = _generator.generateTray(initialBoard, 0);

      _state = GameState(
        mode: mode,
        board: initialBoard,
        tray: List.unmodifiable(initialTray),
        score: 0,
        linesClearedTotal: 0,
        currentCombo: 0,
        bestCombo: 0,
        noClearPlacementsStreak: 0,
        movesCount: 0,
        seed: initialSeed,
        isGameOver: false,
        revivesUsed: 0,
        undoCharges: initialUndos,
      );
    }
  }

  GameState get state => _state;
  bool get canUndo =>
      _state.undoCharges > 0 && _history.isNotEmpty && !_state.isGameOver;

  /// Places the piece at [trayIndex] onto [origin] on the board.
  /// Returns `true` if move was valid and executed, `false` otherwise.
  bool placePiece({required int trayIndex, required BoardPoint origin}) {
    if (_state.isGameOver) return false;
    if (trayIndex < 0 || trayIndex >= _state.tray.length) return false;

    final shape = _state.tray[trayIndex];
    if (shape == null) return false;

    // Check legality
    if (!_state.board.canPlacePiece(shape, origin)) {
      return false;
    }

    // Capture pre-move state for undo history
    final preMoveBoard = _state.board;
    final preMoveScore = _state.score;
    final preMoveCombo = _state.currentCombo;
    final preMoveNoClearStreak = _state.noClearPlacementsStreak;
    final preMoveTray = List<PieceShape?>.from(_state.tray);

    // Place the piece on board
    final boardAfterPlacement = _state.board.placePiece(
      shape,
      origin,
      shape.colorIndex,
    );

    // Detect filled rows and columns simultaneously
    final linesToClear = boardAfterPlacement.findFilledLines();
    final clearedCount = linesToClear.totalLines;

    // Calculate updated board after clear
    final boardAfterClear = boardAfterPlacement.clearLines(linesToClear);
    final isPerfectClear = linesToClear.isNotEmpty && boardAfterClear.isEmpty;

    // Combo calculation
    int newCombo = _state.currentCombo;
    int newNoClearStreak = _state.noClearPlacementsStreak;

    if (clearedCount > 0) {
      newCombo += 1;
      newNoClearStreak = 0;
    } else {
      newNoClearStreak += 1;
      if (newNoClearStreak >= ScoringRules.comboGracePlacements) {
        newCombo = 0;
      }
    }

    final int bestCombo = newCombo > _state.bestCombo
        ? newCombo
        : _state.bestCombo;

    // Scoring calculation
    final scoreResult = ScoringRules.calculateScore(
      cellsPlaced: shape.cellCount,
      linesCleared: clearedCount,
      currentCombo: newCombo,
      isPerfectClear: isPerfectClear,
    );

    final newScore = _state.score + scoreResult.totalEarned;
    final newLinesTotal = _state.linesClearedTotal + clearedCount;
    final newMovesCount = _state.movesCount + 1;

    // Update tray: consume placed piece
    final newTray = List<PieceShape?>.from(_state.tray);
    newTray[trayIndex] = null;

    // If tray is empty, deal a fresh round of 3 pieces
    final bool trayEmptied = newTray.every((p) => p == null);
    if (trayEmptied) {
      final freshPieces = _generator.generateTray(boardAfterClear, newScore);
      for (int i = 0; i < freshPieces.length; i++) {
        newTray[i] = freshPieces[i];
      }
    }

    // Game Over check
    bool gameOver = false;
    if (_state.mode == GameMode.zen) {
      // In Zen mode: if no piece can be placed, board auto-clears instead of Game Over!
      bool anyPlaceable = false;
      for (final p in newTray) {
        if (p != null && boardAfterClear.canPlacePieceAnywhere(p)) {
          anyPlaceable = true;
          break;
        }
      }
      if (!anyPlaceable) {
        // Zen auto-clear
        final zenBoard = Board();
        _state = _state.copyWith(
          board: zenBoard,
          tray: List.unmodifiable(newTray),
          score: newScore,
          linesClearedTotal: newLinesTotal,
          currentCombo: 0,
          bestCombo: bestCombo,
          noClearPlacementsStreak: 0,
          movesCount: newMovesCount,
          isGameOver: false,
          lastScoreResult: scoreResult,
          lastClearedLines: linesToClear,
        );
        return true;
      }
    } else {
      // Classic / Daily modes
      bool anyPlaceable = false;
      for (final p in newTray) {
        if (p != null && boardAfterClear.canPlacePieceAnywhere(p)) {
          anyPlaceable = true;
          break;
        }
      }
      gameOver = !anyPlaceable;
    }

    // Save move to history
    _history.add(
      MoveRecord(
        moveIndex: _state.movesCount,
        pieceShape: shape,
        trayIndex: trayIndex,
        origin: origin,
        linesCleared: clearedCount,
        scoreEarned: scoreResult.totalEarned,
        previousBoard: preMoveBoard,
        previousScore: preMoveScore,
        previousCombo: preMoveCombo,
        previousNoClearStreak: preMoveNoClearStreak,
        previousTray: preMoveTray,
      ),
    );

    // Commit new state
    _state = _state.copyWith(
      board: boardAfterClear,
      tray: List.unmodifiable(newTray),
      score: newScore,
      linesClearedTotal: newLinesTotal,
      currentCombo: newCombo,
      bestCombo: bestCombo,
      noClearPlacementsStreak: newNoClearStreak,
      movesCount: newMovesCount,
      isGameOver: gameOver,
      lastScoreResult: scoreResult,
      lastClearedLines: linesToClear,
    );

    return true;
  }

  /// Exact undo operation. Reverts the last placed move using history.
  bool undo() {
    if (!canUndo) return false;

    final lastMove = _history.removeLast();

    _state = _state.copyWith(
      board: lastMove.previousBoard,
      tray: List.unmodifiable(lastMove.previousTray),
      score: lastMove.previousScore,
      currentCombo: lastMove.previousCombo,
      noClearPlacementsStreak: lastMove.previousNoClearStreak,
      movesCount: _state.movesCount > 0 ? _state.movesCount - 1 : 0,
      undoCharges: _state.undoCharges - 1,
      isGameOver: false,
      lastScoreResult: null,
      lastClearedLines: const LinesToClear(rows: [], columns: []),
    );

    return true;
  }

  /// Revive mechanic: clears a 3x3 center area, deals a fresh placeable tray, and resumes run.
  bool revive() {
    if (!_state.canRevive) return false;

    final revivedBoard = _state.board.clearReviveArea();
    final freshTray = _generator.generateTray(revivedBoard, _state.score);

    _state = _state.copyWith(
      board: revivedBoard,
      tray: List.unmodifiable(freshTray),
      isGameOver: false,
      revivesUsed: _state.revivesUsed + 1,
      noClearPlacementsStreak: 0,
      lastScoreResult: null,
      lastClearedLines: const LinesToClear(rows: [], columns: []),
    );

    return true;
  }

  void addUndoCharges(int amount) {
    _state = _state.copyWith(undoCharges: _state.undoCharges + amount);
  }

  RunResult createRunResult() {
    return RunResult(
      mode: _state.mode,
      score: _state.score,
      lines: _state.linesClearedTotal,
      moves: _state.movesCount,
      bestCombo: _state.bestCombo,
      seed: _state.seed,
      revived: _state.revivesUsed > 0,
      endedAt: DateTime.now(),
    );
  }
}
