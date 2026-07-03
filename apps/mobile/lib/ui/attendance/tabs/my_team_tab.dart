import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class MyTeamTab extends StatefulWidget {
  const MyTeamTab({super.key});

  @override
  State<MyTeamTab> createState() => _MyTeamTabState();
}

class _MyTeamTabState extends State<MyTeamTab> {
  // Mock data for UI presentation
  final List<Map<String, dynamic>> _students = [
    {'name': 'Arjun D.', 'regNo': '24CS001', 'status': 'PRESENT'},
    {'name': 'Meera R.', 'regNo': '24CS012', 'status': 'PRESENT'},
    {'name': 'Karthik S.', 'regNo': '24CS023', 'status': 'PRESENT'},
    {'name': 'Rohan P.', 'regNo': '24CS031', 'status': 'PRESENT'},
    {'name': 'Sneha M.', 'regNo': '24CS045', 'status': 'ABSENT'},
    {'name': 'Vikram N.', 'regNo': '24CS052', 'status': 'PRESENT'},
    {'name': 'Pooja K.', 'regNo': '24CS061', 'status': 'NOT_MARKED', 'icon': LucideIcons.clock},
    {'name': 'Aditya S.', 'regNo': '24CS067', 'status': 'PRESENT'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Team Stats Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6), // Very light tan
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCoral.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.users, color: AppTheme.accentCoral),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Alpha',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '32 Students',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatColumn('25', 'Present', const Color(0xFF4CAF50)),
                    Container(width: 1, height: 30, color: theme.dividerColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    _buildStatColumn('5', 'Absent', AppTheme.accentCoral),
                    Container(width: 1, height: 30, color: theme.dividerColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    _buildStatColumn('2', 'Not Marked', theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Session Info Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(LucideIcons.calendarCheck, color: AppTheme.accentCoral, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today, 22 Apr 2025',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aptitude Session · 10:00 AM',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          'Marking open',
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
              const SizedBox(height: 24),
              
              // Search and Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search student',
                        hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        prefixIcon: Icon(LucideIcons.search, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.filter, size: 12),
                        const SizedBox(width: 8),
                        Text('Filter', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // List Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Student', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                  Text('Status', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                ],
              ),
              const SizedBox(height: 16),
              
              // Student List
              ...List.generate(_students.length, (index) {
                final student = _students[index];
                return _buildStudentRow(
                  name: student['name'],
                  regNo: student['regNo'],
                  status: student['status'],
                  extraIcon: student['icon'],
                  onChanged: (newStatus) {
                    setState(() {
                      _students[index]['status'] = newStatus;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        
        // Fixed Bottom Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCoral.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(LucideIcons.info, color: AppTheme.accentCoral, size: 12),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mark everyone to complete attendance',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                ),
                                Text(
                                  'All students must be marked to lock today\'s session.',
                                  style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentCoral,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(LucideIcons.lock, size: 12),
                    label: Text('Lock Attendance', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow({
    required String name,
    required String regNo,
    required String status,
    IconData? extraIcon,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(LucideIcons.user),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  regNo,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildSegmentButton(
                label: 'PRESENT',
                isSelected: status == 'PRESENT',
                color: const Color(0xFF4CAF50),
                onTap: () => onChanged('PRESENT'),
                isFirst: true,
              ),
              _buildSegmentButton(
                label: 'ABSENT',
                isSelected: status == 'ABSENT',
                color: AppTheme.accentCoral,
                onTap: () => onChanged('ABSENT'),
                isFirst: false,
              ),
              _buildSegmentButton(
                label: 'NOT MARKED',
                isSelected: status == 'NOT_MARKED',
                color: theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.5),
                onTap: () => onChanged('NOT_MARKED'),
                isFirst: false,
                isLast: true,
                extraIcon: extraIcon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
    IconData? extraIcon,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border(
            top: BorderSide(color: isSelected ? color : theme.dividerColor.withValues(alpha: 0.3)),
            bottom: BorderSide(color: isSelected ? color : theme.dividerColor.withValues(alpha: 0.3)),
            left: BorderSide(color: isSelected ? color : theme.dividerColor.withValues(alpha: 0.3)),
            right: BorderSide(color: isSelected ? color : (isLast ? theme.dividerColor.withValues(alpha: 0.3) : Colors.transparent)),
          ),
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(4) : Radius.zero,
            right: isLast ? const Radius.circular(4) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
            if (isSelected && label != 'NOT MARKED') ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 12, color: color),
            ],
            if (extraIcon != null && !isSelected) ...[
              const SizedBox(width: 4),
              Icon(extraIcon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ]
          ],
        ),
      ),
    );
  }
}
