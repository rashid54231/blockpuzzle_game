import '../board/board_point.dart';

/// Defines an unrotatable puzzle piece shape.
/// Pure Dart class with zero Flutter dependencies.
class PieceShape {
  final int id;
  final String name;
  final List<BoardPoint> points;
  final int colorIndex;
  final String shapeMark; // For colorblind accessibility pattern

  const PieceShape({
    required this.id,
    required this.name,
    required this.points,
    required this.colorIndex,
    required this.shapeMark,
  });

  int get cellCount => points.length;

  int get width {
    if (points.isEmpty) return 0;
    int maxX = points.first.x;
    for (final p in points) {
      if (p.x > maxX) maxX = p.x;
    }
    return maxX + 1;
  }

  int get height {
    if (points.isEmpty) return 0;
    int maxY = points.first.y;
    for (final p in points) {
      if (p.y > maxY) maxY = p.y;
    }
    return maxY + 1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'points': points.map((p) => p.toJson()).toList(),
    'colorIndex': colorIndex,
    'shapeMark': shapeMark,
  };

  factory PieceShape.fromJson(Map<String, dynamic> json) => PieceShape(
    id: json['id'] as int,
    name: json['name'] as String,
    points: (json['points'] as List)
        .map((p) => BoardPoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    colorIndex: json['colorIndex'] as int,
    shapeMark: json['shapeMark'] as String? ?? 'circle',
  );
}
