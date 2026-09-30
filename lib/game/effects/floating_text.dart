import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Performance-optimized floating text effect.
/// TextPainter is built ONCE on creation and reused — not recreated every frame.
class FloatingTextItem {
  final String text;
  double x;
  double y;
  final Color color;
  final double fontSize;
  final double lifeTime;
  double elapsed = 0.0;
  final bool isCombo;

  // Cached painter — built once, avoids per-frame layout cost
  late final TextPainter _painter;
  bool _painterBuilt = false;

  FloatingTextItem({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    required this.fontSize,
    this.lifeTime = 0.85,
    this.isCombo = false,
  });

  void _ensurePainter() {
    if (_painterBuilt) return;
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          shadows: const [
            Shadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _painterBuilt = true;
  }

  bool update(double dt) {
    elapsed += dt;
    if (elapsed >= lifeTime) return false;
    // Eased upward float
    y -= (55 + (elapsed / lifeTime) * 20) * dt;
    return true;
  }

  void render(Canvas canvas) {
    _ensurePainter();

    final progress = (elapsed / lifeTime).clamp(0.0, 1.0);

    // Opacity: fade in fast, hold, fade out
    double opacity;
    if (progress < 0.12) {
      opacity = progress / 0.12; // quick fade-in
    } else {
      opacity = (1.0 - progress).clamp(0.0, 1.0);
    }
    if (opacity <= 0) return;

    // Scale: pop in, then settle
    double scale;
    if (isCombo) {
      scale = progress < 0.15
          ? (progress / 0.15) * 1.25
          : 1.0 + math.sin(progress * math.pi) * 0.28;
    } else {
      scale = progress < 0.12 ? (progress / 0.12) * 1.1 : 1.0;
    }

    final w = _painter.width * scale;
    final h = _painter.height * scale;

    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    // Draw glow behind text
    if (opacity > 0.3) {
      final glowPaint = Paint()
        ..color = color.withAlpha((80 * opacity).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 1.2,
          height: h * 1.2,
        ),
        glowPaint,
      );
    }

    // Paint text with current opacity using saveLayer
    canvas.saveLayer(
      Rect.fromCenter(center: Offset.zero, width: w + 20, height: h + 20),
      Paint()..color = Colors.white.withAlpha((255 * opacity).toInt()),
    );
    _painter.paint(
      canvas,
      Offset(-_painter.width / 2, -_painter.height / 2),
    );
    canvas.restore(); // layer
    canvas.restore(); // transform
  }
}

class FloatingTextManager {
  final List<FloatingTextItem> _items = [];

  void addScoreText(Offset position, int score) {
    _items.add(
      FloatingTextItem(
        text: '+$score',
        x: position.dx + (math.Random().nextDouble() - 0.5) * 40,
        y: position.dy,
        color: const Color(0xFF00E5FF),
        fontSize: 28,
        lifeTime: 0.9,
      ),
    );
  }

  void addComboText(Offset position, int combo) {
    String message;
    Color color;

    if (combo == 2) {
      message = '🔥 DOUBLE!';
      color = const Color(0xFFFFD600);
    } else if (combo == 3) {
      message = '⚡ TRIPLE!';
      color = const Color(0xFFFF6D00);
    } else if (combo == 4) {
      message = '💥 MEGA! 4x';
      color = const Color(0xFFFF007F);
    } else if (combo == 5) {
      message = '🌟 ULTRA! 5x';
      color = const Color(0xFFB300FF);
    } else {
      message = '✨ INSANE! ${combo}x';
      color = const Color(0xFFFFFFFF);
    }

    _items.add(
      FloatingTextItem(
        text: message,
        x: position.dx,
        y: position.dy - 40,
        color: color,
        fontSize: 34,
        isCombo: true,
        lifeTime: 1.2,
      ),
    );
  }

  void addPerfectClearText(Offset position) {
    _items.add(
      FloatingTextItem(
        text: '✨ PERFECT! +300',
        x: position.dx,
        y: position.dy - 20,
        color: const Color(0xFFFFD700),
        fontSize: 36,
        isCombo: true,
        lifeTime: 1.6,
      ),
    );
  }

  void addLineClearText(Offset position, int lines) {
    if (lines < 2) return; // Single line — no text, not worth showing
    final texts = ['', '', 'DOUBLE LINE!', 'TRIPLE LINE!', 'QUAD LINE!'];
    final colors = [
      Colors.white,
      Colors.white,
      const Color(0xFF00E5FF),
      const Color(0xFF00E676),
      const Color(0xFFFFD700),
    ];
    final idx = lines.clamp(0, 4);
    _items.add(
      FloatingTextItem(
        text: texts[idx],
        x: position.dx,
        y: position.dy + 30,
        color: colors[idx],
        fontSize: 22,
        lifeTime: 1.0,
      ),
    );
  }

  void update(double dt) {
    _items.removeWhere((item) => !item.update(dt));
  }

  void render(Canvas canvas) {
    for (final item in _items) {
      item.render(canvas);
    }
  }

  void clear() {
    _items.clear();
  }
}
