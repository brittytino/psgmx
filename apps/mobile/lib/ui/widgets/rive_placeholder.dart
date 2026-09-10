import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

/// Legacy-named AI mascot surface. It now uses a bundled image and a small
/// Flutter-native motion effect, avoiding missing Rive files and runtime asset
/// errors while keeping the existing call sites stable.
class RivePlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final IconData icon;

  const RivePlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.label = 'Animation',
    this.icon = LucideIcons.image,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: RepaintBoundary(
        child: _GentleMotion(
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              'assets/images/home/sparkAI.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppTheme.accentCoral,
                    size: width < height ? width * 0.5 : height * 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SparkPlaceholder extends StatelessWidget {
  final double size;

  const SparkPlaceholder({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _GentleMotion(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A65), AppTheme.accentCoral],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCoral.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.sparkles,
            color: Colors.white,
            size: size * 0.48,
          ),
        ),
      ),
    );
  }
}

class _GentleMotion extends StatefulWidget {
  final Widget child;

  const _GentleMotion({required this.child});

  @override
  State<_GentleMotion> createState() => _GentleMotionState();
}

class _GentleMotionState extends State<_GentleMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      value: 0.5,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final eased = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -1.5 * eased),
          child: Transform.scale(
            scale: 0.985 + (0.015 * eased),
            child: child,
          ),
        );
      },
    );
  }
}
