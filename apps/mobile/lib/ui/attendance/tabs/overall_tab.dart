import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/rive_placeholder.dart';
import 'dart:math' as math;

class OverallTab extends StatelessWidget {
  const OverallTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Row
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildDropdownFilter('Batch: 2024 CS', null, theme),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildDropdownFilter('01 Apr 2025 - 22 Apr 2025', LucideIcons.calendar, theme),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Students', '82', 'Total', LucideIcons.users, theme, isIcon: true),
                _buildGaugeStatColumn('Avg. Attendance', 0.76, '76%', theme),
                _buildStatColumn('Sessions Held', '24', 'Total', LucideIcons.copy, theme, isIcon: true),
                _buildStatColumn('Avg. Readiness', '62', 'Readiness Score', LucideIcons.activity, theme, isIcon: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Problem Areas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAbsentCard(theme, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildAbsentCard(theme, false)),
            ],
          ),
          const SizedBox(height: 24),

          // Table Filters
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search student',
                    hintStyle: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    prefixIcon: Icon(LucideIcons.search, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildDropdownFilter('All Status', null, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildDropdownFilter('All Attendance', null, theme),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.arrowUpDown, size: 12),
                    const SizedBox(width: 4),
                    Text('Sort', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.filter, size: 12, color: AppTheme.accentCoral),
                    const SizedBox(width: 4),
                    Text('Filters (0)', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Student', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                      Expanded(flex: 2, child: _buildTableHeader('Attendance', theme)),
                      Expanded(flex: 2, child: _buildTableHeader('Sessions', theme)),
                      Expanded(flex: 2, child: _buildTableHeader('Readiness', theme)),
                      Expanded(flex: 2, child: _buildTableHeader('Trend', theme)),
                      Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                
                // Rows
                _buildTableRow(theme, 'Arjun D.', '43CS001', 0.92, '22 / 24', 78, 'Excellent'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Meera R.', '43CS012', 0.84, '20 / 24', 71, 'Good'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Karthik S.', '43CS032', 0.52, '12 / 24', 54, 'Average'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Rohit T.', '43CS023', 0.48, '11 / 24', 47, 'At Risk'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Rohan P.', '43CS047', 0.28, '7 / 24', 31, 'Critical'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Sneha M.', '43CS061', 0.32, '8 / 24', 36, 'Critical'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Vikram N.', '43CS058', 0.34, '8 / 24', 38, 'Critical'),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                _buildTableRow(theme, 'Pooja K.', '43CS072', 0.76, '18 / 24', 63, 'Good'),
                
                // Pagination
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(LucideIcons.arrowLeft, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(width: 16),
                      Text('1 of 9', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(LucideIcons.arrowRight, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                      ),
                      const Spacer(),
                      Text('Show', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Text('10', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Bottom Tip Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.info, color: AppTheme.accentCoral, size: 12),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistency drives outcomes.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Students with 75%+ attendance improve 20% more in readiness.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const RivePlaceholder(width: 60, height: 60, label: 'Chart Mascot', icon: LucideIcons.barChart),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String value, IconData? icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
              ],
              Text(value, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
            ],
          ),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, String subtitle, IconData icon, ThemeData theme, {bool isIcon = false}) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        if (isIcon)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.illusSage.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.illusSage, size: 16),
          )
        else
          SizedBox(height: 44, width: 44), // Placeholder for gauge
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildGaugeStatColumn(String title, double progress, String value, ThemeData theme) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _GaugePainter(
                  progress: progress,
                  color: AppTheme.accentCoral,
                  trackColor: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // Adjusted to match the others visually
        Text('', style: GoogleFonts.inter(fontSize: 9)), // Empty subtitle to align
      ],
    );
  }

  Widget _buildAbsentCard(ThemeData theme, bool isMostAbsent) {
    final List<Map<String, String>> users = isMostAbsent
        ? [
            {'name': 'Rohan P.', 'id': '43CS047', 'value': '28%'},
            {'name': 'Sneha M.', 'id': '43CS061', 'value': '32%'},
            {'name': 'Vikram N.', 'id': '43CS058', 'value': '34%'},
          ]
        : [
            {'name': 'Karthik S.', 'id': '43CS032', 'value': '5\nsessions'},
            {'name': 'Meera R.', 'id': '43CS019', 'value': '4\nsessions'},
            {'name': 'Pooja K.', 'id': '43CS072', 'value': '4\nsessions'},
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isMostAbsent ? LucideIcons.alertTriangle : LucideIcons.calendarX, color: AppTheme.accentCoral, size: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMostAbsent ? 'Most Absent' : 'Continuous Absentees',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      isMostAbsent ? '% attendance (lowest)' : '3+ consecutive sessions missed',
                      style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              Text('View all', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.illusSage)),
            ],
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < users.length; i++) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(LucideIcons.user, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(users[i]['name']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      Text(users[i]['id']!, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Text(
                  users[i]['value']!,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.sora(
                    fontSize: isMostAbsent ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCoral,
                  ),
                ),
              ],
            ),
            if (i < users.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, ThemeData theme) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(width: 4),
        Icon(LucideIcons.arrowUpDown, size: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _buildTableRow(ThemeData theme, String name, String regNo, double attendance, String sessions, int readiness, String status) {
    Color getStatusColor() {
      switch (status) {
        case 'Excellent':
        case 'Good':
          return const Color(0xFF4CAF50); // Green
        case 'Average':
        case 'At Risk':
          return const Color(0xFFFF9800); // Orange
        case 'Critical':
          return AppTheme.accentCoral; // Red
        default:
          return Colors.grey;
      }
    }

    final color = getStatusColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Student Column
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(LucideIcons.user, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      Text(regNo, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Attendance Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(attendance * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: attendance,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                    color: color,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          
          // Sessions Column
          Expanded(
            flex: 2,
            child: Text(sessions, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
          ),
          
          // Readiness Column
          Expanded(
            flex: 2,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  readiness.toString(),
                  style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
          ),
          
          // Trend Column
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 50,
              height: 20,
              child: CustomPaint(
                painter: _SparklinePainter(
                  color: color,
                  isPositive: readiness > 50,
                ),
              ),
            ),
          ),
          
          // Status Column
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _GaugePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * -0.5,
      math.pi * 2,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * -0.5,
      (math.pi * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final bool isPositive;

  _SparklinePainter({required this.color, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Generate a random-looking sparkline based on positive/negative trend
    final w = size.width;
    final h = size.height;
    
    if (isPositive) {
      path.moveTo(0, h * 0.8);
      path.lineTo(w * 0.2, h * 0.6);
      path.lineTo(w * 0.4, h * 0.7);
      path.lineTo(w * 0.6, h * 0.3);
      path.lineTo(w * 0.8, h * 0.4);
      path.lineTo(w, h * 0.1);
    } else {
      path.moveTo(0, h * 0.2);
      path.lineTo(w * 0.2, h * 0.4);
      path.lineTo(w * 0.4, h * 0.3);
      path.lineTo(w * 0.6, h * 0.6);
      path.lineTo(w * 0.8, h * 0.5);
      path.lineTo(w, h * 0.9);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
