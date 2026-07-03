import 'package:flutter/material.dart';
import '../../core/theme/app_dimens.dart';

class PremiumEmptyState extends StatelessWidget {
  final String message;
  final String subMessage;
  final IconData icon;
  final Widget? action;
  final bool isAnimated;

  const PremiumEmptyState({
    super.key,
    required this.message,
    this.subMessage = "",
    required this.icon,
    this.action,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppDurations.medium,
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: isAnimated ? value : 1.0,
              child: Opacity(
                opacity: (isAnimated ? value : 1.0).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
