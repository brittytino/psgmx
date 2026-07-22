import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;

import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ecampus_cgpa.dart';

class BunkerScreen extends StatefulWidget {
  const BunkerScreen({super.key});

  @override
  State<BunkerScreen> createState() => _BunkerScreenState();
}

class _BunkerScreenState extends State<BunkerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (user != null && user.regNo.isNotEmpty) {
        Provider.of<EcampusProvider>(context, listen: false).init(user.regNo);
      }
    });
  }

  void _showPasswordUpdateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _UpdatePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ecampus = Provider.of<EcampusProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    final attendance = ecampus.attendance;
    final cgpa = ecampus.cgpa;
    final timetable = ecampus.caTimetable;
    
    final lastSyncedAt = ecampus.lastSyncedAt;
    String lastSyncText = 'Never synced';
    if (lastSyncedAt != null) {
      final now = DateTime.now();
      if (lastSyncedAt.year == now.year && lastSyncedAt.month == now.month && lastSyncedAt.day == now.day) {
        lastSyncText = 'Today, ${DateFormat('h:mm a').format(lastSyncedAt)}';
      } else {
        lastSyncText = DateFormat('MMM d, h:mm a').format(lastSyncedAt);
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ecampus.sync();
          },
          color: AppTheme.accentCoral,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Academic Insights',
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your academic overview, all in one place.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF1F8E9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6, height: 6, 
                                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)
                                    ),
                                    const SizedBox(width: 6),
                                      Text(
                                        'Last synced: $lastSyncText',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ecampus.sync(),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                                  ),
                                  child: ecampus.isSyncing 
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCoral))
                                    : Icon(LucideIcons.refreshCcw, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const RivePlaceholder(width: 60, height: 60, label: 'Graduation Cap', icon: LucideIcons.graduationCap),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Failed Banner
                if (ecampus.isLoginFailed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppTheme.accentCoral),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Failed',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your eCampus password may have changed. Update it to resume syncing.',
                                style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _showPasswordUpdateSheet,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentCoral,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Update', style: TextStyle(fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                // Error Message (Generic)
                if (ecampus.errorMessage != null && !ecampus.isLoginFailed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ecampus.errorMessage!,
                      style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.error),
                    ),
                  ),

                // Subject Attendance
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subject Attendance',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (attendance != null)
                              Text(
                                'Overall: ${attendance.summary.overallPercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentCoral,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (ecampus.isLoading && attendance == null)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
                        )
                      else if (attendance == null || attendance.subjects.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No attendance data available.',
                              style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: attendance.subjects.map((subj) {
                              final titleWords = subj.courseTitle.split(' ');
                              String shortTitle = subj.courseTitle;
                              if (titleWords.length > 2) {
                                shortTitle = '${titleWords[0]}\n${titleWords[1]}';
                              } else if (titleWords.length == 2) {
                                shortTitle = '${titleWords[0]}\n${titleWords[1]}';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 24),
                                child: _buildSubjectGauge(shortTitle, subj.percentage / 100, theme),
                              );
                            }).toList(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '* Attendance reflects portal data',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CGPA Trend
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CGPA Trend',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Current CGPA',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: cgpa?.cgpa.toStringAsFixed(2) ?? '--',
                                      style: GoogleFonts.sora(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentCoral,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/10',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (ecampus.isLoading && cgpa == null)
                        const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
                        )
                      else if (cgpa == null || cgpa.semesterSgpa.isEmpty)
                        SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'CGPA history not available.',
                              style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _CgpaChartPainter(
                              color: AppTheme.accentCoral,
                              history: cgpa.semesterSgpa,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.trendingUp, size: 12, color: AppTheme.accentCoral),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed ${cgpa.totalCredits} Credits!',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentCoral,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Next Classes (Global CA Timetable)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                          Text(
                            'Exam Timetable',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (timetable == null || !timetable.hasData)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No upcoming exams found.',
                              style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            ),
                          ),
                        )
                      else ...[
                        for (int i = 0; i < timetable.rows.length; i++) ...[
                          _buildTimelineItem(
                            date: timetable.rows[i]['Date'] ?? '',
                            title: timetable.rows[i]['Course'] ?? '',
                            session: timetable.rows[i]['Session'] ?? '',
                            isLast: i == timetable.rows.length - 1,
                            theme: theme,
                          ),
                        ]
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Stats Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomStat(
                        attendance != null ? '${attendance.summary.overallPercentage.toStringAsFixed(1)}%' : '--', 
                        'Attendance', LucideIcons.bookOpen, theme
                      ),
                      _buildBottomStat(
                        cgpa?.cgpa.toStringAsFixed(2) ?? '--', 
                        'CGPA', LucideIcons.trendingUp, theme
                      ),
                      _buildBottomStat(
                        cgpa != null ? '${cgpa.totalCredits}' : '--', 
                        'Credits', LucideIcons.target, theme
                      ),
                      _buildBottomStat(
                        attendance != null ? '${attendance.subjects.length}' : '--', 
                        'Subjects', LucideIcons.layers, theme
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120), // Bottom padding for navbar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGauge(String title, double progress, ThemeData theme) {
    Color getColor(double val) {
      if (val >= 0.8) return AppTheme.accentCoral;
      if (val >= 0.7) return const Color(0xFFFF9800);
      return AppTheme.accentCoral.withValues(alpha: 0.6); 
    }
    
    final color = getColor(progress);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RadialGaugePainter(
                    progress: progress,
                    color: color,
                    trackColor: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
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
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String title,
    required String session,
    required bool isLast,
    required ThemeData theme,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2E) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStat(String value, String label, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _UpdatePasswordSheet extends StatefulWidget {
  const _UpdatePasswordSheet();

  @override
  State<_UpdatePasswordSheet> createState() => _UpdatePasswordSheetState();
}

class _UpdatePasswordSheetState extends State<_UpdatePasswordSheet> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final ecampusProvider = Provider.of<EcampusProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Update eCampus Password',
            style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'By default, your password is your DOB. If you changed it on the portal, enter your custom password below so we can sync your academic data.',
            style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Custom eCampus Password',
              hintText: 'Enter new password or leave blank for DOB',
              prefixIcon: Icon(LucideIcons.lock, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                final password = _passwordController.text;
                await userProvider.updateEcampusPassword(password.isEmpty ? null : password);
                if (userProvider.currentUser != null) {
                  await ecampusProvider.syncAfterCredentialUpdate(userProvider.currentUser!.regNo);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save & Sync'),
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RadialGaugePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

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
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CgpaChartPainter extends CustomPainter {
  final Color color;
  final List<SemesterSgpa> history;
  final ThemeData theme;

  _CgpaChartPainter({required this.color, required this.history, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isDark = theme.brightness == Brightness.dark;

    final gridPaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 5; i++) {
      final y = h - (h * (i / 5));
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      
      final textSpan = TextSpan(
        text: '${i * 2}',
        style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(-20, y - 6));
    }

    if (history.isEmpty) return;

    final points = <Offset>[];
    final xStep = history.length > 1 ? w / (history.length - 1) : w / 2;
    
    for (int i = 0; i < history.length; i++) {
      final x = history.length == 1 ? w / 2 : i * xStep;
      final val = history[i].sgpa;
      final y = h - (h * (val / 10));
      points.add(Offset(x, y));
      
      final textSpan = TextSpan(
        text: history[i].semester.replaceAll('Semester', 'S').trim(),
        style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), h + 10));
      
      final dataSpan = TextSpan(
        text: val.toStringAsFixed(2),
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
      );
      final dataPainter = TextPainter(text: dataSpan, textDirection: TextDirection.ltr);
      dataPainter.layout();
      dataPainter.paint(canvas, Offset(x - (dataPainter.width / 2), y - 24));
    }

    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, h);
      path.lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, h);
      path.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isDark ? 0.4 : 0.3),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(0, 0, w, h));
        
      canvas.drawPath(path, gradientPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = theme.colorScheme.surface;
    final dotStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      final r = isLast ? 6.0 : 4.0;
      canvas.drawCircle(points[i], r, dotPaint);
      canvas.drawCircle(points[i], r, dotStrokePaint);
      
      if (isLast) {
        final lastDotPaint = Paint()..color = color;
        canvas.drawCircle(points[i], 3.0, lastDotPaint);
      } else {
        final innerDotPaint = Paint()..color = color;
        canvas.drawCircle(points[i], 2.0, innerDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
