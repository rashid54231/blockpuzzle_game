import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int count;
  final TextStyle style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.count,
    required this.style,
    this.duration = const Duration(milliseconds: 500),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text('$prefix${value.toInt()}$suffix', style: style);
      },
    );
  }
}
