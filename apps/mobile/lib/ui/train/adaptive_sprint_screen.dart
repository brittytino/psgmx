import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/premium_card.dart';

/// PRD Ch. 4.2's Adaptive Skill Sprint: pick a domain (or "recommended for
/// me") and a duration, answer questions that escalate from recall to
/// application, and end with a mastery-movement report. Wrong concepts are
/// added to a revisit queue server-side (supabase/migrations/43) so they
/// resurface in a later sprint automatically.
class AdaptiveSprintScreen extends StatefulWidget {
  const AdaptiveSprintScreen({super.key});

  @override
  State<AdaptiveSprintScreen> createState() => _AdaptiveSprintScreenState();
}

enum _SprintStage { picker, running, loading, report, error }

class _AdaptiveSprintScreenState extends State<AdaptiveSprintScreen> {
  _SprintStage _stage = _SprintStage.picker;
  String? _domain;
  int _duration = 10;
  List<String> _domains = const [];

  String? _attemptId;
  List<Map<String, dynamic>> _questions = const [];
  int _currentIndex = 0;
  final Map<String, int> _answers = {};
  Timer? _timer;
  int _secondsLeft = 0;
  Map<String, dynamic>? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDomains() async {
    try {
      final rows = await Supabase.instance.client
          .from('question_bank')
          .select('topic')
          .eq('is_active', true)
          .limit(200);
      final topics = <String>{};
      for (final row in rows as List) {
        final topic = row['topic']?.toString();
        if (topic != null && topic.isNotEmpty) topics.add(topic);
      }
      if (!mounted) return;
      setState(() => _domains = topics.toList()..sort());
    } catch (_) {
      // Domain picker just shows "Recommended for me" if this fails.
    }
  }

  Future<void> _startSprint() async {
    setState(() {
      _stage = _SprintStage.loading;
      _error = null;
    });
    try {
      final userId = context.read<UserProvider>().currentUser!.uid;
      final rows = await Supabase.instance.client.rpc('start_adaptive_sprint', params: {
        'p_user_id': userId,
        'p_domain': _domain,
        'p_duration_minutes': _duration,
      });
      // The RPC call itself returns the attempt's questions, but we still
      // need the attempt id it created — read it back as the newest attempt
      // for this user (started within the last few seconds).
      final attemptRow = await Supabase.instance.client
          .from('sprint_attempts')
          .select('id')
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(1)
          .single();
      if (!mounted) return;
      setState(() {
        _questions = List<Map<String, dynamic>>.from(rows as List);
        _attemptId = attemptRow['id'] as String;
        _currentIndex = 0;
        _answers.clear();
        _secondsLeft = _duration * 60;
        _stage = _SprintStage.running;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_secondsLeft <= 1) {
          timer.cancel();
          _submit();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _SprintStage.error;
        _error = 'Could not start a sprint right now. Try again shortly.';
      });
    }
  }

  Future<void> _submit() async {
    _timer?.cancel();
    setState(() => _stage = _SprintStage.loading);
    try {
      final userId = context.read<UserProvider>().currentUser!.uid;
      final result = await Supabase.instance.client.rpc('submit_adaptive_sprint', params: {
        'p_user_id': userId,
        'p_attempt_id': _attemptId,
        'p_answers': _answers,
      });
      if (!mounted) return;
      setState(() {
        _report = Map<String, dynamic>.from(result as Map);
        _stage = _SprintStage.report;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _SprintStage.error;
        _error = 'Could not submit your sprint. Your answers were not saved — try again.';
      });
    }
  }

  String _formatTime(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text('Adaptive Skill Sprint',
            style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: switch (_stage) {
        _SprintStage.picker => _buildPicker(),
        _SprintStage.loading => const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
        _SprintStage.running => _buildRunning(),
        _SprintStage.report => _buildReport(),
        _SprintStage.error => _buildError(),
      },
    );
  }

  Widget _buildPicker() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pick a domain', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              label: const Text('Recommended for me'),
              selected: _domain == null,
              onSelected: (_) => setState(() => _domain = null),
            ),
            ..._domains.map((d) => ChoiceChip(
                  label: Text(d),
                  selected: _domain == d,
                  onSelected: (_) => setState(() => _domain = d),
                )),
          ]),
          const SizedBox(height: 24),
          Text('Pick a duration', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [5, 10, 20].map((d) {
            final selected = _duration == d;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => setState(() => _duration = d),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? AppTheme.primaryPurple.withValues(alpha: .1) : null,
                    side: BorderSide(color: selected ? AppTheme.primaryPurple : AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('$d min',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: selected ? AppTheme.primaryPurple : null)),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _startSprint,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryPurple, padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Text('Launch Sprint'),
            ),
          ),
        ],
      );

  Widget _buildRunning() {
    final question = _questions[_currentIndex];
    final options = (question['options'] as List? ?? const []);
    final selected = _answers[question['id'].toString()];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(
            child: Text('Question ${_currentIndex + 1} of ${_questions.length} · ${question['topic']}',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedText)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryPurple.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
            child: Text(_formatTime(_secondsLeft),
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryPurple)),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text(question['question_text']?.toString() ?? '',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...List.generate(options.length, (idx) {
              final isSelected = selected == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _answers[question['id'].toString()] = idx),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryPurple.withValues(alpha: .06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppTheme.primaryPurple : AppTheme.cardBorder, width: isSelected ? 2 : 1),
                    ),
                    child: Text(options[idx].toString(), style: GoogleFonts.inter(fontSize: 13)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Row(children: [
          if (_currentIndex > 0)
            TextButton(onPressed: () => setState(() => _currentIndex--), child: const Text('Back')),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: () {
              if (_currentIndex < _questions.length - 1) {
                setState(() => _currentIndex++);
              } else {
                _submit();
              }
            },
            child: Text(_currentIndex < _questions.length - 1 ? 'Next' : 'Finish Sprint'),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildReport() {
    final report = _report!;
    final byDifficulty = Map<String, dynamic>.from(report['by_difficulty'] as Map? ?? const {});
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF17132D), borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sprint complete', style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('${report['correct_count']} / ${report['total_questions']} correct',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            if ((report['resolved_revisit_count'] as int? ?? 0) > 0) ...[
              const SizedBox(height: 6),
              Text('${report['resolved_revisit_count']} previously-missed concept(s) resolved 🎉',
                  style: GoogleFonts.inter(color: const Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Text('Mastery movement', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...['easy', 'medium', 'hard'].map((tier) {
          final tierData = Map<String, dynamic>.from(byDifficulty[tier] as Map? ?? const {});
          final correct = (tierData['correct'] as num?)?.toInt() ?? 0;
          final total = (tierData['total'] as num?)?.toInt() ?? 0;
          if (total == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PremiumCard(
              padding: const EdgeInsets.all(14),
              radius: AppRadius.card,
              child: Row(children: [
                Expanded(child: Text(tier[0].toUpperCase() + tier.substring(1), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12))),
                Text('$correct / $total', style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 13)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.pop(),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryPurple, padding: const EdgeInsets.symmetric(vertical: 18)),
            child: const Text('Back to Train'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.wifiOff, size: 32, color: AppTheme.accentCoral),
            const SizedBox(height: 12),
            Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => setState(() => _stage = _SprintStage.picker), child: const Text('Try again')),
          ]),
        ),
      );
}
