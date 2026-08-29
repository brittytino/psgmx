import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  String? _error;
  double? _score;
  DateTime? _computedAt;
  Map<String, dynamic> _components = const {};
  List<Map<String, dynamic>> _dimensionRows = const [];
  int _currentStreak = 0;
  int _longestStreak = 0;
  int? _leetcodeSolved;
  DateTime? _leetcodeUpdatedAt;

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
      final futures = await Future.wait<dynamic>([
        client
            .from('current_readiness_scores')
            .select('score, components_json, computed_at')
            .eq('user_id', user.uid)
            .maybeSingle(),
        client
            .from('daily_five_streaks')
            .select('current_streak, longest_streak')
            .eq('user_id', user.uid)
            .maybeSingle(),
        client
            .from('readiness_dimension_scores')
            .select(
                'dimension, score, confidence, evidence_count, evidence_fresh_at')
            .eq('user_id', user.uid)
            .eq('algorithm_version', 'v2'),
        if (user.leetcodeUsername != null && user.leetcodeUsername!.isNotEmpty)
          client
              .from('leetcode_stats')
              .select('total_solved, last_updated')
              .eq('username', user.leetcodeUsername!)
              .maybeSingle()
        else
          Future<Map<String, dynamic>?>.value(null),
      ]);

      final readiness = futures[0] as Map<String, dynamic>?;
      final streak = futures[1] as Map<String, dynamic>?;
      final dimensionRows = (futures[2] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final leetcode = futures[3] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _score = _asDouble(readiness?['score']);
        _components = readiness?['components_json'] is Map
            ? Map<String, dynamic>.from(readiness!['components_json'] as Map)
            : const {};
        _dimensionRows = dimensionRows;
        _computedAt =
            DateTime.tryParse(readiness?['computed_at']?.toString() ?? '');
        _currentStreak = (streak?['current_streak'] as num?)?.toInt() ?? 0;
        _longestStreak = (streak?['longest_streak'] as num?)?.toInt() ?? 0;
        _leetcodeSolved = (leetcode?['total_solved'] as num?)?.toInt();
        _leetcodeUpdatedAt =
            DateTime.tryParse(leetcode?['last_updated']?.toString() ?? '');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Progress could not be refreshed. Your last verified data is still safe.';
      });
    }
  }

  double? _asDouble(dynamic value) =>
      value == null ? null : double.tryParse(value.toString());

  double? _componentValue(List<String> keys) {
    for (final key in keys) {
      final value = _asDouble(_components[key]);
      if (value != null) return value.clamp(0, 100);
    }
    return null;
  }

  String _freshness(DateTime? date) {
    if (date == null) return 'Not measured yet';
    final days = DateTime.now().difference(date.toLocal()).inDays;
    if (days <= 0) return 'Verified today';
    if (days == 1) return 'Verified yesterday';
    return 'Verified $days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser!;
    Map<String, dynamic>? evidence(String key) {
      for (final row in _dimensionRows) {
        if (row['dimension'] == key) return row;
      }
      return null;
    }

    double? measuredValue(String key, List<String> fallbackKeys) {
      final row = evidence(key);
      final count = (row?['evidence_count'] as num?)?.toInt() ?? 0;
      if (count > 0) return _asDouble(row?['score'])?.clamp(0, 100);
      return _dimensionRows.isEmpty ? _componentValue(fallbackKeys) : null;
    }

    final dimensions = [
      _Dimension(
          'Aptitude & reasoning',
          LucideIcons.brain,
          measuredValue('aptitude_reasoning',
              ['daily_five_accuracy_pct', 'daily_five_score']),
          evidence('aptitude_reasoning')),
      _Dimension(
          'Coding & problem solving',
          LucideIcons.code2,
          measuredValue('coding_problem_solving',
              ['leetcode_momentum_percentile', 'leetcode_score']),
          evidence('coding_problem_solving')),
      _Dimension(
          'Core computer science',
          LucideIcons.database,
          measuredValue('core_computer_science', ['core_cs_score']),
          evidence('core_computer_science')),
      _Dimension(
          'Communication',
          LucideIcons.messagesSquare,
          measuredValue('communication_interview', ['communication_score']),
          evidence('communication_interview')),
      _Dimension(
          'Assessment performance',
          LucideIcons.clipboardCheck,
          measuredValue('assessment_performance',
              ['mock_exam_score', 'assessment_score']),
          evidence('assessment_performance')),
      _Dimension(
          'Portfolio & project proof',
          LucideIcons.folderKanban,
          measuredValue('portfolio_project', ['portfolio_score', 'fyp_score']),
          evidence('portfolio_project')),
    ];
    final measured = dimensions.where((item) => item.value != null).toList();
    final focus = measured.isEmpty
        ? null
        : measured.reduce((a, b) => a.value! <= b.value! ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Text('Progress',
                  style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF17132D))),
              const SizedBox(height: 5),
              Text('Evidence, freshness and your next useful move.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 18),
              if (_loading)
                const LinearProgressIndicator(minHeight: 3)
              else if (_error != null)
                _MessageCard(
                    icon: LucideIcons.wifiOff,
                    message: _error!,
                    action: 'Retry',
                    onTap: _load),
              _ScoreHero(
                score: _score,
                stage: user.isActiveSenior ? 'Proof stage' : 'Foundation stage',
                freshness: _freshness(_computedAt),
              ),
              const SizedBox(height: 14),
              _NextMoveCard(
                title: focus == null
                    ? 'Build your first evidence'
                    : 'Refresh ${focus.title.toLowerCase()}',
                message: focus == null
                    ? 'Complete Daily Five or a practice quest to make this plan personal.'
                    : 'This is currently your least-supported measured dimension. A focused sprint is the best next move.',
              ),
              const SizedBox(height: 24),
              Text('Readiness evidence',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...dimensions.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DimensionCard(item: item),
                  )),
              const SizedBox(height: 14),
              Text('Consistency signals',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _StatCard(
                        label: 'Current rhythm',
                        value: '$_currentStreak',
                        suffix: 'days',
                        icon: LucideIcons.flame)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        label: 'Personal best',
                        value: '$_longestStreak',
                        suffix: 'days',
                        icon: LucideIcons.trophy)),
              ]),
              const SizedBox(height: 10),
              _MessageCard(
                icon: LucideIcons.code2,
                message: _leetcodeSolved == null
                    ? 'Connect LeetCode in You to add verified coding evidence.'
                    : '$_leetcodeSolved problems verified · ${_freshness(_leetcodeUpdatedAt)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dimension {
  final String title;
  final IconData icon;
  final double? value;
  final Map<String, dynamic>? evidence;
  const _Dimension(this.title, this.icon, this.value, this.evidence);
}

