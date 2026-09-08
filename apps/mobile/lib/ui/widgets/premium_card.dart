import 'package:flutter/material.dart';
import '../../core/theme/app_dimens.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional header row — title (+ optional subtitle) with a divider before
  /// [child]. Lets call sites that used to reach for the old, unused
  /// `ContentCard` widget just add these params to `PremiumCard` instead.
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.hasBorder = true,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppRadius.md,
    this.title,
    this.subtitle,
    this.trailing,
    this.backgroundColor, // Optional override alias for color
  });

  // ignore: unused_field
  final Color? backgroundColor;

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use backgroundColor if provided, else color, else theme default
    final cardColor = widget.backgroundColor ?? widget.color ?? theme.cardTheme.color;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
        onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
        onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.hasBorder
                  ? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Padding(
                padding: widget.padding,
                child: widget.title == null
                    ? widget.child
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.title!,
                                        style: theme.textTheme.titleLarge),
                                    if (widget.subtitle != null) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(widget.subtitle!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant)),
                                    ],
                                  ],
                                ),
                              ),
                              if (widget.trailing != null) widget.trailing!,
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          widget.child,
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
