import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

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
    // Pick a mascot deterministically based on label
    final mascotIndex = (label.hashCode % 3) + 1;
    final mascotAsset = 'assets/images/mascots/mascot$mascotIndex.png';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          mascotAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.illusGold.withValues(alpha: 0.1),
            child: const Center(child: Icon(LucideIcons.image, color: AppTheme.illusGold)),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accentCoral,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCoral.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          LucideIcons.sparkles,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
