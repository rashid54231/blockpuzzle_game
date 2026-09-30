import 'package:flutter/material.dart';

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final Duration duration;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00E5FF),
    this.maxBlur = 16.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 2.0,
      end: widget.maxBlur,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withAlpha(
                  (120 * (_glowAnimation.value / widget.maxBlur)).toInt(),
                ),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value * 0.25,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
