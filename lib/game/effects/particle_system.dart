import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Performance-optimized particle system with varied shapes.
/// Particle cap prevents runaway memory on heavy combos.
class BlockParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  final Color color;
  final double lifeTime;
  final int shape; // 0=circle, 1=square, 2=diamond, 3=star
  double elapsed = 0.0;
  double rotation = 0.0;
  double rotSpeed = 0.0;

  BlockParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.shape,
    this.lifeTime = 0.6,
    this.opacity = 1.0,
    this.rotSpeed = 0.0,
  });

  bool update(double dt) {
    elapsed += dt;
    if (elapsed >= lifeTime) return false;

    x += vx * dt;
    y += vy * dt;
    vy += 900 * dt; // Gravity
    vx *= math.pow(0.90, dt * 60);
    rotation += rotSpeed * dt;

    final progress = elapsed / lifeTime;
    opacity = (1.0 - (progress * progress)).clamp(0.0, 1.0);
    return true;
  }

  static final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  static final Path _particlePath = Path();

  void render(Canvas canvas) {
    if (opacity <= 0.01) return;

    _particlePaint.color = color.withAlpha((255 * opacity).toInt());

    final currentSize = size * (0.6 + opacity * 0.4);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    switch (shape) {
      case 0: // circle
        canvas.drawCircle(Offset.zero, currentSize, _particlePaint);
        break;
      case 1: // square
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: currentSize * 1.6,
            height: currentSize * 1.6,
          ),
          _particlePaint,
        );
        break;
      case 2: // diamond
        _particlePath.reset();
        _particlePath.moveTo(0, -currentSize * 1.4);
        _particlePath.lineTo(currentSize, 0);
        _particlePath.lineTo(0, currentSize * 1.4);
        _particlePath.lineTo(-currentSize, 0);
        _particlePath.close();
        canvas.drawPath(_particlePath, _particlePaint);
        break;
      case 3: // sparkle / star
        _drawSparkle(canvas, _particlePaint, currentSize);
        break;
    }

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Paint paint, double r) {
    _particlePath.reset();
    for (int i = 0; i < 4; i++) {
      final outerAngle = i * math.pi / 2;
      final innerAngle = outerAngle + math.pi / 4;
      if (i == 0) {
        _particlePath.moveTo(math.cos(outerAngle) * r * 1.5, math.sin(outerAngle) * r * 1.5);
      } else {
        _particlePath.lineTo(math.cos(outerAngle) * r * 1.5, math.sin(outerAngle) * r * 1.5);
      }
      _particlePath.lineTo(math.cos(innerAngle) * r * 0.5, math.sin(innerAngle) * r * 0.5);
    }
    _particlePath.close();
    canvas.drawPath(_particlePath, paint);
  }
}

class ParticleManager {
  final List<BlockParticle> _particles = [];
  final math.Random _rng = math.Random();

  // Hard cap to prevent lag on heavy combos
  static const int _maxParticles = 180;

  void spawnBurst({
    required Offset origin,
    required Color color,
    int count = 7,
    double spread = 30.0,
  }) {
    // If near cap, don't add more
    if (_particles.length >= _maxParticles) return;

    // Clamp count to not exceed cap
    final toAdd = math.min(count, _maxParticles - _particles.length);

    for (int i = 0; i < toAdd; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 100 + _rng.nextDouble() * 220;
      final vx = math.cos(angle) * speed;
      final vy = (math.sin(angle) * speed) - 80; // upward bias

      // Vary color slightly for sparkle feel
      final hsl = HSLColor.fromColor(color);
      final variedColor = hsl
          .withSaturation((hsl.saturation + (_rng.nextDouble() - 0.5) * 0.3).clamp(0.0, 1.0))
          .withLightness((hsl.lightness + (_rng.nextDouble() - 0.3) * 0.25).clamp(0.2, 0.9))
          .toColor();

      _particles.add(
        BlockParticle(
          x: origin.dx + (_rng.nextDouble() - 0.5) * spread,
          y: origin.dy + (_rng.nextDouble() - 0.5) * spread,
          vx: vx,
          vy: vy,
          size: 2.5 + _rng.nextDouble() * 4.0,
          color: variedColor,
          shape: _rng.nextInt(4),
          lifeTime: 0.40 + _rng.nextDouble() * 0.30,
          rotSpeed: (_rng.nextDouble() - 0.5) * 12.0,
        ),
      );
    }
  }

  void spawnLineClear({
    required List<Offset> cellCenters,
    required Color color,
  }) {
    // For line clears, spawn fewer per cell but with dramatic colors
    for (final center in cellCenters) {
      spawnBurst(
        origin: center,
        color: color,
        count: 4, // fewer per cell = still 32 for full row, manageable
        spread: 20.0,
      );
    }
  }

  void update(double dt) {
    _particles.removeWhere((p) => !p.update(dt));
  }

  void render(Canvas canvas) {
    for (final p in _particles) {
      p.render(canvas);
    }
  }

  void clear() {
    _particles.clear();
  }

  int get count => _particles.length;
}
