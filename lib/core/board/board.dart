import 'board_point.dart';
import 'cell.dart';
import '../pieces/piece_shape.dart';

/// Immutable representation of the 8x8 block puzzle grid.
/// Pure Dart class with zero Flutter dependencies.
class Board {
  static const int size = 8;
  final List<Cell> _cells;

  Board({List<Cell>? cells})
    : _cells = cells != null
          ? List<Cell>.unmodifiable(cells)
          : List<Cell>.filled(size * size, Cell.empty, growable: false);

  Cell getCell(int x, int y) {
    if (!isInBounds(x, y)) return Cell.empty;
    return _cells[y * size + x];
  }

  bool isInBounds(int x, int y) => x >= 0 && x < size && y >= 0 && y < size;

  bool isCellEmpty(int x, int y) => getCell(x, y).isEmpty;

  int get filledCellCount {
    int count = 0;
    for (final c in _cells) {
      if (c.isFilled) count++;
    }
    return count;
  }

  bool get isEmpty => filledCellCount == 0;

  bool get isFull => filledCellCount == size * size;

  /// Validates whether a [PieceShape] can be placed at an origin coordinate [origin].
  bool canPlacePiece(PieceShape shape, BoardPoint origin) {
    for (final p in shape.points) {
      final targetX = origin.x + p.x;
      final targetY = origin.y + p.y;
      if (!isInBounds(targetX, targetY)) return false;
      if (!isCellEmpty(targetX, targetY)) return false;
    }
    return true;
  }

  /// Checks if [shape] can be placed anywhere on this board.
  bool canPlacePieceAnywhere(PieceShape shape) {
    for (int y = 0; y <= size - shape.height; y++) {
      for (int x = 0; x <= size - shape.width; x++) {
        if (canPlacePiece(shape, BoardPoint(x, y))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Places [shape] at [origin] with [colorId] and returns a new updated [Board].
  Board placePiece(PieceShape shape, BoardPoint origin, int colorId) {
    final newCells = List<Cell>.from(_cells);
    for (final p in shape.points) {
      final targetX = origin.x + p.x;
      final targetY = origin.y + p.y;
      newCells[targetY * size + targetX] = Cell(colorId: colorId);
    }
    return Board(cells: newCells);
  }

  /// Finds all fully filled rows and columns simultaneously.
  LinesToClear findFilledLines() {
    final rows = <int>[];
    final cols = <int>[];

    // Check rows
    for (int y = 0; y < size; y++) {
      bool rowFull = true;
      for (int x = 0; x < size; x++) {
        if (isCellEmpty(x, y)) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) rows.add(y);
    }

    // Check columns
    for (int x = 0; x < size; x++) {
      bool colFull = true;
      for (int y = 0; y < size; y++) {
        if (isCellEmpty(x, y)) {
          colFull = false;
          break;
        }
      }
      if (colFull) cols.add(x);
    }

    return LinesToClear(rows: rows, columns: cols);
  }

  /// Clears the specified rows and columns simultaneously and returns the new [Board].
  Board clearLines(LinesToClear lines) {
    if (lines.isEmpty) return this;

    final newCells = List<Cell>.from(_cells);

    for (final y in lines.rows) {
      for (int x = 0; x < size; x++) {
        newCells[y * size + x] = Cell.empty;
      }
    }

    for (final x in lines.columns) {
      for (int y = 0; y < size; y++) {
        newCells[y * size + x] = Cell.empty;
      }
    }

    return Board(cells: newCells);
  }

  /// Projects what lines WOULD clear if [shape] was placed at [origin].
  LinesToClear previewClearedLines(PieceShape shape, BoardPoint origin) {
    if (!canPlacePiece(shape, origin)) {
      return const LinesToClear(rows: [], columns: []);
    }
    final hypotheticalBoard = placePiece(shape, origin, 999);
    return hypotheticalBoard.findFilledLines();
  }

  /// Revive clearance: clears a 3x3 centered area around the board center.
  Board clearReviveArea() {
    final newCells = List<Cell>.from(_cells);
    const startX = 2;
    const startY = 2;
    for (int y = startY; y < startY + 4; y++) {
      for (int x = startX; x < startX + 4; x++) {
        newCells[y * size + x] = Cell.empty;
      }
    }
    return Board(cells: newCells);
  }

  Map<String, dynamic> toJson() => {
    'cells': _cells.map((c) => c.toJson()).toList(),
  };

  factory Board.fromJson(Map<String, dynamic> json) {
    final list = (json['cells'] as List)
        .map((item) => Cell.fromJson(item as Map<String, dynamic>))
        .toList();
    return Board(cells: list);
  }
}

class LinesToClear {
  final List<int> rows;
  final List<int> columns;

  const LinesToClear({required this.rows, required this.columns});

  int get totalLines => rows.length + columns.length;
  bool get isEmpty => rows.isEmpty && columns.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
