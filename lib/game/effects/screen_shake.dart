import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScreenShake {
  double _intensity = 0.0;
  double _duration = 0.0;
  double _elapsed = 0.0;
  final math.Random _rng = math.Random();

  Offset get offset {
    if (_elapsed >= _duration || _intensity <= 0) return Offset.zero;
    final decay = 1.0 - (_elapsed / _duration);
    final currentIntensity = _intensity * decay;
    final dx = (_rng.nextDouble() * 2 - 1) * currentIntensity;
    final dy = (_rng.nextDouble() * 2 - 1) * currentIntensity;
    return Offset(dx, dy);
  }

  void trigger({required int linesCleared}) {
    if (linesCleared <= 0) return;
    switch (linesCleared) {
      case 1:
        _intensity = 4.0;
        _duration = 0.20;
        break;
      case 2:
        _intensity = 8.0;
        _duration = 0.30;
        break;
      case 3:
        _intensity = 14.0;
        _duration = 0.40;
        break;
      default:
        _intensity = 20.0;
        _duration = 0.50;
        break;
    }
    _elapsed = 0.0;
  }

  void update(double dt) {
    if (_elapsed < _duration) {
      _elapsed += dt;
    }
  }
}
