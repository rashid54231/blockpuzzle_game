import '../board/board_point.dart';
import 'piece_shape.dart';

/// Complete catalog of unrotatable shapes for Prism Blocks.
/// Pure Dart class with zero Flutter dependencies.
abstract final class PieceCatalog {
  // 1. Single Dot (1x1)
  static const PieceShape dot = PieceShape(
    id: 1,
    name: 'Single Dot',
    points: [BoardPoint(0, 0)],
    colorIndex: 0,
    shapeMark: 'circle',
  );

  // 2-3. Lines 2 (Horizontal and Vertical)
  static const PieceShape line2H = PieceShape(
    id: 2,
    name: 'Line 2H',
    points: [BoardPoint(0, 0), BoardPoint(1, 0)],
    colorIndex: 1,
    shapeMark: 'diamond',
  );

  static const PieceShape line2V = PieceShape(
    id: 3,
    name: 'Line 2V',
    points: [BoardPoint(0, 0), BoardPoint(0, 1)],
    colorIndex: 1,
    shapeMark: 'diamond',
  );

  // 4-5. Lines 3 (Horizontal and Vertical)
  static const PieceShape line3H = PieceShape(
    id: 4,
    name: 'Line 3H',
    points: [BoardPoint(0, 0), BoardPoint(1, 0), BoardPoint(2, 0)],
    colorIndex: 2,
    shapeMark: 'triangle',
  );

  static const PieceShape line3V = PieceShape(
    id: 5,
    name: 'Line 3V',
    points: [BoardPoint(0, 0), BoardPoint(0, 1), BoardPoint(0, 2)],
    colorIndex: 2,
    shapeMark: 'triangle',
  );

