import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ecampus_attendance.dart';
import '../../models/ecampus_cgpa.dart';
import '../../models/ecampus_ca_timetable.dart';

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

  @override
  Widget build(BuildContext context) {
    final ecampus = Provider.of<EcampusProvider>(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => await ecampus.sync(),
            color: AppTheme.accentCoral,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildHeader(ecampus),
                  ),
                ),

                // ── Password-failed banner ──────────────────────────────
                if (ecampus.isLoginFailed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _PasswordBanner(ecampus: ecampus),
                    ),
                  ),

                // ── Loading / No data ───────────────────────────────────
                if (ecampus.isLoading || ecampus.isSyncing)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
                  )
                else if (!ecampus.hasData && !ecampus.isLoginFailed)
                  SliverFillRemaining(child: _buildNoData(ecampus))
                else ...[
                  // ── Attendance Radar ──────────────────────────────────
                  if (ecampus.attendance != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _AttendanceCard(attendance: ecampus.attendance!),
                      ),
                    ),

                  // ── CGPA ──────────────────────────────────────────────
                  if (ecampus.cgpa != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _CgpaCard(cgpa: ecampus.cgpa!),
                      ),
                    ),

                  // ── CA Timetable ───────────────────────────────────────
                  if (ecampus.caTimetable != null && ecampus.caTimetable!.rows.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _CaTimetableCard(timetable: ecampus.caTimetable!),
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EcampusProvider ecampus) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus',
              style: GoogleFonts.sora(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Academic insight from eCampus.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Sync button
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ecampus.sync();
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: const Center(
              child: Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoData(EcampusProvider ecampus) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.graduationCap, size: 36, color: AppTheme.accentCoral),
            ),
            const SizedBox(height: 16),
            Text('No Academic Data', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(
              'Your eCampus data will appear here after the first sync.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            if (ecampus.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ecampus.errorMessage!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444))),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ecampus.sync(),
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text('Sync Now', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Password Banner ───────────────────────────────────────────────────────
class _PasswordBanner extends StatelessWidget {
  final EcampusProvider ecampus;
  const _PasswordBanner({required this.ecampus});

  void _showPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordSheet(ecampus: ecampus),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            child: const Icon(LucideIcons.lockKeyhole, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('eCampus login failed', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7F1D1D))),
                const SizedBox(height: 2),
                Text('Password changed? Update it here →', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showPasswordSheet(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text('Update', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Password Sheet ────────────────────────────────────────────────────────
class _PasswordSheet extends StatefulWidget {
  final EcampusProvider ecampus;
  const _PasswordSheet({required this.ecampus});
  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await Provider.of<UserProvider>(context, listen: false)
          .updateEcampusPassword(_ctrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated. Syncing data…', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Trigger re-sync
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user != null) widget.ecampus.sync();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Update eCampus Password', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text('Enter your current eCampus portal password. It\'s stored securely and only used for syncing your data.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              obscureText: _obscure,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'eCampus Password',
                labelStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentCoral)),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: const Color(0xFF94A3B8)),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentCoral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save & Sync', style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Attendance Card with Radar ────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final EcampusAttendance attendance;
  const _AttendanceCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final subjects = attendance.subjects;
    final summary = attendance.summary;

    // Build radar data (up to 6 subjects for readability)
    final radarSubjects = subjects.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.accentCoral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.checkCircle, size: 18, color: AppTheme.accentCoral),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Overview', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text('Overall: ${summary.overallPercentage.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              _AttendanceBadge(pct: summary.overallPercentage),
            ],
          ),

          // Radar chart
          if (radarSubjects.length >= 3) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: _AttendanceRadar(subjects: radarSubjects),
            ),
          ],

          // Subject list
          const SizedBox(height: 16),
          ...subjects.map((s) => _SubjectAttRow(subject: s)),
        ],
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final double pct;
  const _AttendanceBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = pct >= 75 ? const Color(0xFF22C55E) : pct >= 65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        '${pct.toStringAsFixed(1)}%',
        style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _AttendanceRadar extends StatelessWidget {
  final List<SubjectAttendance> subjects;
  const _AttendanceRadar({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final entries = subjects.map((s) {
      return RadarEntry(value: s.percentage / 100);
    }).toList();

    final featureCount = subjects.length;

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: AppTheme.accentCoral.withValues(alpha: 0.15),
            borderColor: AppTheme.accentCoral,
            entryRadius: 4,
            dataEntries: entries,
          ),
          RadarDataSet(
            fillColor: Colors.transparent,
            borderColor: Colors.transparent,
            entryRadius: 0,
            dataEntries: List.generate(featureCount, (_) => const RadarEntry(value: 1.0)),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Color(0xFFE2E8F0)),
        gridBorderData: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
        tickCount: 4,
        ticksTextStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
        tickBorderData: const BorderSide(color: Color(0xFFF1F5F9)),
        getTitle: (index, _) {
          final s = subjects[index];
          final label = s.courseCode.isNotEmpty ? s.courseCode : s.courseTitle;
          return RadarChartTitle(
            text: label.length > 8 ? label.substring(0, 8) : label,
            angle: 0,
          );
        },
        titleTextStyle: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
        titlePositionPercentageOffset: 0.2,
      ),
    );
  }
}

class _SubjectAttRow extends StatelessWidget {
  final SubjectAttendance subject;
  const _SubjectAttRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final color = subject.isSafe
        ? const Color(0xFF22C55E)
        : subject.isCritical
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.courseTitle,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${subject.percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: subject.percentage / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('${subject.totalPresent}/${subject.totalHours} hrs',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              const Spacer(),
              if (subject.canBunk > 0)
                Text('Can miss ${subject.canBunk}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF22C55E)))
              else if (subject.classesToAttend > 0)
                Text('Need +${subject.classesToAttend}',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CGPA Card ─────────────────────────────────────────────────────────────
class _CgpaCard extends StatelessWidget {
  final EcampusCgpa cgpa;
  const _CgpaCard({required this.cgpa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.award, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CGPA', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Text('${cgpa.totalSemesters} semesters • ${cgpa.totalCredits} credits', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cgpa.cgpa.toStringAsFixed(2),
                  style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          if (cgpa.semesterSgpa.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Semester SGPA', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
            const SizedBox(height: 10),
            ...cgpa.semesterSgpa.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(s.semester, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s.sgpa.toStringAsFixed(2), style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── CA Timetable Card ─────────────────────────────────────────────────────
class _CaTimetableCard extends StatelessWidget {
  final EcampusCaTimetable timetable;
  const _CaTimetableCard({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final headers = timetable.headers;
    final rows = timetable.rows;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.clipboardCheck, size: 18, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CA Timetable', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  if (timetable.note != null)
                    Text(timetable.note!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.take(6).map((row) {
            // Try to extract common fields by header name
            final subject = row['Subject'] ?? row['Course'] ?? row['subject'] ?? row.values.firstOrNull ?? 'Exam';
            final date = row['Date'] ?? row['date'] ?? '';
            final time = row['Time'] ?? row['time'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.bookOpen, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(subject, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                  if (date.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(date, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                        if (time.isNotEmpty)
                          Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
