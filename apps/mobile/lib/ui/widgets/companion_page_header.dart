import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'notification_bell_icon.dart';

class CompanionPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final bool showNotifications;
  final List<Widget> actions;

  const CompanionPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.showNotifications = true,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentCoral,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                  color: const Color(0xFF17132D),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.35,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty || showNotifications) const SizedBox(width: 12),
        ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: action,
            )),
        if (showNotifications) const NotificationBellIcon(),
      ],
    );
  }
}
