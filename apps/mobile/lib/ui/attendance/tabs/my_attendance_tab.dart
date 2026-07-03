import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/rive_placeholder.dart';

class MyAttendanceTab extends StatelessWidget {
  const MyAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heatmap Card
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'April 2025',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 16, color: theme.textTheme.bodyMedium?.color),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Less', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        const SizedBox(width: 8),
                        _buildLegendBox(AppTheme.accentCoral.withValues(alpha: 0.1)),
                        const SizedBox(width: 4),
                        _buildLegendBox(AppTheme.accentCoral.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        _buildLegendBox(AppTheme.accentCoral.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        _buildLegendBox(AppTheme.accentCoral.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        _buildLegendBox(AppTheme.accentCoral),
                        const SizedBox(width: 8),
                        Text('More', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Heatmap Mockup
                _buildHeatmapMockup(theme),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.info, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                'Tap a day to view session details',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '86%',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placement Sessions',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attended 43 of 50 sessions',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.arrowUpRight, color: Color(0xFF4CAF50), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Great consistency! Keep it up.',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: const RivePlaceholder(
                  height: 200,
                  width: 200,
                  label: 'Calendar Mascot',
                  icon: LucideIcons.calendarHeart,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.target, color: AppTheme.accentCoral),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistent attendance = More opportunities',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Top performers never miss sessions.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppTheme.accentCoral),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // This Week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                  children: [
                    TextSpan(
                      text: '4 / 7',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                    ),
                    const TextSpan(text: ' attended'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayCircle('Mon', true),
              _buildDayCircle('Tue', true),
              _buildDayCircle('Wed', true),
              _buildDayCircle('Thu', true, isToday: true),
              _buildDayCircle('Fri', false),
              _buildDayCircle('Sat', false),
              _buildDayCircle('Sun', false),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeatmapMockup(ThemeData theme) {
    // Just a visual representation matching s11
    final columns = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final rows = ['Mar 31', 'Apr 7', 'Apr 14', 'Apr 21', 'Apr 28', 'May 5'];
    
    // Intensity matrix matching roughly the design
    final matrix = [
      [0.0, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2], // Mar 31
      [0.2, 0.2, 0.2, 0.2, 0.5, 0.5, 0.5], // Apr 7
      [0.2, 0.4, 0.4, 0.6, 0.8, 0.8, 0.5], // Apr 14
      [0.4, 0.4, 0.6, 0.6, 0.8, 0.8, 0.4], // Apr 21
      [0.2, 0.4, 0.6, 0.6, 0.6, 0.2, 0.1], // Apr 28
      [0.2, 0.4, 0.4, 0.6, 0.6, 0.1, 0.1], // May 5
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 40), // Offset for row headers
            for (var col in columns)
              Expanded(
                child: Center(
                  child: Text(
                    col,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (int r = 0; r < rows.length; r++) ...[
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  rows[r],
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
              for (int c = 0; c < columns.length; c++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: matrix[r][c] == 0.0 
                              ? Colors.white 
                              : AppTheme.accentCoral.withValues(alpha: matrix[r][c]),
                          borderRadius: BorderRadius.circular(6),
                          border: matrix[r][c] == 0.0 && r == 0 && c == 0 
                              ? Border.all(color: AppTheme.accentCoral, width: 2) // Selected cell
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (r < rows.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildDayCircle(String day, bool isAttended, {bool isToday = false}) {
    final color = isAttended ? AppTheme.accentCoral : Colors.grey.shade200;
    
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.black : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isAttended ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isAttended ? color.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: isAttended 
            ? Icon(Icons.check, color: color, size: 16)
            : Icon(Icons.remove, color: Colors.grey.shade400, size: 16),
        ),
      ],
    );
  }
}
