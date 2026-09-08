import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_five.dart';
import '../../core/theme/app_dimens.dart';

class StreakMilestoneScreen extends StatefulWidget {
  final DailyFiveStreak streak;

  const StreakMilestoneScreen({super.key, required this.streak});

  @override
  State<StreakMilestoneScreen> createState() => _StreakMilestoneScreenState();
}

class _StreakMilestoneScreenState extends State<StreakMilestoneScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800)
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        // LayoutBuilder + a min-height ConstrainedBox lets the content stay
        // vertically centered on a normal portrait screen while still
        // scrolling instead of overflowing (RenderFlex error) on a short
        // viewport — e.g. landscape, which this app does not lock out
        // (see ios/Runner/Info.plist's UISupportedInterfaceOrientations).
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                      ],
                    ),
                    child: Text(
                      '🔥',
                      style: TextStyle(fontSize: 16, shadows: [
                        Shadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 10)
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'MILESTONE REACHED!',
                  style: GoogleFonts.sora(
                    textStyle: theme.textTheme.headlineMedium,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.streak.currentStreak} Days',
                  style: GoogleFonts.sora(
                    textStyle: theme.textTheme.displayLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Incredible consistency! Keep the momentum going.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    textStyle: theme.textTheme.titleMedium,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
