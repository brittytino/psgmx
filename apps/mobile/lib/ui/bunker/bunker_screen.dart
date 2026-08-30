import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ecampus_attendance.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/user_provider.dart';

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
      final user = context.read<UserProvider>().currentUser;
      if (user != null && user.regNo.isNotEmpty) {
        context.read<EcampusProvider>().init(user.regNo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcampusProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.sync,
          color: AppTheme.accentCoral,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Attendance',
                            style: GoogleFonts.sora(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Academic attendance and weekly timetable.',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFF64748B)))
                      ])),
                  IconButton.filledTonal(
                      onPressed: provider.isSyncing ? null : provider.sync,
                      icon: provider.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.refreshCw, size: 18))
                ]),
              )),
              if (provider.isLoginFailed)
                SliverToBoxAdapter(child: _LoginBanner(provider: provider)),
              if (provider.isLoading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (provider.attendance == null)
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyAttendance(provider: provider))
              else ...[
                SliverToBoxAdapter(
                    child: _SummaryCard(attendance: provider.attendance!)),
                if (provider.timetable != null)
                  SliverToBoxAdapter(
                      child: _WeeklyTimetableCard(
                          timetable: provider.timetable!)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: provider.attendance!.subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _SubjectTile(
                        subject: provider.attendance!.subjects[index]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyTimetableCard extends StatelessWidget {
  const _WeeklyTimetableCard({required this.timetable});
  final EcampusWeeklyTimetable timetable;

  @override
  Widget build(BuildContext context) {
    if (timetable.headers.isEmpty || timetable.rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.calendarDays,
                size: 18, color: AppTheme.accentCoral),
            const SizedBox(width: 8),
            Text('Weekly timetable',
                style: GoogleFonts.sora(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 64,
              horizontalMargin: 10,
              columnSpacing: 18,
              columns: timetable.headers
                  .map((header) => DataColumn(
                      label: Text(header,
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w800))))
                  .toList(),
              rows: timetable.rows
                  .map((row) => DataRow(
                      cells: List.generate(
                          timetable.headers.length,
                          (index) => DataCell(SizedBox(
                              width: index == 0 ? 64 : 92,
                              child: Text(index < row.length ? row[index] : '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 11)))))))
                  .toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.attendance});
  final EcampusAttendance attendance;
  @override
  Widget build(BuildContext context) {
    final summary = attendance.summary;
    final safe = summary.isSafe;
    final color = safe ? const Color(0xFF16A34A) : AppTheme.accentCoral;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: const Color(0xFF17132D),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF17132D).withValues(alpha: .16),
                    blurRadius: 24,
                    offset: const Offset(0, 12))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('OVERALL ATTENDANCE',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white60,
                    letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${summary.overallPercentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.sora(
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(safe ? 'On track' : 'Needs attention',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: safe
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5))))
            ]),
            const SizedBox(height: 18),
            ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                    value: (summary.overallPercentage / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color))),
            const SizedBox(height: 14),
            Text(
                '${summary.totalPresent} of ${summary.totalHours} academic hours attended',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
                summary.overallNeedAttend > 0
                    ? 'Attend the next ${summary.overallNeedAttend} hour(s) to recover.'
                    : 'You can miss ${summary.overallCanBunk} hour(s) and remain at 75%.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
        ));
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});
  final SubjectAttendance subject;
  @override
  Widget build(BuildContext context) {
    final color = subject.isSafe
        ? const Color(0xFF16A34A)
        : subject.isCritical
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF0))),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14)),
              child: Text('${subject.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    subject.courseTitle.isEmpty
                        ? subject.courseCode
                        : subject.courseTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033))),
                const SizedBox(height: 4),
                Text(
                    '${subject.totalPresent}/${subject.totalHours} hours · ${subject.courseCode}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF64748B)))
              ])),
          Text(
              subject.classesToAttend > 0
                  ? '+${subject.classesToAttend}'
                  : '${subject.canBunk}',
              style: GoogleFonts.sora(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color))
        ]));
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance({required this.provider});
  final EcampusProvider provider;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.calendarCheck,
                size: 44, color: AppTheme.accentCoral),
            const SizedBox(height: 16),
            Text('Attendance not synced yet',
                style: GoogleFonts.sora(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                provider.errorMessage ??
                    'Refresh once to securely fetch your academic attendance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: provider.sync,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Refresh attendance'))
          ])));
}

class _LoginBanner extends StatelessWidget {
  const _LoginBanner({required this.provider});
  final EcampusProvider provider;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(LucideIcons.lockKeyhole, color: Color(0xFFDC2626)),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('eCampus rejected your portal password.',
                    style: TextStyle(fontWeight: FontWeight.w700))),
            TextButton(
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _PasswordSheet(provider: provider)),
                child: const Text('Update'))
          ])));
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.provider});
  final EcampusProvider provider;
  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final controller = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update eCampus password',
                style: GoogleFonts.sora(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Portal password',
                    border: OutlineInputBorder())),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            final user =
                                context.read<UserProvider>().currentUser;
                            await context
                                .read<UserProvider>()
                                .updateEcampusPassword(controller.text);
                            if (user != null) {
                              await widget.provider
                                  .syncAfterCredentialUpdate(user.regNo);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(saving ? 'Updating…' : 'Save and refresh')))
          ]));
}
