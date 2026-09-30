/// Represents a discrete 2D grid position on the board.
/// Pure Dart class with zero Flutter dependencies.
class BoardPoint {
  final int x;
  final int y;

  const BoardPoint(this.x, this.y);

  BoardPoint operator +(BoardPoint other) =>
      BoardPoint(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 4);

  @override
  String toString() => 'BoardPoint($x, $y)';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory BoardPoint.fromJson(Map<String, dynamic> json) =>
      BoardPoint(json['x'] as int, json['y'] as int);
}
