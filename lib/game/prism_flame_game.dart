import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/board/board.dart';
import '../core/board/board_point.dart';
import '../core/engine/game_engine.dart';
import '../core/pieces/piece_shape.dart';
import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';
import '../shared/theme/game_theme.dart';
import 'effects/floating_text.dart';
import 'effects/particle_system.dart';
import 'effects/screen_shake.dart';
import 'painters/block_painter.dart';

class PrismFlameGame extends FlameGame with DragCallbacks {
  final GameEngine engine;
  final AudioService audio;
  final HapticsService haptics;
  GameThemeData theme;
  bool isColorblind;

  final VoidCallback onStateChanged;
  final VoidCallback onGameOver;

  // Effects
  final ParticleManager particleManager = ParticleManager();
  final ScreenShake screenShake = ScreenShake();
  final FloatingTextManager textManager = FloatingTextManager();

  // Layout metrics
  double boardSize = 0.0;
  double cellSize = 0.0;
  Offset boardTopLeft = Offset.zero;

  double trayY = 0.0;
  double trayHeight = 0.0;
  final List<Rect> traySlotRects = [Rect.zero, Rect.zero, Rect.zero];

  // Drag state
  int? draggingTrayIndex;
  Offset? currentDragPosition;
  Offset? dragStartOrigin;
  BoardPoint? hoveredBoardOrigin;
  bool isHoveredPlacementValid = false;
  LinesToClear projectedClearedLines = const LinesToClear(
    rows: [],
    columns: [],
  );

  // Return to tray animation
  int? returningTrayIndex;
  Offset? returnCurrentPos;
  Offset? returnTargetPos;
  double returnProgress = 1.0;

  // Clearing animation
  LinesToClear activeClearingLines = const LinesToClear(rows: [], columns: []);
  double lineClearProgress = 1.0;

