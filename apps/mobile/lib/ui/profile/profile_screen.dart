import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/avatar_widget.dart';
import '../../models/app_user.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/leetcode_provider.dart';
import '../../services/ecampus_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin; // Passed from RootLayout to determine layout (s27 vs s29)
  
  const ProfileScreen({super.key, this.isAdmin = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 120.0), // Bottom padding for nav bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Your profile, your progress, your journey.',
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
                  Row(
                    children: [
                      _buildHeaderIconButton(LucideIcons.bell, theme, hasDot: true),
                      const SizedBox(width: 12),
                      _buildHeaderIconButton(LucideIcons.settings, theme),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Profile Card
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 4),
                      boxShadow: [
                        BoxShadow(color: theme.shadowColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: userProvider.currentUser != null
                        ? AvatarWidget(
                            name: userProvider.currentUser!.name,
                            avatarUrl: userProvider.currentUser!.avatarUrl,
                            gender: userProvider.currentUser!.gender,
                            radius: 40,
                          )
                        : const CircleAvatar(radius: 40, child: Icon(LucideIcons.user, size: 16)),
                  ),
                  const SizedBox(width: 20),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userProvider.currentUser?.name ?? 'Student', 
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(widget.isAdmin ? 'Placement Rep' : 'Student', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(widget.isAdmin ? 'Admin' : 'Batch', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text(widget.isAdmin ? 'PSG Institute' : 'PSG College of Technology', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Stats Row
              Row(
                children: [
                  Expanded(child: _buildStatItem('Longest Streak', '12', 'days', 2, true, LucideIcons.flame, const Color(0xFFFF7043), theme)),
                  Container(width: 1, height: 40, color: theme.dividerColor.withValues(alpha: 0.2)),
                  Expanded(child: _buildStatItem('Problems Solved', '248', '', 18, true, LucideIcons.fileCode2, const Color(0xFFFFB74D), theme)), // Wait, icon is code block in file
                  Container(width: 1, height: 40, color: theme.dividerColor.withValues(alpha: 0.2)),
                  Expanded(child: _buildStatItem('Readiness Score', '812', '', 34, true, LucideIcons.trophy, const Color(0xFFD4AF37), theme)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Lineage Card (Your Senior)
              if (userProvider.currentUser != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchLineageMentor(userProvider.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }
                    
                    final mentor = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader('YOUR SENIOR', theme),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.illusSage.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.graduationCap, color: AppTheme.illusSage),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mentor['full_name'] ?? 'Senior Student', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                    if (mentor['current_role_title'] != null && mentor['current_company'] != null)
                                      Text('${mentor['current_role_title']} @ ${mentor['current_company']}', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ),
                              if (mentor['linkedin_url'] != null)
                                IconButton(
                                  icon: const Icon(LucideIcons.link, color: Colors.blue),
                                  onPressed: () async {
                                    final url = Uri.tryParse(mentor['linkedin_url']);
                                    if (url != null && await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              
              // Admin Actions (Roleplay)
              if (userProvider.isPlacementRep) ...[
                _buildSectionHeader('ADMIN ACTIONS', theme),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile('View as Student', 'Experience the app as a student', LucideIcons.user, theme, onTap: () {
                         // Switch logic
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Student View')));
                      }),
                      _buildDivider(theme),
                      _buildSettingsTile('View as Team Leader', 'Experience the app as a team leader', LucideIcons.users, theme, onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Team Leader View')));
                      }),
                      _buildDivider(theme),
                      _buildSettingsTile('View as Coordinator', 'Experience the app as a coordinator', LucideIcons.shieldAlert, theme, onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Coordinator View')));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Sections
              _buildSectionHeader('ACCOUNT', theme),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile('Edit Profile', 'Update your personal information', LucideIcons.user, theme),
                    _buildDivider(theme),
                    _buildSettingsTile('Change Password', 'Keep your account secure', LucideIcons.lock, theme),
                    _buildDivider(theme),
                    _buildSettingsTile('Email Preferences', 'Manage what you receive', LucideIcons.mail, theme),
                    _buildDivider(theme),
                    _buildSettingsTile('Linked Accounts', 'Connect your accounts', LucideIcons.link, theme, showChevron: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionHeader('PREFERENCES', theme),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    // Theme Tile (Custom trailing)
                    _buildCustomTrailingTile(
                      'Theme', 'Choose light or dark theme', LucideIcons.sun, theme,
                      trailing: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isDarkMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_isDarkMode ? theme.colorScheme.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: !_isDarkMode ? Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.sun, size: 12, color: !_isDarkMode ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                    const SizedBox(width: 4),
                                    Text('Light', style: GoogleFonts.inter(fontSize: 8, fontWeight: !_isDarkMode ? FontWeight.bold : FontWeight.normal, color: !_isDarkMode ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isDarkMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isDarkMode ? theme.colorScheme.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: _isDarkMode ? Border.all(color: theme.dividerColor.withValues(alpha: 0.3)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.moon, size: 12, color: _isDarkMode ? theme.colorScheme.onSurface : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                    const SizedBox(width: 4),
                                    Text('Dark', style: GoogleFonts.inter(fontSize: 8, fontWeight: _isDarkMode ? FontWeight.bold : FontWeight.normal, color: _isDarkMode ? theme.colorScheme.onSurface : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(theme),
                    
                    // Push Notifications (Custom trailing)
                    _buildCustomTrailingTile(
                      'Push Notifications', 'Manage your notification settings', LucideIcons.bell, theme,
                      trailing: Switch(
                        value: _pushNotifications,
                        onChanged: (v) => setState(() => _pushNotifications = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.accentCoral,
                        inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    _buildDivider(theme),
                    
                    // Language
                    _buildCustomTrailingTile(
                      'Language', 'Choose your preferred language', LucideIcons.globe, theme,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('English', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                    _buildDivider(theme),
                    _buildSettingsTile('Data & Privacy', 'Manage your data and privacy', LucideIcons.shieldCheck, theme),
                    
                    if (!widget.isAdmin) ...[
                      _buildDivider(theme),
                      _buildSettingsTile('Help & Support', 'Get help and contact support', LucideIcons.helpCircle, theme),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (widget.isAdmin) ...[
                _buildSectionHeader('ADMIN TOOLS', theme),
                
                // Simulation Mode Toggle and Data Sync
                if (context.watch<UserProvider>().isActualPlacementRep) ...[
                  _buildDataSyncSection(theme),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.illusSage.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.illusSage.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.venetianMask, size: 16, color: Colors.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Simulation Mode', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                                  Text('Preview app as different roles', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserRole?>(
                              isExpanded: true,
                              value: context.watch<UserProvider>().simulatedRole,
                              hint: Text('No Simulation (Actual Role)', style: GoogleFonts.inter(fontSize: 11)),
                              icon: const Icon(LucideIcons.chevronDown, size: 12),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('No Simulation (Actual Role)')),
                                DropdownMenuItem(value: UserRole.coordinator, child: Text('Coordinator')),
                                DropdownMenuItem(value: UserRole.teamLeader, child: Text('Team Leader')),
                                DropdownMenuItem(value: UserRole.student, child: Text('Student')),
                              ],
                              onChanged: (UserRole? role) {
                                context.read<UserProvider>().setSimulationRole(role);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Simulation role set to ${role?.name ?? 'Actual Role'}'),
                                    backgroundColor: Colors.teal,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F5), // Light coral tint
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildAdminTile('Reports: Command Center', 'View analytics and insights', LucideIcons.barChart2, theme, onTap: () => context.push('/admin/command-center')),
                      _buildDivider(theme, isOrange: true),
                      _buildAdminTile('Team & Role Management', 'Manage teams and permissions', LucideIcons.users, theme, onTap: () => context.push('/admin/team-management')),
                      _buildDivider(theme, isOrange: true),
                      _buildAdminTile('Schedule Placement Session', 'Create and manage sessions', LucideIcons.calendar, theme, onTap: () => context.push('/admin/schedule-session')),
                      _buildDivider(theme, isOrange: true),
                      _buildAdminTile('Export Data', 'Download reports and data', LucideIcons.download, theme, onTap: () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                _buildSectionHeader('SUPPORT', theme),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile('Help & Support', 'Get help and contact support', LucideIcons.helpCircle, theme),
                      _buildDivider(theme),
                      _buildSettingsTile('About Placer', 'Learn more about the app', LucideIcons.info, theme, onTap: () => context.push('/credits')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Log Out
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCoral,
                  side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.surface,
                ),
                icon: const Icon(LucideIcons.logOut, size: 12),
                label: Text('Log Out', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              
              // App Version
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('App version 2.4.1 • You\'re all set! 🚀', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchLineageMentor(String currentUserId) async {
    try {
      final client = Supabase.instance.client;
      final lineageResponse = await client.from('lineage_map')
        .select('senior_user_id')
        .eq('junior_user_id', currentUserId)
        .maybeSingle();
        
      if (lineageResponse == null) return null;
      
      final seniorId = lineageResponse['senior_user_id'];
      
      final mentorResponse = await client.from('users')
        .select('full_name, current_company, current_role_title, linkedin_url')
        .eq('id', seniorId)
        .eq('mentorship_open', true)
        .maybeSingle();
        
      return mentorResponse;
    } catch (e) {
      debugPrint('Error fetching lineage mentor: $e');
      return null;
    }
  }

  Widget _buildHeaderIconButton(IconData icon, ThemeData theme, {bool hasDot = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          if (hasDot)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accentCoral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String unit, int diff, bool isUp, IconData icon, Color iconColor, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 8, color: isUp ? Colors.green : Colors.red),
                    Text(' $diff this week', style: GoogleFonts.inter(fontSize: 9, color: isUp ? Colors.green : Colors.red)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, ThemeData theme, {bool showChevron = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ),
            if (showChevron)
              Icon(LucideIcons.chevronRight, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(String title, String subtitle, IconData icon, ThemeData theme, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accentCoral),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 12, color: AppTheme.accentCoral.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTrailingTile(String title, String subtitle, IconData icon, ThemeData theme, {required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDataSyncSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.illusSage.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.illusSage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.database, size: 16, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Synchronization', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text('Manually trigger background syncs', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting LeetCode sync...')));
                    try {
                      final provider = context.read<LeetCodeProvider>();
                      await provider.refreshAllUsersFromAPI();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync complete! Updated all records.')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                    }
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 12),
                  label: const Text('Sync LeetCode'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo, elevation: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting eCampus sync...')));
                    try {
                      final service = EcampusService();
                      await service.syncAllUsers();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync complete! Processed users.')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                    }
                  },
                  icon: const Icon(LucideIcons.school, size: 12),
                  label: const Text('Sync eCampus'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo, elevation: 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, {bool isOrange = false}) {
    return Divider(height: 1, indent: 52, endIndent: 16, color: isOrange ? AppTheme.accentCoral.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.1));
  }
}
