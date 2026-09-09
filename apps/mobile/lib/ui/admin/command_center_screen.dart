import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/premium_card.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _pulse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw const FormatException('Your session has expired.');
      }
      final response = await http.get(
        Uri.parse('${SupabaseConfig.appApiUrl}/api/placement-rep/pulse'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw FormatException(
            body['error']?.toString() ?? 'Could not load readiness.');
      }
      if (!mounted) return;
      setState(() {
        _pulse = body;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is FormatException
            ? error.message
            : 'The live batch pulse could not be refreshed.';
      });
    }
  }

  num? _number(String key) => _pulse?[key] as num?;

  void _openQuestPauseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuestPauseSheet(),
    );
  }

  void _openAttendanceCorrectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AttendanceCorrectionSheet(),
    );
  }

  void _openAnnouncementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AnnouncementSheet(),
    );
  }

  void _openSquadObjectiveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SquadObjectiveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = _pulse?['batchCode']?.toString() ?? '—';
    final bands =
        Map<String, dynamic>.from((_pulse?['bandCounts'] as Map?) ?? const {});
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PR Command Center',
              style:
                  GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('Batch-level preparation pulse',
              style:
                  GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedText)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(LucideIcons.refreshCw, size: 19))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) _Notice(message: _error!, onRetry: _load),
            if (_pulse != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: const Color(0xFF17132D),
                    borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(LucideIcons.shieldCheck,
                          color: Colors.white)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('$batch live pulse',
                            style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            'Aggregate signals only. Individual readiness stays private.',
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                height: 1.4))
                      ])),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Quick actions',
                  style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                  'Urgent items only — deep administration stays on the PR web console.',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.mutedText)),
              const SizedBox(height: 12),
              _QuickActionTile(
                icon: LucideIcons.pauseCircle,
                title: 'Pause or resume a quest',
                subtitle: 'Toggle visibility on quests you authored',
                onTap: () => _openQuestPauseSheet(context),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: LucideIcons.calendarCheck2,
                title: 'Correct session attendance',
                subtitle: 'Fix a participation record for a past session',
                onTap: () => _openAttendanceCorrectionSheet(context),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: LucideIcons.megaphone,
                title: 'Send an announcement',
                subtitle: 'Post an update to the whole batch',
                onTap: () => _openAnnouncementSheet(context),
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: LucideIcons.target,
                title: 'Set a squad objective',
                subtitle: 'Set the weekly objective a squad sees',
                onTap: () => _openSquadObjectiveSheet(context),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _Metric(
                      label: 'Students',
                      value: '${_number('totalStudents') ?? 0}',
                      note:
                          '${_number('activeThisWeekPct') ?? 0}% active this week',
                      icon: LucideIcons.users),
                  _Metric(
                      label: 'Readiness',
                      value: _number('avgReadinessScore') == null
                          ? '—'
                          : '${_number('avgReadinessScore')}/100',
                      note: 'Verified evidence',
                      icon: LucideIcons.activity),
                  _Metric(
                      label: 'Attendance',
                      value: _number('avgAttendance') == null
                          ? '—'
                          : '${(_number('avgAttendance')!).round()}%',
                      note: 'Preparation sessions',
                      icon: LucideIcons.calendarCheck),
                  _Metric(
                      label: 'Upcoming',
                      value: '${_number('upcomingSessions') ?? 0}',
                      note: 'Scheduled sessions',
                      icon: LucideIcons.calendarClock),
                ],
              ),
              const SizedBox(height: 20),
              Text('Readiness distribution',
                  style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                  'Counts guide batch preparation without exposing student scores.',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.mutedText)),
              const SizedBox(height: 12),
              _BandCard(bands: bands),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                    borderRadius: BorderRadius.circular(17)),
                child: Row(children: [
                  const Icon(LucideIcons.shieldAlert,
                      size: 19, color: Color(0xFFEA580C)),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Text(
                          '${_number('declineSignalCount') ?? 0} recovery signals were routed privately to faculty. PR accounts cannot open individual scores.',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9A3412))))
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  const _Metric(
      {required this.label,
      required this.value,
      required this.note,
      required this.icon});

  @override
  Widget build(BuildContext context) => PremiumCard(
        padding: const EdgeInsets.all(14),
        radius: AppRadius.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.accentCoral, size: 18),
          const Spacer(),
          Text(value,
              style:
                  GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
          Text(note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 8, color: AppTheme.mutedText))
        ]),
      );
}