  // 6-7. Lines 4 (Horizontal and Vertical)
  static const PieceShape line4H = PieceShape(
    id: 6,
    name: 'Line 4H',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(3, 0),
    ],
    colorIndex: 3,
    shapeMark: 'square',
  );

  static const PieceShape line4V = PieceShape(
    id: 7,
    name: 'Line 4V',
    points: [
      BoardPoint(0, 0),
      BoardPoint(0, 1),
      BoardPoint(0, 2),
      BoardPoint(0, 3),
    ],
    colorIndex: 3,
    shapeMark: 'square',
  );

  // 8-9. Lines 5 (Horizontal and Vertical)
  static const PieceShape line5H = PieceShape(
    id: 8,
    name: 'Line 5H',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(3, 0),
      BoardPoint(4, 0),
    ],
    colorIndex: 4,
    shapeMark: 'star',
  );

  static const PieceShape line5V = PieceShape(
    id: 9,
    name: 'Line 5V',
    points: [
      BoardPoint(0, 0),
      BoardPoint(0, 1),
      BoardPoint(0, 2),
      BoardPoint(0, 3),
      BoardPoint(0, 4),
    ],
    colorIndex: 4,
    shapeMark: 'star',
  );

  // 10. Square 2x2
  static const PieceShape square2 = PieceShape(
    id: 10,
    name: 'Square 2x2',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
    ],
    colorIndex: 5,
    shapeMark: 'cross',
  );

  // 11. Square 3x3
  static const PieceShape square3 = PieceShape(
    id: 11,
    name: 'Square 3x3',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(2, 1),
      BoardPoint(0, 2),
      BoardPoint(1, 2),
      BoardPoint(2, 2),
    ],
    colorIndex: 6,
    shapeMark: 'hex',
  );

  // 12-13. Rectangles 2x3 and 3x2
  static const PieceShape rect2x3 = PieceShape(
    id: 12,
    name: 'Rectangle 2x3',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(0, 2),
      BoardPoint(1, 2),
    ],
    colorIndex: 7,
    shapeMark: 'diamond',
  );

  static const PieceShape rect3x2 = PieceShape(
    id: 13,
    name: 'Rectangle 3x2',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(2, 1),
    ],
    colorIndex: 7,
    shapeMark: 'diamond',
  );

  // 14-17. Small L / 2x2 Corner in 4 orientations
  static const PieceShape corner2TopLeft = PieceShape(
    id: 14,
    name: 'Corner 2 TL',
    points: [BoardPoint(0, 0), BoardPoint(1, 0), BoardPoint(0, 1)],
    colorIndex: 0,
    shapeMark: 'triangle',
  );

  static const PieceShape corner2TopRight = PieceShape(
    id: 15,
    name: 'Corner 2 TR',
    points: [BoardPoint(0, 0), BoardPoint(1, 0), BoardPoint(1, 1)],
    colorIndex: 0,
    shapeMark: 'triangle',
  );

  static const PieceShape corner2BottomLeft = PieceShape(
    id: 16,
    name: 'Corner 2 BL',
    points: [BoardPoint(0, 0), BoardPoint(0, 1), BoardPoint(1, 1)],
    colorIndex: 0,
    shapeMark: 'triangle',
  );

  static const PieceShape corner2BottomRight = PieceShape(
    id: 17,
    name: 'Corner 2 BR',
    points: [BoardPoint(1, 0), BoardPoint(0, 1), BoardPoint(1, 1)],
    colorIndex: 0,
    shapeMark: 'triangle',
  );

  // 18-21. Big L / 3x3 Corner in 4 orientations
  static const PieceShape corner3TopLeft = PieceShape(
    id: 18,
    name: 'Corner 3 TL',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(0, 1),
      BoardPoint(0, 2),
    ],
    colorIndex: 1,
    shapeMark: 'square',
  );

  static const PieceShape corner3TopRight = PieceShape(
    id: 19,
    name: 'Corner 3 TR',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(2, 1),
      BoardPoint(2, 2),
    ],
    colorIndex: 1,
    shapeMark: 'square',
  );

  static const PieceShape corner3BottomLeft = PieceShape(
    id: 20,
    name: 'Corner 3 BL',
    points: [
      BoardPoint(0, 0),
      BoardPoint(0, 1),
      BoardPoint(0, 2),
      BoardPoint(1, 2),
      BoardPoint(2, 2),
    ],
    colorIndex: 1,
    shapeMark: 'square',
  );

  static const PieceShape corner3BottomRight = PieceShape(
    id: 21,
    name: 'Corner 3 BR',
    points: [
      BoardPoint(2, 0),
      BoardPoint(2, 1),
      BoardPoint(0, 2),
      BoardPoint(1, 2),
      BoardPoint(2, 2),
    ],
    colorIndex: 1,
    shapeMark: 'square',
  );

  // 22-25. T Shapes in 4 orientations
  static const PieceShape tUp = PieceShape(
    id: 22,
    name: 'T Up',
    points: [
      BoardPoint(1, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(2, 1),
    ],
    colorIndex: 2,
    shapeMark: 'cross',
  );

  static const PieceShape tDown = PieceShape(
    id: 23,
    name: 'T Down',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(1, 1),
    ],
    colorIndex: 2,
    shapeMark: 'cross',
  );

  static const PieceShape tLeft = PieceShape(
    id: 24,
    name: 'T Left',
    points: [
      BoardPoint(1, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(1, 2),
    ],
    colorIndex: 2,
    shapeMark: 'cross',
  );

  static const PieceShape tRight = PieceShape(
    id: 25,
    name: 'T Right',
    points: [
      BoardPoint(0, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
      BoardPoint(0, 2),
    ],
    colorIndex: 2,
    shapeMark: 'cross',
  );

  // 26-27. S & Z Shapes Horizontal
  static const PieceShape sShapeH = PieceShape(
    id: 26,
    name: 'S Horizontal',
    points: [
      BoardPoint(1, 0),
      BoardPoint(2, 0),
      BoardPoint(0, 1),
      BoardPoint(1, 1),
    ],
    colorIndex: 3,
    shapeMark: 'star',
  );

  static const PieceShape zShapeH = PieceShape(
    id: 27,
    name: 'Z Horizontal',
    points: [
      BoardPoint(0, 0),
      BoardPoint(1, 0),
      BoardPoint(1, 1),
      BoardPoint(2, 1),
    ],
    colorIndex: 4,
    shapeMark: 'star',
  );

  // 28-29. Diagonal pairs (2 orientations)
  static const PieceShape diagDown = PieceShape(
    id: 28,
    name: 'Diagonal Down',
    points: [BoardPoint(0, 0), BoardPoint(1, 1)],
    colorIndex: 5,
    shapeMark: 'circle',
  );

  static const PieceShape diagUp = PieceShape(
    id: 29,
    name: 'Diagonal Up',
    points: [BoardPoint(1, 0), BoardPoint(0, 1)],
    colorIndex: 5,
    shapeMark: 'circle',
  );

  static const List<PieceShape> all = [
    dot,
    line2H,
    line2V,
    line3H,
    line3V,
    line4H,
    line4V,
    line5H,
    line5V,
    square2,
    square3,
    rect2x3,
    rect3x2,
    corner2TopLeft,
    corner2TopRight,
    corner2BottomLeft,
    corner2BottomRight,
    corner3TopLeft,
    corner3TopRight,
    corner3BottomLeft,
    corner3BottomRight,
    tUp,
    tDown,
    tLeft,
    tRight,
    sShapeH,
    zShapeH,
    diagDown,
    diagUp,
  ];

  static PieceShape? getById(int id) {
    for (final shape in all) {
      if (shape.id == id) return shape;
    }
    return null;
  }
}
