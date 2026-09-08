import 'package:flutter/material.dart';
import '../../core/theme/app_dimens.dart';

/// The single empty/offline/no-data state for the whole app — merges what
/// used to be three near-identical widgets (this one, the unused
/// `PremiumEmptyState`, and the unused `OfflineErrorView`) into one, keeping
/// the nicer scale+fade entrance the other two had. For a retry action, pass
/// `onRetry` (renders a filled "Retry" button) instead of building one by
/// hand via `action`.
class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool animated;

  const EmptyState({
    super.key,
    required this.title,
    required this.icon,
    this.message,
    this.action,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAction = action ??
        (onRetry != null
            ? FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryLabel),
              )
            : null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: animated ? AppDurations.medium : Duration.zero,
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: animated ? value : 1.0,
            child: Opacity(opacity: (animated ? value : 1.0).clamp(0.0, 1.0), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (resolvedAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                resolvedAction,
              ]
            ],
          ),
        ),
      ),
    );
  }
}
