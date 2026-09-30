import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders premium jewel-like blocks with:
/// - Gradient fill + 3D bevel
/// - Inner gem shine spot
/// - Pulsing glow for highlighted/clearing cells
/// - Optimized: avoids unnecessary shader creation for ghost blocks
abstract final class BlockPainter {
  // Cached paints for performance (reused across calls)
  static final Paint _shadowPaint = Paint();
  static final Paint _fillPaint = Paint();
  static final Paint _bevelPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _shinePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _ghostPaint = Paint()..style = PaintingStyle.fill;

  static void drawBlock(
    Canvas canvas,
    Rect rect, {
    required Color baseColor,
    String? shapeMark,
    bool isGhost = false,
    bool isInvalid = false,
    bool isClearing = false,
    double clearProgress = 0.0,
  }) {
    if (rect.width <= 0 || rect.height <= 0) return;

    double scale = 1.0;
    double opacity = 1.0;

    if (isGhost) {
      // Ghost blocks: fast fill only, no gradients
      opacity = isInvalid ? 0.30 : 0.55;
      _drawGhostBlock(canvas, rect, baseColor, opacity, isInvalid);
      return;
    } else if (isClearing) {
      scale = (1.0 - (clearProgress * 0.75)).clamp(0.0, 1.2);
      opacity = (1.0 - clearProgress).clamp(0.0, 1.0);
    }

    if (scale <= 0 || opacity <= 0) return;

    final center = rect.center;
    final w = rect.width * scale;
    final h = rect.height * scale;
    final currentRect = Rect.fromCenter(center: center, width: w, height: h);
    final inset = currentRect.width * 0.06;
    final innerRect = currentRect.deflate(inset);
    final radius = Radius.circular(currentRect.width * 0.22);
    final rrect = RRect.fromRectAndRadius(innerRect, radius);

    // Color derivation
    Color displayColor = baseColor;
    if (isClearing && clearProgress < 0.25) {
      displayColor = Color.lerp(baseColor, Colors.white, 0.85)!;
    }

    final alphaScale = (255 * opacity).toInt();
    final hsl = HSLColor.fromColor(displayColor);

    // ── Drop shadow ──────────────────────────────────────
    _shadowPaint
      ..color = displayColor.withAlpha((60 * opacity).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), _shadowPaint);

    // ── Main gradient fill ────────────────────────────────
    final lightColor = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0))
        .toColor()
        .withAlpha(alphaScale);
    final midColor = displayColor.withAlpha(alphaScale);
    final darkColor = hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .toColor()
        .withAlpha(alphaScale);

    _fillPaint.shader = LinearGradient(
      colors: [lightColor, midColor, darkColor],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(innerRect);
    canvas.drawRRect(rrect, _fillPaint);

    // ── 3D Bevel highlight ────────────────────────────────
    final bevelAlpha = (110 * opacity).toInt();
    _bevelPaint
      ..color = Colors.white.withAlpha(bevelAlpha)
      ..strokeWidth = math.max(0.8, currentRect.width * 0.045);
    final innerBevelRect = innerRect.deflate(currentRect.width * 0.11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerBevelRect, Radius.circular(currentRect.width * 0.14)),
      _bevelPaint,
    );

    // ── Gem shine spot (top-left bright highlight) ────────
    if (opacity > 0.5 && currentRect.width > 8) {
      final shineRect = Rect.fromLTWH(
        innerRect.left + currentRect.width * 0.12,
        innerRect.top + currentRect.height * 0.10,
        currentRect.width * 0.28,
        currentRect.height * 0.22,
      );
      _shinePaint.shader = RadialGradient(
        colors: [
          Colors.white.withAlpha((200 * opacity).toInt()),
          Colors.white.withAlpha(0),
        ],
      ).createShader(shineRect);
      canvas.drawOval(shineRect, _shinePaint);
    }

    // ── Outer glow for highlighted/clearing cells ─────────
    if (isClearing && clearProgress < 0.5) {
      final glowOpacity = (1.0 - clearProgress * 2).clamp(0.0, 1.0);
      _glowPaint
        ..color = displayColor.withAlpha((180 * glowOpacity).toInt())
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(rrect, _glowPaint);
      _glowPaint.maskFilter = null;
    }

    // ── Colorblind shape mark ─────────────────────────────
    if (shapeMark != null && shapeMark.isNotEmpty) {
      _drawShapeMark(
        canvas,
        currentRect.center,
        currentRect.width * 0.27,
        shapeMark,
        opacity,
      );
    }
  }

  static void _drawGhostBlock(
    Canvas canvas,
    Rect rect,
    Color color,
    double opacity,
    bool isInvalid,
  ) {
    final innerRect = rect.deflate(rect.width * 0.06);
    final rrect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(rect.width * 0.22),
    );

    final displayColor = isInvalid ? const Color(0xFFFF1744) : color;

    // Simple flat fill for ghost — no shader
    _ghostPaint.color = displayColor.withAlpha((255 * opacity).toInt());
    canvas.drawRRect(rrect, _ghostPaint);

    // Border outline
    final borderPaint = Paint()
      ..color = displayColor.withAlpha((200 * opacity).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  static void _drawShapeMark(
    Canvas canvas,
    Offset center,
    double radius,
    String mark,
    double opacity,
  ) {
    final markPaint = Paint()
      ..color = Colors.white.withAlpha((160 * opacity).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.22)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (mark) {
      case 'circle':
        canvas.drawCircle(center, radius * 0.65, markPaint);
        break;

      case 'diamond':
        final path = Path()
          ..moveTo(center.dx, center.dy - radius * 0.8)
          ..lineTo(center.dx + radius * 0.8, center.dy)
          ..lineTo(center.dx, center.dy + radius * 0.8)
          ..lineTo(center.dx - radius * 0.8, center.dy)
          ..close();
        canvas.drawPath(path, markPaint);
        break;

      case 'triangle':
        final path = Path()
          ..moveTo(center.dx, center.dy - radius * 0.8)
          ..lineTo(center.dx + radius * 0.8, center.dy + radius * 0.7)
          ..lineTo(center.dx - radius * 0.8, center.dy + radius * 0.7)
          ..close();
        canvas.drawPath(path, markPaint);
        break;

      case 'square':
        final sqRect = Rect.fromCenter(
          center: center,
          width: radius * 1.3,
          height: radius * 1.3,
        );
        canvas.drawRect(sqRect, markPaint);
        break;

      case 'cross':
        final d = radius * 0.7;
        canvas.drawLine(
          Offset(center.dx - d, center.dy),
          Offset(center.dx + d, center.dy),
          markPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - d),
          Offset(center.dx, center.dy + d),
          markPaint,
        );
        break;

      case 'star':
      case 'hex':
      default:
        final d = radius * 0.6;
        canvas.drawLine(
          Offset(center.dx - d, center.dy - d),
          Offset(center.dx + d, center.dy + d),
          markPaint,
        );
        canvas.drawLine(
          Offset(center.dx - d, center.dy + d),
          Offset(center.dx + d, center.dy - d),
          markPaint,
        );
        break;
    }
  }
}
