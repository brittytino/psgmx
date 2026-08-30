import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  // Keep param for backwards compat but ignore it
  final bool isAdmin;
  const ProfileScreen({super.key, this.isAdmin = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You',
                            style: GoogleFonts.sora(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Your profile, your journey.',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B))),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.sparkles,
                                size: 12, color: AppTheme.illusGold),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Settings icon
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Center(
                                child: Icon(LucideIcons.settings,
                                    size: 18, color: Color(0xFF1E293B))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Profile Card ──────────────────────────────────────
                _ProfileCard(user: user),
                const SizedBox(height: 24),

                if (userProvider.isPlacementRep) ...[
                  _buildSectionHeader('YOUR WORKSPACES'),
                  _buildCard([
                    _NavTile(
                      icon: LucideIcons.shieldCheck,
                      iconColor: AppTheme.accentCoral,
                      label: 'PR Command Center',
                      subtitle: 'Manage readiness, squads and participation',
                      onTap: () => context.push('/admin'),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // ── ACCOUNT ───────────────────────────────────────────
                _buildSectionHeader('ACCOUNT'),
                _buildCard([
                  _NavTile(
                    icon: LucideIcons.mail,
                    iconColor: const Color(0xFF0EA5E9),
                    label: 'Email',
                    subtitle: user?.email ?? '—',
                    showChevron: false,
                  ),
                  _divider(),
                  _NavTile(
                    icon: LucideIcons.hash,
                    iconColor: const Color(0xFF6366F1),
                    label: 'Register Number',
                    subtitle: user?.regNo ?? '—',
                    showChevron: false,
                  ),
                  _divider(),
                  _NavTile(
                    icon: LucideIcons.code,
                    iconColor: const Color(0xFFEF4444),
                    label: 'LeetCode Username',
                    subtitle: user?.leetcodeUsername?.isNotEmpty == true
                        ? user!.leetcodeUsername!
                        : 'Not set',
                    onTap: () => _showLeetcodeSheet(context, userProvider),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── INFO ──────────────────────────────────────────────
                _buildSectionHeader('INFO'),
                _buildCard([
                  _NavTile(
                    icon: LucideIcons.shieldCheck,
                    iconColor: const Color(0xFF22C55E),
                    label: 'Data Privacy',
                    subtitle: 'How we protect your data',
                    onTap: () => _launchUrl('https://psgmx.in/privacy'),
                  ),
                  _divider(),
                  _NavTile(
                    icon: LucideIcons.helpCircle,
                    iconColor: const Color(0xFF64748B),
                    label: 'Help & Support',
                    subtitle: 'Get help or report an issue',
                    onTap: () => context.push('/help-support'),
                  ),
                  _divider(),
                  _NavTile(
                    icon: LucideIcons.info,
                    iconColor: const Color(0xFF64748B),
                    label: 'About PSGMX',
                    subtitle: 'Version, team & credits',
                    onTap: () => context.push('/credits'),
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Sign Out ──────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _signingOut
                      ? null
                      : () => _confirmSignOut(context, userProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side:
                        const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _signingOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF4444), strokeWidth: 2))
                      : const Icon(LucideIcons.logOut, size: 16),
                  label: Text('Sign Out',
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 52, endIndent: 16, color: Color(0xFFF1F5F9));

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showLeetcodeSheet(BuildContext context, UserProvider userProvider) {
    final ctrl = TextEditingController(
        text: userProvider.currentUser?.leetcodeUsername ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('LeetCode Username',
                  style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text('Link your LeetCode profile to track your progress.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. john_doe or a LeetCode profile URL',
                  helperText:
                      'Used for your live progress and batch leaderboard.',
                  labelStyle: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF64748B)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppTheme.accentCoral)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final username = ctrl.text.trim();
                        if (username.isEmpty) return;
                        try {
                          await userProvider.updateLeetCodeUsername(username);
                          if (context.mounted) Navigator.pop(context);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error
                                    .toString()
                                    .replaceFirst('FormatException: ', '')),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Save',
                          style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, UserProvider userProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.sora(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: GoogleFonts.sora(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _signingOut = true);
      try {
        await userProvider.signOut();
      } finally {
        if (mounted) setState(() => _signingOut = false);
      }
    }
  }
}

// ─── Profile Card ──────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Student';
    final reg = user?.regNo ?? '';
    final email = user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: AvatarWidget(
                avatarUrl: user?.avatarUrl,
                name: name,
                gender: user?.gender,
                radius: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(reg,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(email,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Tile Widgets ─────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            if (showChevron)
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
