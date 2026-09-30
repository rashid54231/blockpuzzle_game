import 'package:flutter/services.dart';

abstract class HapticsService {
  void setEnabled(bool enabled);
  bool get isEnabled;
  void light();
  void medium();
  void heavy();
  void success();
}

class AppHapticsService implements HapticsService {
  bool _enabled = true;

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  @override
  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  @override
  void success() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }
}
