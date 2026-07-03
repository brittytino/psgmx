import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  double _teamSize = 12;
  
  bool _viewMembers = true;
  bool _viewProgress = true;
  bool _sendAnnouncements = true;
  bool _createAssessments = false;
  bool _manageRoles = false;

  final List<Map<String, String>> _teams = [
    {'name': 'Team Alpha', 'leader': 'Aarav Mehta'},
    {'name': 'Team Beta', 'leader': 'Ananya Singh'},
    {'name': 'Team Gamma', 'leader': 'Karthik R.'},
    {'name': 'Team Delta', 'leader': 'Meera Patel'},
    {'name': 'Team Epsilon', 'leader': 'Rohan Verma'},
    {'name': 'Team Zeta', 'leader': 'Diya Shah'},
    {'name': 'Team Eta', 'leader': 'Siddharth J.'},
    {'name': 'Team Theta', 'leader': 'Neha Verma'},
    {'name': 'Team Iota', 'leader': 'Aditya Kulkarni'},
    {'name': 'Team Kappa', 'leader': 'Pooja Nair'},
    {'name': 'Team Lambda', 'leader': 'Vikram Joshi'},
    {'name': 'Team Mu', 'leader': 'Tanvi Gupta'},
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
                  'Team & Role Management',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.shieldCheck, color: AppTheme.illusTerracotta, size: 12),
              ],
            ),
            Row(
              children: [
                Text(
                  'Organize your team. Assign roles. Empower leads.',
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
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Team Size Slider Section
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Team Size', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                Text('Adjust the team size to automatically organize members.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(_teamSize.toInt().toString(), style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                                  const SizedBox(width: 4),
                                  Text('Teams', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                              Text('120 Members', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('4', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppTheme.accentCoral,
                                inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.2),
                                thumbColor: AppTheme.accentCoral,
                                overlayColor: AppTheme.accentCoral.withValues(alpha: 0.2),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _teamSize,
                                min: 4,
                                max: 20,
                                divisions: 16,
                                onChanged: (value) {
                                  setState(() {
                                    _teamSize = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text('20', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Teams Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Teams', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(width: 4),
                        Text('(${_teams.length})', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentCoral,
                        side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(LucideIcons.wand2, size: 12),
                      label: Text('Auto Distribute', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return _buildTeamCard(team['name']!, team['leader']!, theme);
                  },
                ),
                const SizedBox(height: 32),
                
                // Role Permissions
                Text('Role Permissions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('Manage what team leaders can view and do.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildPermissionToggle('View team members', 'Allow leaders to view their team members.', LucideIcons.users, _viewMembers, (v) => setState(() => _viewMembers = v), theme),
                      _buildDivider(theme),
                      _buildPermissionToggle('View progress reports', 'Allow leaders to view team progress and analytics.', LucideIcons.barChart2, _viewProgress, (v) => setState(() => _viewProgress = v), theme),
                      _buildDivider(theme),
                      _buildPermissionToggle('Send announcements', 'Allow leaders to send announcements to their team.', LucideIcons.messageSquare, _sendAnnouncements, (v) => setState(() => _sendAnnouncements = v), theme),
                      _buildDivider(theme),
                      _buildPermissionToggle('Create assessments', 'Allow leaders to create quizzes and assessments.', LucideIcons.calendar, _createAssessments, (v) => setState(() => _createAssessments = v), theme),
                      _buildDivider(theme),
                      _buildPermissionToggle('Manage team roles', 'Allow leaders to assign roles within their team.', LucideIcons.settings, _manageRoles, (v) => setState(() => _manageRoles = v), theme),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                child: Row(
                  children: [
                    const RivePlaceholder(width: 48, height: 48, label: 'Team', icon: LucideIcons.users),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leaders empower. Teams achieve.', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          Text('Great teams are built with clarity and trust.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save Changes', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildTeamCard(String name, String leader, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(LucideIcons.moreVertical, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked Avatars
          SizedBox(
            height: 32,
            child: Stack(
              children: [
                _buildAvatar(0, const Color(0xFFFFCCBC)),
                _buildAvatar(16, const Color(0xFFC8E6C9)),
                _buildAvatar(32, const Color(0xFFBBDEFB)),
                _buildAvatar(48, const Color(0xFFFFF9C4), isLeader: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('10 members', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shield, size: 12, color: AppTheme.accentCoral),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leader, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Team Leader', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double leftPos, Color color, {bool isLeader = false}) {
    return Positioned(
      left: leftPos,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Icon(LucideIcons.user, size: 12, color: Colors.black.withValues(alpha: 0.4)),
            ),
            if (isLeader)
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.illusTerracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 8, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionToggle(String title, String desc, IconData icon, bool value, ValueChanged<bool> onChanged, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.accentCoral,
            inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 64, color: theme.dividerColor.withValues(alpha: 0.1));
  }
}
