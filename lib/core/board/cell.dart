/// Represents an individual cell on the 8x8 puzzle board.
/// Pure Dart class with zero Flutter dependencies.
class Cell {
  final int? colorId;

  const Cell({this.colorId});

  bool get isEmpty => colorId == null;
  bool get isFilled => colorId != null;

  static const Cell empty = Cell(colorId: null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          colorId == other.colorId;

  @override
  int get hashCode => colorId.hashCode;

  Map<String, dynamic> toJson() => {'colorId': colorId};

  factory Cell.fromJson(Map<String, dynamic> json) =>
      Cell(colorId: json['colorId'] as int?);
}
