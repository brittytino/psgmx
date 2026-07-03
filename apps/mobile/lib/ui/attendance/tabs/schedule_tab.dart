import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/rive_placeholder.dart';

class ScheduleTab extends StatefulWidget {
  final VoidCallback onNewSessionTap;

  const ScheduleTab({super.key, required this.onNewSessionTap});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Segment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: AppTheme.accentCoral),
                  const SizedBox(width: 8),
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
                  _buildHeaderSegment('Week', true),
                  const SizedBox(width: 16),
                  _buildHeaderSegment('Month', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Date Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.chevronLeft, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              _buildDateItem('Mon', '19', false),
              _buildDateItem('Tue', '20', false),
              _buildDateItem('Wed', '21', false),
              _buildDateItem('Thu', '22', true, isToday: true),
              _buildDateItem('Fri', '23', false),
              _buildDateItem('Sat', '24', false),
              _buildDateItem('Sun', '25', false),
              Icon(LucideIcons.chevronRight, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const RivePlaceholder(width: 48, height: 48, label: 'Cal', icon: LucideIcons.calendarClock),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Manage and schedule placement sessions for your students.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.onNewSessionTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentCoral,
                    side: const BorderSide(color: AppTheme.accentCoral),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(LucideIcons.plusCircle, size: 12),
                  label: const Text('New Session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Search & Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search sessions',
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
                flex: 1,
                child: _buildDropdownFilter('All Types', theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildDropdownFilter('All Trainers', theme),
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
                    const Icon(LucideIcons.filter, size: 12),
                    const SizedBox(width: 4),
                    Text('Filter', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Day Header
          Text(
            'Thursday, 22 April 2025',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sessions List
          _buildSessionCard(
            context,
            color: AppTheme.accentCoral,
            timeStart: '10:00 AM',
            timeEnd: '11:30 AM',
            status: 'Upcoming',
            icon: LucideIcons.code2,
            tag: 'Aptitude',
            title: 'Quantitative Aptitude',
            subtitle: 'Number System & Simplification',
            trainer: 'Rishabh T.',
            target: '3rd Year',
            location: 'Room 201',
          ),
          const SizedBox(height: 16),
          _buildSessionCard(
            context,
            color: const Color(0xFF4CAF50),
            timeStart: '12:00 PM',
            timeEnd: '1:30 PM',
            status: 'Live',
            icon: LucideIcons.bookOpen,
            tag: 'Technical',
            title: 'Data Structures (Arrays)',
            subtitle: 'Arrays, Prefix Sums & Two Pointers',
            trainer: 'Neha S.',
            target: '3rd Year',
            location: 'Lab 3',
          ),
          const SizedBox(height: 16),
          _buildSessionCard(
            context,
            color: const Color(0xFF2196F3),
            timeStart: '2:00 PM',
            timeEnd: '3:30 PM',
            status: 'Scheduled',
            icon: LucideIcons.messageCircle,
            tag: 'Soft Skills',
            title: 'Group Discussion',
            subtitle: 'Communication & Leadership',
            trainer: 'Amit K.',
            target: '2nd & 3rd Year',
            location: 'Seminar Hall',
          ),
          const SizedBox(height: 16),
          _buildSessionCard(
            context,
            color: const Color(0xFF4CAF50),
            timeStart: '4:00 PM',
            timeEnd: '5:00 PM',
            status: 'Scheduled',
            icon: LucideIcons.target,
            tag: 'Aptitude',
            title: 'Daily Practice Session',
            subtitle: 'Mixed Aptitude & Reasoning Problems',
            trainer: 'Rishabh T.',
            target: '3rd Year',
            location: 'Online',
            isOnline: true,
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
                const RivePlaceholder(width: 40, height: 40, label: 'List', icon: LucideIcons.clipboardList),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip: Consistency in scheduling = Better attendance.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Plan ahead and help your students stay on track.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const RivePlaceholder(width: 40, height: 40, label: 'Mascot', icon: LucideIcons.smile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSegment(String title, bool isSelected) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        if (isSelected)
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.accentCoral,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildDateItem(String day, String date, bool isSelected, {bool isToday = false}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCoral : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              date,
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (isToday) ...[
          const SizedBox(height: 4),
          Text(
            'Today',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentCoral,
            ),
          ),
        ] else if (!isSelected) ...[
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.accentCoral,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownFilter(String hint, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface)),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.colorScheme.onSurface),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context, {
    required Color color,
    required String timeStart,
    required String timeEnd,
    required String status,
    required IconData icon,
    required String tag,
    required String title,
    required String subtitle,
    required String trainer,
    required String target,
    required String location,
    bool isOnline = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Block
                    SizedBox(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(timeStart, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text('-', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                          const SizedBox(height: 2),
                          Text(timeEnd, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Live' ? const Color(0xFFE8F5E9) : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: status == 'Live' ? const Color(0xFF2E7D32) : color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Middle Block
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tag,
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(LucideIcons.user, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text('Trainer: $trainer', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.users, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text('Target: $target', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Right Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(isOnline ? LucideIcons.globe : LucideIcons.mapPin, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(location, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface)),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.moreVertical, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentCoral,
                            side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(LucideIcons.pencil, size: 12),
                          label: Text('Edit', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
