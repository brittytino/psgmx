import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class ReadinessDimensionScreen extends StatefulWidget {
  final String dimension;
  const ReadinessDimensionScreen({super.key, required this.dimension});

  @override
  State<ReadinessDimensionScreen> createState() =>
      _ReadinessDimensionScreenState();
}

class _ReadinessDimensionScreenState extends State<ReadinessDimensionScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _row;

  _DimensionMeta get _meta =>
      _dimensionMeta[widget.dimension] ?? _dimensionMeta.values.first;

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
      final row = await Supabase.instance.client
          .from('readiness_dimension_scores')
          .select(
              'dimension, score, confidence, evidence_count, evidence_fresh_at, evidence, computed_at')
          .eq('user_id', user.uid)
          .eq('dimension', widget.dimension)
          .eq('algorithm_version', 'v2')
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _row = row;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'This evidence could not be refreshed right now.';
      });
    }
  }

  String _freshness(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'No verified evidence yet';
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Verified today';
    if (days == 1) return 'Verified yesterday';
    return 'Verified $days days ago';
  }

  Future<void> _takeAction() async {
    final route = _meta.route;
    if (route != null) {
      context.push(route);
      return;
    }
    final path = _meta.webPath;
    if (path == null) return;
    final opened = await launchUrl(
      Uri.parse('${SupabaseConfig.appApiUrl}$path'),
      mode: LaunchMode.platformDefault,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the web workspace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = double.tryParse(_row?['score']?.toString() ?? '');
    final evidence = (_row?['evidence'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    final count = (_row?['evidence_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(_meta.shortTitle,
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) _Notice(message: _error!, onRetry: _load),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_meta.color, const Color(0xFF20163D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_meta.icon, color: Colors.white, size: 23),
                    ),
                    const Spacer(),
                    Text(score == null ? '—' : '${score.round()}%',
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 18),
                  Text(_meta.title,
                      style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_meta.description,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 11, height: 1.45)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _HeroChip(text: _freshness(_row?['evidence_fresh_at'])),
                    _HeroChip(
                        text: '${_row?['confidence'] ?? 'low'} confidence'),
                    _HeroChip(text: '$count source${count == 1 ? '' : 's'}'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('What this score means',
                style: GoogleFonts.sora(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            PremiumCard(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(16),
              child: Text(_meta.explanation,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.5,
                      color: const Color(0xFF475569))),
            ),
            const SizedBox(height: 22),
            Text('Verified evidence',
                style: GoogleFonts.sora(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (!_loading && evidence.isEmpty)
              EmptyState(
                icon: _meta.icon,
                title: 'No evidence here yet',
                message:
                    'Your score will appear after a verified ${_meta.evidenceHint}.',
              )
            else
              ...evidence.map((key) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PremiumCard(
                      radius: AppRadius.card,
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        const Icon(LucideIcons.badgeCheck,
                            size: 19, color: Color(0xFF16A34A)),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(_evidenceLabel(key),
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  )),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4ED),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFFFD4BF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best next move',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_meta.nextMove,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.45,
                          color: const Color(0xFF7C5B4A))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _takeAction,
                      icon: Icon(_meta.actionIcon, size: 17),
                      label: Text(_meta.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _evidenceLabel(String key) {
    const labels = {
      'daily_five_accuracy_pct': 'Daily Five accuracy',
      'daily_five_adherence_pct': 'Daily Five consistency',
      'leetcode_momentum_percentile': 'LeetCode momentum',
      'quest_completion_rate_pct': 'Verified quest completion',
      'task_completion_rate_pct': 'Verified task completion',
      'communication_score': 'Communication practice evaluation',
      'mock_exam_score': 'Mock assessment performance',
      'assessment_score': 'Assessment performance',
      'portfolio_score': 'Portfolio evidence',
      'fyp_score': 'Faculty-confirmed FYP progress',
    };
    return labels[key] ??
        key
            .replaceAll('_pct', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}

class _Notice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Notice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(LucideIcons.wifiOff,
              size: 18, color: AppTheme.accentCoral),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 11))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _DimensionMeta {
  final String title;
  final String shortTitle;
  final String description;
  final String explanation;
  final String evidenceHint;
  final String nextMove;
  final String actionLabel;
  final IconData icon;
  final IconData actionIcon;
  final Color color;
  final String? route;
  final String? webPath;

  const _DimensionMeta({
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.explanation,
    required this.evidenceHint,
    required this.nextMove,
    required this.actionLabel,
    required this.icon,
    required this.actionIcon,
    required this.color,
    this.route,
    this.webPath,
  });
}

const _dimensionMeta = <String, _DimensionMeta>{
  'aptitude_reasoning': _DimensionMeta(
    title: 'Aptitude & reasoning',
    shortTitle: 'Aptitude',
    description: 'Speed, accuracy and repeatable reasoning under pressure.',
    explanation:
        'This dimension grows through verified Daily Five answers, focused sprints and released mock assessments. Recent evidence carries more confidence than an older result.',
    evidenceHint: 'quiz or aptitude sprint',
    nextMove:
        'Take a focused sprint. Missed concepts will return automatically in your revisit queue.',
    actionLabel: 'Start an aptitude sprint',
    icon: LucideIcons.brain,
    actionIcon: LucideIcons.timerReset,
    color: Color(0xFF7C3AED),
    route: '/train/sprint',
  ),
  'coding_problem_solving': _DimensionMeta(
    title: 'Coding & problem solving',
    shortTitle: 'Coding',
    description: 'Verified solutions, consistency and external coding proof.',
    explanation:
        'CodeBox verification and synced LeetCode activity feed this score. Opening a task never counts as evidence; only a verified result does.',
    evidenceHint: 'CodeBox result or LeetCode sync',
    nextMove:
        'Open your current coding quest, or connect LeetCode if your profile is not linked yet.',
    actionLabel: 'Open coding work',
    icon: LucideIcons.code2,
    actionIcon: LucideIcons.monitorUp,
    color: Color(0xFF2563EB),
    route: '/train/deep-work',
  ),
  'core_computer_science': _DimensionMeta(
    title: 'Core computer science',
    shortTitle: 'Core CS',
    description: 'DBMS, operating systems, networks and foundational depth.',
    explanation:
        'Verified answers and targeted concept practice show both coverage and freshness across Core CS topics.',
    evidenceHint: 'Core CS quiz or sprint',
    nextMove:
        'Choose a Core CS topic in Adaptive Sprint and refresh the oldest concept first.',
    actionLabel: 'Start a Core CS sprint',
    icon: LucideIcons.database,
    actionIcon: LucideIcons.timerReset,
    color: Color(0xFF0F766E),
    route: '/train/sprint',
  ),
  'communication_interview': _DimensionMeta(
    title: 'Communication & interview',
    shortTitle: 'Communication',
    description: 'Clear, structured answers with relevant supporting detail.',
    explanation:
        'Private audio practice builds evidence from clarity, structure and relevance. Faculty-reviewed attempts carry higher confidence.',
    evidenceHint: 'audio practice evaluation',
    nextMove:
        'Record one two-minute answer and apply the single improvement suggested for your next attempt.',
    actionLabel: 'Practise an answer',
    icon: LucideIcons.messagesSquare,
    actionIcon: LucideIcons.mic,
    color: Color(0xFFEA580C),
    route: '/train/communication',
  ),
  'assessment_performance': _DimensionMeta(
    title: 'Assessment performance',
    shortTitle: 'Assessments',
    description: 'Released mock results and corrected misconception patterns.',
    explanation:
        'This score reflects completed assessments, not attendance or merely starting an attempt. Results appear after faculty release.',
    evidenceHint: 'released mock assessment',
    nextMove:
        'Review your open assessments and reserve an uninterrupted full-screen session.',
    actionLabel: 'View mock assessments',
    icon: LucideIcons.clipboardCheck,
    actionIcon: LucideIcons.monitorUp,
    color: Color(0xFFB45309),
    route: '/train/deep-work',
  ),
  'portfolio_project': _DimensionMeta(
    title: 'Portfolio & project proof',
    shortTitle: 'Portfolio',
    description:
        'Faculty-confirmed FYP milestones and demonstrable project work.',
    explanation:
        'Project claims become evidence only when a faculty guide confirms the milestone. Repository links alone do not raise readiness.',
    evidenceHint: 'faculty-confirmed project milestone',
    nextMove:
        'Update your FYP milestone, then request guide review from the full project workspace.',
    actionLabel: 'Open FYP workspace',
    icon: LucideIcons.folderKanban,
    actionIcon: LucideIcons.externalLink,
    color: Color(0xFFBE185D),
    webPath: '/student/fyp',
  ),
};
