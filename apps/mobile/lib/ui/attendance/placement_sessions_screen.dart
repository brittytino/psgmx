import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'tabs/my_attendance_tab.dart';
import 'tabs/my_team_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/overall_tab.dart';

class PlacementSessionsScreen extends StatefulWidget {
  const PlacementSessionsScreen({super.key});

  @override
  State<PlacementSessionsScreen> createState() => _PlacementSessionsScreenState();
}

class _PlacementSessionsScreenState extends State<PlacementSessionsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Placement Sessions',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getSubtitle(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.upload, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'Export',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTab(0, 'My attendance', LucideIcons.user)),
                    Expanded(child: _buildTab(1, 'My Team', LucideIcons.users)),
                    Expanded(child: _buildTab(2, 'Schedule', LucideIcons.calendar)),
                    Expanded(child: _buildTab(3, 'Overall', LucideIcons.barChart2)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Consistency today, opportunities tomorrow.';
      case 1:
        return 'Your team, your impact.';
      case 2:
        return 'Plan today, prepare tomorrow.';
      case 3:
      default:
        return 'Tracking progress across the board.';
    }
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCoral : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return const MyAttendanceTab();
      case 1:
        return const MyTeamTab();
      case 2:
        return ScheduleTab(
          onNewSessionTap: () {
            context.push('/admin/new-session');
          },
        );
      case 3:
        return const OverallTab();
      default:
        return Center(
          child: Text(
            'Coming soon',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        );
    }
  }
}
