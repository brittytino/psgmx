import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

class SchedulePlacementSessionScreen extends StatefulWidget {
  const SchedulePlacementSessionScreen({super.key});

  @override
  State<SchedulePlacementSessionScreen> createState() => _SchedulePlacementSessionScreenState();
}

class _SchedulePlacementSessionScreenState extends State<SchedulePlacementSessionScreen> {
  String _selectedType = 'Placement Drive';
  final List<String> _selectedTeams = ['Team Alpha', 'Team Beta', 'Team Epsilon'];

  final List<String> _types = ['Placement Drive', 'Mock Test', 'Workshop', 'Webinar', 'Other'];
  final List<String> _allTeams = [
    'Team Alpha', 'Team Beta', 'Team Gamma', 'Team Delta', 
    'Team Epsilon', 'Team Zeta', 'Team Eta', 'Team Theta',
    'Team Iota', 'Team Kappa', 'Team Lambda', 'Team Mu'
  ];

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
                  'Schedule Placement Session',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.calendar, color: AppTheme.accentCoral, size: 12),
              ],
            ),
            Row(
              children: [
                Text(
                  'Plan today. Impact tomorrow.',
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Icon(LucideIcons.fileText, size: 12, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner
                Row(
                  children: [
                    const RivePlaceholder(width: 100, height: 100, label: 'Calendar', icon: LucideIcons.calendarClock),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create a new session', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text('Pick a date, choose the topic, select teams and publish. Students will be notified instantly.', 
                            style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Session Date & Time
                Text('Session Date & Time', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField('21 May, 2024', LucideIcons.calendar, theme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField('04:00 PM', LucideIcons.clock, theme),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Time zone: Asia/Kolkata (IST)', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                const SizedBox(height: 24),
                
                // Session Topic
                Text('Session Topic', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Design Basics: Scalable Architectures', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
                      Text('41/80', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Add a topic that helps students know what to expect.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                const SizedBox(height: 24),
                
                // Session Type
                Text('Session Type', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _types.map((type) => _buildTypeChip(type, type == _selectedType, theme)).toList(),
                ),
                const SizedBox(height: 24),
                
                // Select Target Teams
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Target Teams', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text('Select All', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _allTeams.map((team) => _buildTeamChip(team, _selectedTeams.contains(team), theme)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.users, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Text('${_selectedTeams.length} teams selected  •  ${_selectedTeams.length * 10} members will be notified', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Session Description
                Text('Session Description (Optional)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'An interactive session to understand core System Design principles and how to design scalable systems.',
                        style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text('104/250', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Live Preview
                Row(
                  children: [
                    const Icon(LucideIcons.eye, size: 12),
                    const SizedBox(width: 8),
                    Text('Preview', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Text('(Students will see this)', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Live preview', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreviewCard(theme),
              ],
            ),
          ),
          
          // Fixed Bottom Section
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Save Draft', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accentCoral,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(LucideIcons.send, size: 12),
                            label: Text('Schedule & Publish', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.lock, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text('You can edit or cancel this session anytime.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Text(value, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
            ],
          ),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCoral : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamChip(String label, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTeams.remove(label);
          } else {
            _selectedTeams.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, size: 12, color: AppTheme.accentCoral),
            ] else ...[
              const SizedBox(width: 8),
              Icon(Icons.circle_outlined, size: 12, color: theme.dividerColor.withValues(alpha: 0.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('TUE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                Text('21', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                Text('MAY', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Placement Session', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('System Design Basics: Scalable Architectures', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    const RivePlaceholder(width: 48, height: 48, label: 'Board', icon: LucideIcons.presentation),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text('04:00 PM - 05:30 PM (IST)', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.users, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text('30 Members', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    children: [
                      const TextSpan(text: 'Teams: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Alpha, Beta, Epsilon', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'An interactive session to understand core System Design principles and how to design scalable systems.',
                  style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
