import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';
import 'dart:math' as math;

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Reports: Command Center',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.shieldCheck, color: AppTheme.accentCoral, size: 12),
              ],
            ),
            Row(
              children: [
                Text(
                  'Overview of student readiness & engagement',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.upload, size: 12, color: theme.colorScheme.onSurface),
                const SizedBox(width: 6),
                Text('Export', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdownFilter('CSE A • 2024 Batch', theme),
                  const SizedBox(width: 12),
                  _buildDropdownFilter('12 May – 18 May, 2024', theme, icon: LucideIcons.calendar),
                  const SizedBox(width: 12),
                  _buildDropdownFilter('Compared to: 5 – 11 May', theme, isSubdued: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildOverallReadinessChart(theme)),
                const SizedBox(width: 16),
                Expanded(child: _buildReadinessTrendChart(theme)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Engagement Overview
            Row(
              children: [
                Text(
                  'Engagement Overview',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.info, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Avg. Streak', '7.6', 'days', 1.2, true, LucideIcons.flame, const Color(0xFFFF7043), theme),
                _buildStatCard('Active This Week', '243', '', 18, true, LucideIcons.calendar, const Color(0xFFFF7043), theme),
                _buildStatCard('Problems Solved', '1,842', '', 231, true, LucideIcons.code, const Color(0xFFFF7043), theme),
                _buildStatCard('Assessments Taken', '392', '', 46, true, LucideIcons.target, const Color(0xFFFF7043), theme),
              ],
            ),
            const SizedBox(height: 32),
            
            // Needs Attention
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Needs Attention (45)',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                Text('View All', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Students who may need help or are falling behind.',
              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            
            // List
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildNeedsAttentionItem(
                    name: 'Rohan Mehta',
                    details: 'CSE A • Roll No. 23',
                    issueTitle: 'Low Assessment Score',
                    issueDesc: 'Scored below 50% in 2 assessments this week.',
                    iconWidget: const RivePlaceholder(width: 48, height: 48, label: 'Board', icon: LucideIcons.clipboardList),
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  
                  // Highlighted "Message Sent" state
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      _buildNeedsAttentionItem(
                        name: 'Ananya Singh',
                        details: 'CSE A • Roll No. 47',
                        issueTitle: 'Inactive',
                        issueDesc: 'No activity in the last 5 days.',
                        iconWidget: const SizedBox(width: 48, height: 48), // Spacer
                        theme: theme,
                      ),
                      // Overlay Action
                      Positioned(
                        right: 0, top: 0, bottom: 0,
                        child: Container(
                          width: 120,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentCoral,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.mail, color: Colors.white, size: 16),
                              ),
                              const SizedBox(height: 4),
                              Text('Message Sent!', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  _buildDivider(theme),
                  _buildNeedsAttentionItem(
                    name: 'Karthik R.',
                    details: 'CSE A • Roll No. 31',
                    issueTitle: 'Low Problem Solved',
                    issueDesc: 'Solved fewer than 5 problems this week.',
                    iconWidget: const RivePlaceholder(width: 48, height: 48, label: 'Code', icon: LucideIcons.laptop),
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildNeedsAttentionItem(
                    name: 'Meera Patel',
                    details: 'CSE A • Roll No. 58',
                    issueTitle: 'Missed Goal',
                    issueDesc: 'Did not meet the weekly learning goal.',
                    iconWidget: const RivePlaceholder(width: 48, height: 48, label: 'Target', icon: LucideIcons.target),
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildNeedsAttentionItem(
                    name: 'Siddharth J.',
                    details: 'CSE A • Roll No. 12',
                    issueTitle: 'Low Streak',
                    issueDesc: 'Streak dropped below 3 days.',
                    iconWidget: const RivePlaceholder(width: 48, height: 48, label: 'Flame', icon: LucideIcons.flame),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Bottom Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.megaphone, color: AppTheme.accentCoral, size: 16),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Early nudges lead to better outcomes.', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text('Reach out and help students get back on track.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48), // Padding for potential bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, ThemeData theme, {IconData? icon, bool isSubdued = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSubdued ? Colors.transparent : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSubdued ? Colors.transparent : theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSubdued ? FontWeight.normal : FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: isSubdued ? 0.6 : 1.0),
            ),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOverallReadinessChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Overall Readiness', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 4),
              Icon(LucideIcons.info, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _ReadinessDonutPainter(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('62%', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text('Ready', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow('Ready', '62%', '(186)', const Color(0xFF81C784), theme),
                    const SizedBox(height: 12),
                    _buildLegendRow('On Track', '23%', '(69)', const Color(0xFFFFB74D), theme),
                    const SizedBox(height: 12),
                    _buildLegendRow('Needs Attention', '15%', '(45)', const Color(0xFFFF7043), theme),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowUp, size: 10, color: Colors.green),
                const SizedBox(width: 2),
                Text('6%', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                Text(' vs last week', style: GoogleFonts.inter(fontSize: 8, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String pct, String count, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(pct, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            Text(count, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
          ],
        ),
      ],
    );
  }

  Widget _buildReadinessTrendChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Readiness Trend', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.info, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text('Weekly', style: GoogleFonts.inter(fontSize: 8, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronDown, size: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart Area
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _ReadinessBarChartPainter(theme),
                ),
                // Labels overlay
                Positioned(bottom: 0, left: 30, right: 0, child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Apr 21-27', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    Text('Apr 28-4', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    Text('May 5-11', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    Text('May 12-18', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, double diff, bool isUp, IconData icon, Color iconColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 10, color: isUp ? Colors.green : Colors.red),
              const SizedBox(width: 2),
              Text(
                '${diff.toString().replaceAll('.0', '')} vs last week',
                style: GoogleFonts.inter(fontSize: 8, color: isUp ? Colors.green : Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.1));
  }

  Widget _buildNeedsAttentionItem({
    required String name,
    required String details,
    required String issueTitle,
    required String issueDesc,
    required Widget iconWidget,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(LucideIcons.user, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(details, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issueTitle, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                const SizedBox(height: 2),
                Text(
                  issueDesc,
                  style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          iconWidget,
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _ReadinessDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Hardcoded percentages from the design: Green 62%, Orange 23%, Red 15%
    // Draw Green (Ready)
    paint.color = const Color(0xFF81C784);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.60, false, paint);
    
    // Draw Orange (On Track)
    paint.color = const Color(0xFFFFB74D);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.62, 2 * math.pi * 0.20, false, paint);
    
    // Draw Red (Needs Attention)
    paint.color = const Color(0xFFFF7043);
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.85, 2 * math.pi * 0.12, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReadinessBarChartPainter extends CustomPainter {
  final ThemeData theme;
  _ReadinessBarChartPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Draw horizontal grid lines and labels
    final labels = ['100%', '75%', '50%', '25%', '0%'];
    final yStep = (size.height - 20) / 4;
    
    for (int i = 0; i < 5; i++) {
      final y = i * yStep;
      canvas.drawLine(Offset(30, y), Offset(size.width, y), linePaint);
      
      textPainter.text = TextSpan(
        text: labels[i],
        style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));
    }
    
    // Draw Bars (Heights are visual estimates from the design: 48%, 53%, 56%, 62%)
    final barData = [0.48, 0.53, 0.56, 0.62];
    final barWidth = 16.0;
    final startX = 50.0;
    final spacing = (size.width - startX - barWidth) / 3;
    final bottomY = size.height - 20;
    
    for (int i = 0; i < 4; i++) {
      final x = startX + i * spacing;
      final barHeight = barData[i] * (size.height - 20); // Relative to grid
      final y = bottomY - barHeight;
      
      paint.color = i == 3 ? const Color(0xFFFF7043) : const Color(0xFFFF7043).withValues(alpha: 0.3);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth/2, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint);
      
      // Value label on top
      textPainter.text = TextSpan(
        text: '${(barData[i] * 100).toInt()}%',
        style: GoogleFonts.inter(fontSize: 8, fontWeight: i == 3 ? FontWeight.bold : FontWeight.normal, color: i == 3 ? theme.colorScheme.onSurface : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width/2, y - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
