import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  final bool isInteractive;

  const TutorialScreen({super.key, this.isInteractive = true});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Drag & Drop Shapes',
      'desc':
          'Choose from 3 block shapes in your tray. Drag and place them anywhere on the 8x8 grid.',
      'icon': 'pan_tool_alt_rounded',
    },
    {
      'title': 'Clear Lines',
      'desc':
          'Fill an entire row or column to clear it. Clearing multiple lines at once scores massive bonus points!',
      'icon': 'view_week_rounded',
    },
    {
      'title': 'Build Combos',
      'desc':
          'Keep clearing lines on consecutive moves to build your combo multiplier up to 5x!',
      'icon': 'bolt_rounded',
    },
    {
      'title': 'Daily Challenge',
      'desc':
          'Play the exact same seeded puzzle as players worldwide every day, and climb the global leaderboards.',
      'icon': 'emoji_events_rounded',
    },
  ];

  void _finish() {
    final storage = ref.read(storageServiceProvider);
    storage.setBool('has_seen_tutorial', true);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('How to Play', style: AppTextStyles.titleMedium),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(
              'SKIP',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.neonCyan,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderColor: AppColors.neonCyan,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(step['icon']!),
                          size: 56,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step['title']!,
                        style: AppTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step['desc']!,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentStep == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentStep == index
                          ? AppColors.neonCyan
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: isLast ? 'START PLAYING' : 'NEXT',
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    setState(() {
                      _currentStep++;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'pan_tool_alt_rounded':
        return Icons.pan_tool_alt_rounded;
      case 'view_week_rounded':
        return Icons.view_week_rounded;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'emoji_events_rounded':
        return Icons.emoji_events_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