class _BandCard extends StatelessWidget {
  final Map<String, dynamic> bands;
  const _BandCard({required this.bands});

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('strong', 'Strong', Color(0xFF2563EB)),
      ('building', 'Building', Color(0xFFF59E0B)),
      ('needs_attention', 'Needs attention', Color(0xFF7C3AED)),
      ('at_risk', 'At risk', Color(0xFFDC2626))
    ];
    final total = entries.fold<int>(
        0, (sum, item) => sum + ((bands[item.$1] as num?)?.toInt() ?? 0));
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: AppRadius.card,
      child: total == 0
          ? Text('No readiness evidence has been computed yet.',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedText))
          : Column(
              children: entries.map((item) {
              final count = (bands[item.$1] as num?)?.toInt() ?? 0;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.$2,
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                          Text('$count',
                              style: GoogleFonts.sora(
                                  fontSize: 11, fontWeight: FontWeight.w900))
                        ]),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                        value: count / total,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(8),
                        color: item.$3,
                        backgroundColor: const Color(0xFFF1F5F9))
                  ]));
            }).toList()),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => PremiumCard(
        onTap: onTap,
        radius: AppRadius.card,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: AppTheme.primaryPurple)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.mutedText)),
              ])),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppTheme.mutedText),
        ]),
      );
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title,
                        style: GoogleFonts.sora(
                            fontSize: 16, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 12),
            Expanded(
                child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [child])),
          ]),
        ),
      );
}

class _QuestPauseSheet extends StatefulWidget {
  const _QuestPauseSheet();
  @override
  State<_QuestPauseSheet> createState() => _QuestPauseSheetState();
}

class _QuestPauseSheetState extends State<_QuestPauseSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quests = const [];
  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = context.read<UserProvider>().currentUser?.uid;
      if (userId == null) throw Exception('Not signed in.');
      final rows = await Supabase.instance.client
          .from('quests')
          .select('id, title, status, type')
          .eq('authored_by', userId)
          .order('created_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _quests = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your quests.';
      });
    }
  }

  Future<void> _toggle(Map<String, dynamic> quest) async {
    final id = quest['id'] as String;
    final next = quest['status'] == 'paused' ? 'published' : 'paused';
    setState(() => _updating.add(id));
    try {
      await Supabase.instance.client
          .from('quests')
          .update({'status': next}).eq('id', id);
      if (!mounted) return;
      setState(() {
        quest['status'] = next;
        _updating.remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update that quest.')));
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Pause or resume a quest',
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? Text(_error!, style: GoogleFonts.inter(fontSize: 12))
                : _quests.isEmpty
                    ? Text('You have not authored any quests yet.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.mutedText))
                    : Column(
                        children: _quests.map((quest) {
                        final status = quest['status'] as String;
                        final isPaused = status == 'paused';
                        final isArchived = status == 'archived';
                        final id = quest['id'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.cardBorder)),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(quest['title']?.toString() ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${quest['type']} · $status',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppTheme.mutedText)),
                                  ])),
                              if (!isArchived)
                                _updating.contains(id)
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : TextButton(
                                        onPressed: () => _toggle(quest),
                                        child: Text(
                                            isPaused ? 'Resume' : 'Pause')),
                            ]),
                          ),
                        );
                      }).toList()),
      );
}

class _AttendanceCorrectionSheet extends StatefulWidget {
  const _AttendanceCorrectionSheet();
  @override
  State<_AttendanceCorrectionSheet> createState() =>
      _AttendanceCorrectionSheetState();
}

