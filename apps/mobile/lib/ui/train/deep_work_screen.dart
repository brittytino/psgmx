import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

/// Phone-friendly gateway to the two deep-work experiences that intentionally
/// stay on psgmx.tech: CodeBox and timed mock assessments. The mobile app owns
/// discovery, state and resumption; the browser owns the full editor/exam UI.
class DeepWorkScreen extends StatefulWidget {
  const DeepWorkScreen({super.key});

  @override
  State<DeepWorkScreen> createState() => _DeepWorkScreenState();
}

class _DeepWorkScreenState extends State<DeepWorkScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quests = const [];
  List<Map<String, dynamic>> _exams = const [];
  Map<String, Map<String, dynamic>> _questAttempts = const {};
  Map<String, Map<String, dynamic>> _examAttempts = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final rows = await Future.wait<dynamic>([
        client
            .from('quests')
            .select(
                'id, title, type, difficulty, due_at, available_from, xp_reward')
            .eq('status', 'published')
            .order('due_at', ascending: true, nullsFirst: false)
            .limit(30),
        client
            .from('code_submissions')
            .select(
                'quest_id, verdict, is_verified_complete, attempt_number, submitted_at')
            .eq('student_id', user.uid)
            .order('submitted_at', ascending: false)
            .limit(100),
        client
            .from('mock_exams')
            .select('id, title, description, duration_minutes, exam_date')
            .order('exam_date', ascending: true, nullsFirst: false)
            .limit(30),
        client
            .from('mock_exam_results')
            .select('exam_id, status, score, out_of, started_at, submitted_at')
            .eq('student_id', user.uid)
            .order('created_at', ascending: false)
            .limit(100),
      ]);

      final attempts = <String, Map<String, dynamic>>{};
      for (final raw in rows[1] as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['quest_id']?.toString();
        if (id != null) attempts.putIfAbsent(id, () => row);
      }
      final examAttempts = <String, Map<String, dynamic>>{};
      for (final raw in rows[3] as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['exam_id']?.toString();
        if (id != null) examAttempts.putIfAbsent(id, () => row);
      }

      final now = DateTime.now();
      final quests = (rows[0] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) {
        final available =
            DateTime.tryParse(item['available_from']?.toString() ?? '');
        return available == null || !available.isAfter(now);
      }).toList();

      if (!mounted) return;
      setState(() {
        _quests = quests;
        _exams = (rows[2] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _questAttempts = attempts;
        _examAttempts = examAttempts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Assignments could not be refreshed. Pull down or try again shortly.';
      });
    }
  }

  Future<void> _openWebPath(String path) async {
    final uri = Uri.parse('${SupabaseConfig.appApiUrl}$path');
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the secure web workspace.')));
    }
  }

  String _dateLabel(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'No deadline';
    final delta = date.difference(DateTime.now());
    if (delta.isNegative) return 'Deadline passed';
    if (delta.inHours < 24) return 'Due in ${delta.inHours.clamp(1, 23)}h';
    if (delta.inDays < 7) return 'Due in ${delta.inDays}d';
    return 'Due ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final activeQuests = _quests
        .where((q) => _questAttempts[q['id']]?['is_verified_complete'] != true)
        .toList();
    final upcomingExams = _exams.where((exam) {
      final status = _examAttempts[exam['id']]?['status'];
      return status != 'submitted' && status != 'auto_submitted';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Deep work',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF20163D), Color(0xFF5B2A86)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.monitorUp,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.isActiveSenior == true
                            ? 'Proof-stage workspace'
                            : 'Focused practice workspace',
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open full-screen CodeBox and timed assessments securely on psgmx.tech.',
                        style: GoogleFonts.inter(
                            color: Colors.white70, height: 1.4, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            if (_loading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _Notice(message: _error!, onRetry: _load),
            ],
            const SizedBox(height: 22),
            _SectionHeader(title: 'CodeBox quests', count: activeQuests.length),
            const SizedBox(height: 10),
            if (!_loading && activeQuests.isEmpty)
              const EmptyState(
                icon: LucideIcons.code2,
                title: 'No open coding quests',
                message:
                    'Published quests for your batch will appear here automatically.',
              )
            else
              ...activeQuests.map((quest) {
                final attempt = _questAttempts[quest['id']];
                final status = attempt == null
                    ? 'Not started'
                    : attempt['verdict'] == 'pending'
                        ? 'Evaluation pending'
                        : 'Continue improving';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeepWorkCard(
                    icon: LucideIcons.code2,
                    title: quest['title']?.toString() ?? 'CodeBox quest',
                    metadata:
                        '${quest['type'] ?? 'coding'} · level ${quest['difficulty'] ?? 3} · ${_dateLabel(quest['due_at'])}',
                    status: status,
                    action: attempt == null ? 'Open CodeBox' : 'Resume CodeBox',
                    onTap: () =>
                        _openWebPath('/student/codebox/${quest['id']}'),
                  ),
                );
              }),
            const SizedBox(height: 18),
            _SectionHeader(
                title: 'Mock assessments', count: upcomingExams.length),
            const SizedBox(height: 10),
            if (!_loading && upcomingExams.isEmpty)
              const EmptyState(
                icon: LucideIcons.clipboardCheck,
                title: 'No assessment needs action',
                message:
                    'Upcoming timed assessments for your batch will appear here.',
              )
            else
              ...upcomingExams.map((exam) {
                final attempt = _examAttempts[exam['id']];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeepWorkCard(
                    icon: LucideIcons.clipboardCheck,
                    title: exam['title']?.toString() ?? 'Mock assessment',
                    metadata:
                        '${exam['duration_minutes'] ?? 60} min · ${_dateLabel(exam['exam_date'])}',
                    status: attempt?['status'] == 'in_progress'
                        ? 'Attempt in progress'
                        : 'Timed assessment',
                    action: attempt?['status'] == 'in_progress'
                        ? 'Resume assessment'
                        : 'Open assessment',
                    onTap: () => _openWebPath('/student/exam/${exam['id']}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              style:
                  GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentCoral.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accentCoral)),
        ),
      ]);
}

class _DeepWorkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String metadata;
  final String status;
  final String action;
  final VoidCallback onTap;

  const _DeepWorkCard({
    required this.icon,
    required this.title,
    required this.metadata,
    required this.status,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PremiumCard(
        radius: AppRadius.card,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppTheme.accentCoral),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(metadata,
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppTheme.mutedText)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(
                child: Text(status,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B))),
              ),
              Text(action,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentCoral)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.externalLink,
                  size: 14, color: AppTheme.accentCoral),
            ]),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Notice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD4BF)),
        ),
        child: Row(children: [
          const Icon(LucideIcons.wifiOff,
              size: 18, color: AppTheme.accentCoral),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 11, height: 1.35))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