class _ScoreHero extends StatelessWidget {
  final double? score;
  final String stage;
  final String freshness;
  const _ScoreHero(
      {required this.score, required this.stage, required this.freshness});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF20163D), Color(0xFF5B2A86)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        Container(
          width: 74,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .25))),
          child: Text(score == null ? '—' : '${score!.round()}',
              style: GoogleFonts.sora(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stage,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFFFB899),
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(
                score == null
                    ? 'Evidence is starting'
                    : 'Readiness ${score!.round()}/100',
                style: GoogleFonts.sora(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(freshness,
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white.withValues(alpha: .72))),
          ]),
        )
      ]),
    );
  }
}

class _NextMoveCard extends StatelessWidget {
  final String title;
  final String message;
  const _NextMoveCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFFFD4BF))),
        child: Row(children: [
          const Icon(LucideIcons.sparkles, color: AppTheme.accentCoral),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(message,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.4,
                        color: const Color(0xFF7C5B4A))),
              ]))
        ]),
      );
}

class _DimensionCard extends StatelessWidget {
  final _Dimension item;
  const _DimensionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final value = item.value;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EAF0))),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, size: 19, color: AppTheme.accentCoral)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(item.title,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800))),
            Text(value == null ? 'Not measured' : '${value.round()}%',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: value == null
                        ? const Color(0xFF94A3B8)
                        : AppTheme.accentCoral)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value == null ? 0 : value / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: const Color(0xFFF1F3F7),
            color:
                value == null ? const Color(0xFFD5D9E2) : AppTheme.accentCoral,
          ),
          const SizedBox(height: 6),
          Text(
              value == null
                  ? 'No verified evidence yet'
                  : '${item.evidence?['confidence'] ?? 'low'} confidence · ${item.evidence?['evidence_count'] ?? 1} source${item.evidence?['evidence_count'] == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                  fontSize: 9, color: const Color(0xFF64748B))),
        ]))
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.suffix,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 19, color: AppTheme.accentCoral),
          const SizedBox(height: 12),
          Text('$value $suffix',
              style:
                  GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF64748B))),
        ]),
      );
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onTap;
  const _MessageCard(
      {required this.icon, required this.message, this.action, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF0))),
        child: Row(children: [
          Icon(icon, size: 19, color: AppTheme.accentCoral),
          const SizedBox(width: 11),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 11, height: 1.4, fontWeight: FontWeight.w600))),
          if (action != null)
            TextButton(onPressed: onTap, child: Text(action!)),
        ]),
      );
}