  // Reusable paints to avoid per-frame allocations & GPU churn
  final Paint _boardGlowPaint = Paint()
    ..color = const Color(0x2200E5FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  final Paint _boardBgPaint = Paint();
  final Paint _boardBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _gridPaint = Paint()
    ..color = const Color(0x12FFFFFF)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;
  final Paint _dotPaint = Paint()..color = const Color(0x18FFFFFF);
  final Paint _projectedHighlightPaint = Paint()..color = const Color(0x4000E5FF);
  final Paint _projectedStrokePaint = Paint()
    ..color = const Color(0x8800E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final Paint _trayGlowPaint = Paint()
    ..color = const Color(0x1800E5FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
  final Paint _trayBgPaint = Paint();
  final Paint _trayBorderPaint = Paint()
    ..color = const Color(0x30FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Paint _slotBgPaint = Paint()..color = const Color(0x18FFFFFF);
  final Paint _slotBorderPaint = Paint()
    ..color = const Color(0x20FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _divPaint = Paint()
    ..color = const Color(0x15FFFFFF)
    ..strokeWidth = 1.0;
  final Paint _emptySlotPaint = Paint()
    ..color = const Color(0x20FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  PrismFlameGame({
    required this.engine,
    required this.audio,
    required this.haptics,
    required this.theme,
    required this.isColorblind,
    required this.onStateChanged,
    required this.onGameOver,
  });

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _calculateLayout(size.x, size.y);
  }

  void updateTheme(GameThemeData newTheme, bool colorblind) {
    theme = newTheme;
    isColorblind = colorblind;
    if (boardSize > 0) {
      final boardRect = Rect.fromLTWH(
        boardTopLeft.dx,
        boardTopLeft.dy,
        boardSize,
        boardSize,
      );
      _boardBgPaint.shader = LinearGradient(
        colors: [
          theme.boardBackground,
          Color.lerp(theme.boardBackground, const Color(0xFF0A0E20), 0.5)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(boardRect);
    }
  }

  void _calculateLayout(double screenW, double screenH) {
    // Board is 8x8 square centered horizontally in upper portion
    final margin = 20.0;
    boardSize = math.min(screenW - (margin * 2), screenH * 0.52);
    cellSize = boardSize / Board.size;

    final boardX = (screenW - boardSize) / 2;
    final boardY = math.max(16.0, screenH * 0.08);
    boardTopLeft = Offset(boardX, boardY);

    // Tray is positioned below the board
    trayY = boardTopLeft.dy + boardSize + 32.0;
    trayHeight = math.min(130.0, screenH - trayY - 24.0);

    final slotW = (screenW - (margin * 2)) / 3;
    for (int i = 0; i < 3; i++) {
      traySlotRects[i] = Rect.fromLTWH(
        margin + (i * slotW),
        trayY,
        slotW,
        trayHeight,
      );
    }

    // Pre-cache board shaders
    final boardRect = Rect.fromLTWH(
      boardTopLeft.dx,
      boardTopLeft.dy,
      boardSize,
      boardSize,
    );
    _boardBgPaint.shader = LinearGradient(
      colors: [
        theme.boardBackground,
        Color.lerp(theme.boardBackground, const Color(0xFF0A0E20), 0.5)!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(boardRect);

    _boardBorderPaint.shader = const LinearGradient(
      colors: [Color(0x55FFFFFF), Color(0x15FFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(boardRect);

    // Pre-cache tray shaders
    final panelMargin = 14.0;
    final panelRect = Rect.fromLTWH(
      panelMargin,
      trayY - 14,
      screenW - panelMargin * 2,
      trayHeight + 28,
    );
    _trayBgPaint.shader = const LinearGradient(
      colors: [Color(0xFF161B2E), Color(0xFF0F1226)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(panelRect);
  }

  @override
  void update(double dt) {
    super.update(dt);
    particleManager.update(dt);
    screenShake.update(dt);
    textManager.update(dt);

    // Return to tray animation
    if (returnProgress < 1.0 &&
        returnCurrentPos != null &&
        returnTargetPos != null) {
      returnProgress += dt * 5.0; // ~200ms
      if (returnProgress >= 1.0) {
        returnProgress = 1.0;
        returningTrayIndex = null;
        returnCurrentPos = null;
      } else {
        returnCurrentPos = Offset.lerp(
          returnCurrentPos,
          returnTargetPos,
          dt * 25,
        );
      }
    }

    // Line clearing animation
    if (lineClearProgress < 1.0) {
      lineClearProgress += dt * 4.0; // 250ms
      if (lineClearProgress >= 1.0) {
        lineClearProgress = 1.0;
        activeClearingLines = const LinesToClear(rows: [], columns: []);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    // Screen shake offset
    final shake = screenShake.offset;
    if (shake != Offset.zero) {
      canvas.translate(shake.dx, shake.dy);
    }

    _renderBoard(canvas);
    _renderGhostPreview(canvas);
    _renderTray(canvas);
    _renderDraggingPiece(canvas);
    _renderReturningPiece(canvas);

    // Particles and texts on top
    particleManager.render(canvas);
    textManager.render(canvas);

    canvas.restore();
  }

  void _renderBoard(Canvas canvas) {
    final boardRect = Rect.fromLTWH(
      boardTopLeft.dx,
      boardTopLeft.dy,
      boardSize,
      boardSize,
    );
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(20),
    );

    // Outer glow shadow
    canvas.drawRRect(boardRRect.shift(const Offset(0, 4)), _boardGlowPaint);

    // Board gradient backdrop
    canvas.drawRRect(boardRRect, _boardBgPaint);

    // Inner border highlight (top-left brighter)
    canvas.drawRRect(boardRRect, _boardBorderPaint);

    // Subtle grid lines (instead of drawing per-cell empty backgrounds)
    for (int i = 1; i < Board.size; i++) {
      // Vertical
      canvas.drawLine(
        Offset(boardTopLeft.dx + i * cellSize, boardTopLeft.dy + 4),
        Offset(boardTopLeft.dx + i * cellSize, boardTopLeft.dy + boardSize - 4),
        _gridPaint,
      );
      // Horizontal
      canvas.drawLine(
        Offset(boardTopLeft.dx + 4, boardTopLeft.dy + i * cellSize),
        Offset(boardTopLeft.dx + boardSize - 4, boardTopLeft.dy + i * cellSize),
        _gridPaint,
      );
    }

    // Grid cells
    for (int y = 0; y < Board.size; y++) {
      for (int x = 0; x < Board.size; x++) {
        final cellRect = Rect.fromLTWH(
          boardTopLeft.dx + (x * cellSize),
          boardTopLeft.dy + (y * cellSize),
          cellSize,
          cellSize,
        );

        // Empty cell — subtle dot instead of full rectangle (less visual noise)
        canvas.drawCircle(
          cellRect.center,
          cellSize * 0.08,
          _dotPaint,
        );

        // Projected line clear highlight
        final isProjectedRow = projectedClearedLines.rows.contains(y);
        final isProjectedCol = projectedClearedLines.columns.contains(x);
        if (isProjectedRow || isProjectedCol) {
          final deflated = RRect.fromRectAndRadius(
            cellRect.deflate(cellRect.width * 0.05),
            Radius.circular(cellRect.width * 0.18),
          );
          canvas.drawRRect(deflated, _projectedHighlightPaint);
          canvas.drawRRect(deflated, _projectedStrokePaint);
        }

        // Active placed block
        final cell = engine.state.board.getCell(x, y);
        if (cell.isFilled) {
          final color = theme.colorForPiece(cell.colorId!);
          final isClearing =
              activeClearingLines.rows.contains(y) ||
              activeClearingLines.columns.contains(x);

          BlockPainter.drawBlock(
            canvas,
            cellRect,
            baseColor: color,
            shapeMark: isColorblind
                ? _getShapeMarkForColor(cell.colorId!)
                : null,
            isClearing: isClearing,
            clearProgress: lineClearProgress,
          );
        }
      }
    }
  }

  void _renderGhostPreview(Canvas canvas) {
    if (draggingTrayIndex == null || hoveredBoardOrigin == null) return;
    final shape = engine.state.tray[draggingTrayIndex!];
    if (shape == null) return;

    for (final p in shape.points) {
      final targetX = hoveredBoardOrigin!.x + p.x;
      final targetY = hoveredBoardOrigin!.y + p.y;
      if (engine.state.board.isInBounds(targetX, targetY)) {
        final rect = Rect.fromLTWH(
          boardTopLeft.dx + (targetX * cellSize),
          boardTopLeft.dy + (targetY * cellSize),
          cellSize,
          cellSize,
        );

        BlockPainter.drawBlock(
          canvas,
          rect,
          baseColor: theme.colorForPiece(shape.colorIndex),
          shapeMark: isColorblind ? shape.shapeMark : null,
          isGhost: true,
          isInvalid: !isHoveredPlacementValid,
        );
      }
    }
  }

  void _renderTray(Canvas canvas) {
    final screenW = size.x;

    // ── Tray panel background ────────────────────────────────────────
    final panelMargin = 14.0;
    final panelRect = Rect.fromLTWH(
      panelMargin,
      trayY - 14,
      screenW - panelMargin * 2,
      trayHeight + 28,
    );
    final panelRRect = RRect.fromRectAndRadius(
      panelRect,
      const Radius.circular(20),
    );

    // Panel shadow/glow
    canvas.drawRRect(panelRRect, _trayGlowPaint);

    // Panel gradient fill
    canvas.drawRRect(panelRRect, _trayBgPaint);

    // Panel border
    canvas.drawRRect(panelRRect, _trayBorderPaint);

    // ── Slot backgrounds ─────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final slot = traySlotRects[i];
      if (i == draggingTrayIndex) continue;

      final slotRRect = RRect.fromRectAndRadius(
        slot.deflate(4),
        const Radius.circular(14),
      );

      // Slot fill & border
      canvas.drawRRect(slotRRect, _slotBgPaint);
      canvas.drawRRect(slotRRect, _slotBorderPaint);
    }

    // ── Slot dividers ────────────────────────────────────────────────
    for (int i = 1; i < 3; i++) {
      final x = traySlotRects[i].left;
      canvas.drawLine(
        Offset(x, trayY),
        Offset(x, trayY + trayHeight),
        _divPaint,
      );
    }

    // ── Pieces ───────────────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      if (i == draggingTrayIndex || i == returningTrayIndex) continue;
      final piece = engine.state.tray[i];
      if (piece == null) {
        // Empty slot indicator
        final slot = traySlotRects[i];
        final cx = slot.center.dx;
        final cy = slot.center.dy;
        const r = 10.0;
        canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), _emptySlotPaint);
        canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), _emptySlotPaint);
        continue;
      }

      final slot = traySlotRects[i];
      _renderPieceInRect(canvas, piece, slot, isDragging: false);
    }
  }

  void _renderDraggingPiece(Canvas canvas) {
    if (draggingTrayIndex == null || currentDragPosition == null) return;
    final piece = engine.state.tray[draggingTrayIndex!];
    if (piece == null) return;

    // Piece is offset above finger so user can clearly see it
    const fingerOffsetY = -70.0;
    final center = currentDragPosition! + const Offset(0, fingerOffsetY);
    final pieceW = piece.width * cellSize;
    final pieceH = piece.height * cellSize;

    final pieceTopLeft = Offset(
      center.dx - (pieceW / 2),
      center.dy - (pieceH / 2),
    );

    for (final p in piece.points) {
      final rect = Rect.fromLTWH(
        pieceTopLeft.dx + (p.x * cellSize),
        pieceTopLeft.dy + (p.y * cellSize),
        cellSize,
        cellSize,
      );

      BlockPainter.drawBlock(
        canvas,
        rect,
        baseColor: theme.colorForPiece(piece.colorIndex),
        shapeMark: isColorblind ? piece.shapeMark : null,
        isInvalid: !isHoveredPlacementValid && hoveredBoardOrigin != null,
      );
    }
  }

  void _renderReturningPiece(Canvas canvas) {
    if (returningTrayIndex == null || returnCurrentPos == null) return;
    final piece = engine.state.tray[returningTrayIndex!];
    if (piece == null) return;

    final pieceW = piece.width * cellSize * 0.7;
    final pieceH = piece.height * cellSize * 0.7;

    final topLeft = Offset(
      returnCurrentPos!.dx - (pieceW / 2),
      returnCurrentPos!.dy - (pieceH / 2),
    );

    for (final p in piece.points) {
      final rect = Rect.fromLTWH(
        topLeft.dx + (p.x * cellSize * 0.7),
        topLeft.dy + (p.y * cellSize * 0.7),
        cellSize * 0.7,
        cellSize * 0.7,
      );

      BlockPainter.drawBlock(
        canvas,
        rect,
        baseColor: theme.colorForPiece(piece.colorIndex),
        shapeMark: isColorblind ? piece.shapeMark : null,
      );
    }
  }

  void _renderPieceInRect(
    Canvas canvas,
    PieceShape piece,
    Rect slot, {
    required bool isDragging,
  }) {
    // Fit piece inside tray slot preview
    final slotCellSize = math.min(slot.width / 4.2, slot.height / 4.2);
    final pieceW = piece.width * slotCellSize;
    final pieceH = piece.height * slotCellSize;

    final startX = slot.center.dx - (pieceW / 2);
    final startY = slot.center.dy - (pieceH / 2);

    for (final p in piece.points) {
      final rect = Rect.fromLTWH(
        startX + (p.x * slotCellSize),
        startY + (p.y * slotCellSize),
        slotCellSize,
        slotCellSize,
      );

      BlockPainter.drawBlock(
        canvas,
        rect,
        baseColor: theme.colorForPiece(piece.colorIndex),
        shapeMark: isColorblind ? piece.shapeMark : null,
      );
    }
  }

  String _getShapeMarkForColor(int colorIndex) {
    const marks = [
      'circle',
      'diamond',
      'triangle',
      'square',
      'cross',
      'hex',
      'star',
      'diamond',
    ];
    return marks[colorIndex % marks.length];
  }

  // --- Drag and Drop Handling ---

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final touchPos = Offset(event.canvasPosition.x, event.canvasPosition.y);

    for (int i = 0; i < 3; i++) {
      if (engine.state.tray[i] != null && traySlotRects[i].contains(touchPos)) {
        draggingTrayIndex = i;
        currentDragPosition = touchPos;
        dragStartOrigin = traySlotRects[i].center;
        audio.playSfx('pickup', pitch: 1.1);
        haptics.light();
        break;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (draggingTrayIndex == null) return;

    final touchPos = Offset(
      event.canvasEndPosition.x,
      event.canvasEndPosition.y,
    );
    currentDragPosition = touchPos;

    // Projected landing spot on board
    const fingerOffsetY = -70.0;
    final pieceCenter = touchPos + const Offset(0, fingerOffsetY);
    final shape = engine.state.tray[draggingTrayIndex!];
    if (shape == null) return;

    final pieceTopLeft = Offset(
      pieceCenter.dx - (shape.width * cellSize / 2),
      pieceCenter.dy - (shape.height * cellSize / 2),
    );

    // Calculate snapped grid origin
    final relativeX = (pieceTopLeft.dx - boardTopLeft.dx) / cellSize;
    final relativeY = (pieceTopLeft.dy - boardTopLeft.dy) / cellSize;

    final snappedX = relativeX.round();
    final snappedY = relativeY.round();

    final isWithinReach = snappedX >= -1 &&
        snappedX <= Board.size &&
        snappedY >= -1 &&
        snappedY <= Board.size;

    final candidateOrigin = isWithinReach ? BoardPoint(snappedX, snappedY) : null;

    // HIGH-PERFORMANCE EARLY EXIT: Skip redundant board tests when hovering the exact same cell
    if (candidateOrigin == hoveredBoardOrigin) {
      return;
    }

    if (candidateOrigin != null &&
        engine.state.board.canPlacePiece(shape, candidateOrigin)) {
      hoveredBoardOrigin = candidateOrigin;
      isHoveredPlacementValid = true;
      projectedClearedLines = engine.state.board.previewClearedLines(
        shape,
        candidateOrigin,
      );
    } else if (candidateOrigin != null) {
      hoveredBoardOrigin = candidateOrigin;
      isHoveredPlacementValid = false;
      projectedClearedLines = const LinesToClear(rows: [], columns: []);
    } else {
      hoveredBoardOrigin = null;
      isHoveredPlacementValid = false;
      projectedClearedLines = const LinesToClear(rows: [], columns: []);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (draggingTrayIndex == null) return;

    final trayIdx = draggingTrayIndex!;
    final shape = engine.state.tray[trayIdx];

    if (shape != null &&
        hoveredBoardOrigin != null &&
        isHoveredPlacementValid) {
      // Execute valid placement
      final success = engine.placePiece(
        trayIndex: trayIdx,
        origin: hoveredBoardOrigin!,
      );

      if (success) {
        audio.playSfx('place', pitch: 1.0);
        haptics.medium();

        final linesCleared = engine.state.lastClearedLines;
        final scoreResult = engine.state.lastScoreResult;

        // Line clear celebration
        if (linesCleared.isNotEmpty) {
          activeClearingLines = linesCleared;
          lineClearProgress = 0.0;
          screenShake.trigger(linesCleared: linesCleared.totalLines);

          // Audio pitch rises with combo
          final comboPitch = (1.0 + (engine.state.currentCombo * 0.15)).clamp(
            1.0,
            1.8,
          );
          audio.playSfx('clear', pitch: comboPitch);

          if (linesCleared.totalLines >= 3) {
            haptics.heavy();
          } else {
            haptics.medium();
          }

          // Particles along cleared cells — batched for performance
          final pieceColor = theme.colorForPiece(shape.colorIndex);

          for (final y in linesCleared.rows) {
            final centers = List.generate(Board.size, (x) => Offset(
              boardTopLeft.dx + (x * cellSize) + (cellSize / 2),
              boardTopLeft.dy + (y * cellSize) + (cellSize / 2),
            ));
            particleManager.spawnLineClear(
              cellCenters: centers,
              color: pieceColor,
            );
          }

          for (final x in linesCleared.columns) {
            final centers = List.generate(Board.size, (y) => Offset(
              boardTopLeft.dx + (x * cellSize) + (cellSize / 2),
              boardTopLeft.dy + (y * cellSize) + (cellSize / 2),
            ));
            particleManager.spawnLineClear(
              cellCenters: centers,
              color: pieceColor,
            );
          }

          // Line count floating text (double, triple, etc.)
          textManager.addLineClearText(
            Offset(
              boardTopLeft.dx + (boardSize / 2),
              boardTopLeft.dy + (boardSize * 0.65),
            ),
            linesCleared.totalLines,
          );

          // Floating score text
          final centerOfBoard = Offset(
            boardTopLeft.dx + (boardSize / 2),
            boardTopLeft.dy + (boardSize / 2),
          );

          if (scoreResult != null) {
            textManager.addScoreText(centerOfBoard, scoreResult.totalEarned);
          }

          // Floating combo text
          if (engine.state.currentCombo >= 2) {
            textManager.addComboText(centerOfBoard, engine.state.currentCombo);
            audio.playSfx('combo', pitch: comboPitch);
          }

          // Perfect clear check
          if (engine.state.board.isEmpty) {
            textManager.addPerfectClearText(centerOfBoard);
            audio.playSfx('perfect_clear');
            haptics.success();
          }
        }

        onStateChanged();

        if (engine.state.isGameOver) {
          audio.playSfx('game_over');
          onGameOver();
        }
      } else {
        _animateReturnToTray(trayIdx);
      }
    } else {
      // Invalid drop: return to tray with spring animation
      audio.playSfx('invalid', pitch: 0.9);
      haptics.light();
      _animateReturnToTray(trayIdx);
    }

    _clearDragState();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (draggingTrayIndex != null) {
      _animateReturnToTray(draggingTrayIndex!);
      _clearDragState();
    }
  }

  void _animateReturnToTray(int trayIdx) {
    returningTrayIndex = trayIdx;
    returnCurrentPos = currentDragPosition ?? traySlotRects[trayIdx].center;
    returnTargetPos = traySlotRects[trayIdx].center;
    returnProgress = 0.0;
  }

  void _clearDragState() {
    draggingTrayIndex = null;
    currentDragPosition = null;
    hoveredBoardOrigin = null;
    isHoveredPlacementValid = false;
    projectedClearedLines = const LinesToClear(rows: [], columns: []);
  }
}