class _AttendanceCorrectionSheetState
    extends State<_AttendanceCorrectionSheet> {
  DateTime _date = DateTime.now();
  bool _loaded = false;
  final Map<String, String> _pendingStatus = {};
  bool _submitting = false;
  String? _sessionId;
  bool _isLocked = false;
  bool _togglingLock = false;

  Future<void> _loadFor(DateTime date) async {
    setState(() {
      _date = date;
      _loaded = false;
    });
    final dateStr = date.toIso8601String().split('T').first;
    try {
      final session = await Supabase.instance.client
          .from('placement_sessions')
          .select('id, is_locked')
          .gte('session_datetime', '${dateStr}T00:00:00Z')
          .lte('session_datetime', '${dateStr}T23:59:59Z')
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _sessionId = session?['id'] as String?;
        _isLocked = session?['is_locked'] == true;
      });
    } catch (_) {
      // No session yet for this date — attendance correction will create
      // one on submit, same as the existing team-leader marking flow.
    }
    await context.read<AttendanceProvider>().loadAllUsers(forDate: date);
    if (!mounted) return;
    setState(() {
      _pendingStatus
        ..clear()
        ..addAll(context.read<AttendanceProvider>().statusMap);
      _loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFor(_date));
  }

  Future<void> _toggleLock() async {
    if (_sessionId == null) return;
    setState(() => _togglingLock = true);
    try {
      await Supabase.instance.client
          .from('placement_sessions')
          .update({'is_locked': !_isLocked}).eq('id', _sessionId!);
      if (!mounted) return;
      setState(() => _isLocked = !_isLocked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update lock: $e')));
    } finally {
      if (mounted) setState(() => _togglingLock = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await context
          .read<AttendanceProvider>()
          .submitAttendance(null, _pendingStatus, forDate: _date, isRep: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Attendance corrected.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // A locked session rejects the write at the RLS layer (migration 47),
      // not just client-side — surface that plainly instead of a raw
      // Postgres error string.
      final message = e.toString().contains('row-level security') ||
              e.toString().contains('42501')
          ? 'This session is locked. Unlock it above before making corrections.'
          : '$e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    return _SheetScaffold(
      title: 'Correct session attendance',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(
                  'Session date: ${_date.toIso8601String().split('T').first}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.mutedText))),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now());
              if (picked != null) await _loadFor(picked);
            },
            child: const Text('Change date'),
          ),
        ]),
        const SizedBox(height: 8),
        if (attendance.isLoading || !_loaded)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()))
        else if (attendance.teamMembers.isEmpty)
          Text('No students found for this session.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedText))
        else ...[
          if (_sessionId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _isLocked
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _isLocked
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBBF7D0))),
                child: Row(children: [
                  Icon(_isLocked ? LucideIcons.lock : LucideIcons.lockOpen,
                      size: 16,
                      color: _isLocked
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          _isLocked
                              ? 'Attendance is finalized for this session.'
                              : 'This session is open for corrections.',
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600))),
                  _togglingLock
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _toggleLock,
                          child: Text(_isLocked ? 'Unlock' : 'Lock')),
                ]),
              ),
            ),
          ...attendance.teamMembers.map((student) {
            final current = _pendingStatus[student.uid] ?? 'PRESENT';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder)),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          student.name.isNotEmpty
                              ? student.name
                              : student.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600))),
                  DropdownButton<String>(
                    value: current,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'PRESENT', child: Text('Present')),
                      DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                      DropdownMenuItem(
                          value: 'EXCUSED', child: Text('Excused')),
                    ],
                    onChanged: _isLocked
                        ? null
                        : (value) => setState(() =>
                            _pendingStatus[student.uid] = value ?? current),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting || _isLocked ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isLocked ? 'Locked' : 'Save corrections'),
            ),
          ),
        ],
      ]),
    );
  }
}

class _AnnouncementSheet extends StatefulWidget {
  const _AnnouncementSheet();
  @override
  State<_AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<_AnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _priority = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a title and message first.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<AnnouncementProvider>().createAnnouncement(
            title: _titleCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
            isPriority: _priority,
            expiry: null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Announcement sent.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Send an announcement',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Message', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Mark as priority',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Priority announcements also trigger a push notification',
                style:
                    GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedText)),
            value: _priority,
            onChanged: (value) => setState(() => _priority = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Send to batch'),
            ),
          ),
        ]),
      );
}

class _SquadObjectiveSheet extends StatefulWidget {
  const _SquadObjectiveSheet();
  @override
  State<_SquadObjectiveSheet> createState() => _SquadObjectiveSheetState();
}

class _SquadObjectiveSheetState extends State<_SquadObjectiveSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _teams = const [];
  String? _selectedTeamId;
  final _objectiveCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _objectiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      // Scope to the PR's own batch — set_squad_objective (migration 41)
      // rejects any team outside the caller's batch, so listing every
      // batch's squads here would let a PR pick one that is guaranteed to
      // fail on save.
      final batchId = context.read<UserProvider>().currentUser?.batchId;
      var query = Supabase.instance.client
          .from('teams')
          .select('id, team_name, team_code, objective');
      if (batchId != null) {
        query = query.eq('batch_id', batchId);
      }
      final rows = await query.order('team_name');
      if (!mounted) return;
      setState(() {
        _teams = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedTeamId == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.rpc('set_squad_objective', params: {
        'p_team_id': _selectedTeamId,
        'p_objective': _objectiveCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squad objective updated.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Set a squad objective',
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
            : _teams.isEmpty
                ? Text('No squads exist for your batch yet.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.mutedText))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTeamId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Squad', border: OutlineInputBorder()),
                          items: _teams
                              .map((t) => DropdownMenuItem(
                                    value: t['id'] as String,
                                    child: Text(
                                        '${t['team_name']} (${t['team_code']})',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            final team =
                                _teams.firstWhere((t) => t['id'] == value);
                            setState(() {
                              _selectedTeamId = value;
                              _objectiveCtrl.text =
                                  team['objective']?.toString() ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _objectiveCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'This week\'s objective',
                              border: OutlineInputBorder(),
                              hintText: 'e.g. 15 verified quests as a squad'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _selectedTeamId == null || _saving
                                ? null
                                : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Save objective'),
                          ),
                        ),
                      ]),
      );
}

class _Notice extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _Notice({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(LucideIcons.wifiOff, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.inter(fontSize: 11))),
            TextButton(onPressed: onRetry, child: const Text('Retry'))
          ])));
}
