import 'package:flutter/material.dart';

enum GameThemeId { neon, ocean, sunset, forest, candy, monochrome }

class GameThemeData {
  final GameThemeId id;
  final String name;
  final int costCoins;
  final int costGems;
  final bool isDefaultUnlocked;
  final Color boardBackground;
  final Color gridLineColor;
  final Color cellEmptyColor;
  final List<Color> piecePalette;
  final LinearGradient backgroundGradient;

  const GameThemeData({
    required this.id,
    required this.name,
    required this.costCoins,
    required this.costGems,
    required this.isDefaultUnlocked,
    required this.boardBackground,
    required this.gridLineColor,
    required this.cellEmptyColor,
    required this.piecePalette,
    required this.backgroundGradient,
  });

  Color colorForPiece(int pieceId) {
    if (piecePalette.isEmpty) return const Color(0xFF00E5FF);
    return piecePalette[pieceId.abs() % piecePalette.length];
  }
}

abstract final class GameThemes {
  static const GameThemeData neon = GameThemeData(
    id: GameThemeId.neon,
    name: 'Neon Prism',
    costCoins: 0,
    costGems: 0,
    isDefaultUnlocked: true,
    boardBackground: Color(0xFF101426),
    gridLineColor: Color(0x1AFFFFFF),
    cellEmptyColor: Color(0xFF171D36),
    piecePalette: [
      Color(0xFF00E5FF), // Cyan
      Color(0xFFFF007F), // Magenta
      Color(0xFFFFD600), // Yellow
      Color(0xFF00E676), // Green
      Color(0xFFFF6D00), // Orange
      Color(0xFF7C4DFF), // Purple
      Color(0xFF2979FF), // Blue
      Color(0xFFFF1744), // Coral Red
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF090B14), Color(0xFF14192E)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const GameThemeData ocean = GameThemeData(
    id: GameThemeId.ocean,
    name: 'Ocean Depths',
    costCoins: 500,
    costGems: 0,
    isDefaultUnlocked: false,
    boardBackground: Color(0xFF071B26),
    gridLineColor: Color(0x1A00E5FF),
    cellEmptyColor: Color(0xFF0B2838),
    piecePalette: [
      Color(0xFF00B0FF),
      Color(0xFF00E5FF),
      Color(0xFF1DE9B6),
      Color(0xFF0091EA),
      Color(0xFF80D8FF),
      Color(0xFF64FFDA),
      Color(0xFF40C4FF),
      Color(0xFF00BFA5),
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF030D14), Color(0xFF0A2333)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const GameThemeData sunset = GameThemeData(
    id: GameThemeId.sunset,
    name: 'Sunset Glow',
    costCoins: 800,
    costGems: 0,
    isDefaultUnlocked: false,
    boardBackground: Color(0xFF24101A),
    gridLineColor: Color(0x20FF80AB),
    cellEmptyColor: Color(0xFF331625),
    piecePalette: [
      Color(0xFFFF5252),
      Color(0xFFFF4081),
      Color(0xFFFFAB40),
      Color(0xFFFF6E40),
      Color(0xFFFFD740),
      Color(0xFFE040FB),
      Color(0xFFFF1744),
      Color(0xFFFF9100),
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF14080F), Color(0xFF321324)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const GameThemeData forest = GameThemeData(
    id: GameThemeId.forest,
    name: 'Emerald Forest',
    costCoins: 1200,
    costGems: 0,
    isDefaultUnlocked: false,
    boardBackground: Color(0xFF0B1F14),
    gridLineColor: Color(0x2069F0AE),
    cellEmptyColor: Color(0xFF102E1E),
    piecePalette: [
      Color(0xFF00E676),
      Color(0xFF76FF03),
      Color(0xFF1DE9B6),
      Color(0xFF64DD17),
      Color(0xFFAEEA00),
      Color(0xFF00BFA5),
      Color(0xFFB2FF59),
      Color(0xFF00C853),
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF05100A), Color(0xFF0E281A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const GameThemeData candy = GameThemeData(
    id: GameThemeId.candy,
    name: 'Candy Dream',
    costCoins: 0,
    costGems: 25,
    isDefaultUnlocked: false,
    boardBackground: Color(0xFF24122E),
    gridLineColor: Color(0x25EA80FC),
    cellEmptyColor: Color(0xFF341A42),
    piecePalette: [
      Color(0xFFFF80AB),
      Color(0xFFEA80FC),
      Color(0xFF82B1FF),
      Color(0xFFFFD180),
      Color(0xFFB9F6CA),
      Color(0xFFFF9E80),
      Color(0xFFF48FB1),
      Color(0xFFCE93D8),
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF14071A), Color(0xFF361845)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const GameThemeData monochrome = GameThemeData(
    id: GameThemeId.monochrome,
    name: 'Obsidian Noir',
    costCoins: 0,
    costGems: 50,
    isDefaultUnlocked: false,
    boardBackground: Color(0xFF121212),
    gridLineColor: Color(0x20FFFFFF),
    cellEmptyColor: Color(0xFF1E1E1E),
    piecePalette: [
      Color(0xFFFFFFFF),
      Color(0xFFE0E0E0),
      Color(0xFFBDBDBD),
      Color(0xFF9E9E9E),
      Color(0xFFEEEEEE),
      Color(0xFFCCCCCC),
      Color(0xFF757575),
      Color(0xFFF5F5F5),
    ],
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const List<GameThemeData> all = [
    neon,
    ocean,
    sunset,
    forest,
    candy,
    monochrome,
  ];

  static GameThemeData fromId(String idStr) {
    for (final theme in all) {
      if (theme.id.name == idStr) return theme;
    }
    return neon;
  }
}
