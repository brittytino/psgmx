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

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isHovered = false;

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

  void _setPressed(bool pressed) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 0;
      return;
    }
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Use backgroundColor if provided, else color, else theme default
    final cardColor =
        widget.backgroundColor ?? widget.color ?? theme.cardTheme.color;
    final borderRadius = BorderRadius.circular(widget.radius);

    final content = Padding(
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
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
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
    );

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.onTap == null
          ? null
          : (_) => setState(() => _isHovered = true),
      onExit: widget.onTap == null
          ? null
          : (_) => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppDurations.fast,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: widget.hasBorder
                ? Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: _isHovered ? 0.28 : 0.2)
                    : Colors.black.withValues(alpha: _isHovered ? 0.09 : 0.05),
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: cardColor,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: widget.onTap == null ? null : _setPressed,
              borderRadius: borderRadius,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
              hoverColor: theme.colorScheme.primary.withValues(alpha: 0.025),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
