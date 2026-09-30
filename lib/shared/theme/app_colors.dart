import 'package:flutter/material.dart';

/// Semantic and core color palette for Prism Blocks.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D101D);
  static const Color surface = Color(0xFF161B2E);
  static const Color surfaceLight = Color(0xFF1E253D);
  static const Color glassBackground = Color(0x331E253D);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassBorderHighlight = Color(0x4DFFFFFF);

  // Brand / Jewel Accents
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFB300FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color neonYellow = Color(0xFFFFD600);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonRed = Color(0xFFFF1744);

  // Economy
  static const Color goldCoin = Color(0xFFFFC107);
  static const Color gemCyan = Color(0xFF00E5FF);

  // UI States
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFF9100);
  static const Color danger = Color(0xFFFF1744);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EADC8);
  static const Color textMuted = Color(0xFF5A6680);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireStreakGradient = LinearGradient(
    colors: [Color(0xFFFF3D00), Color(0xFFFF9100)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x28FFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
