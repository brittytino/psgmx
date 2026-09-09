import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class JourneyArchiveScreen extends StatefulWidget {
  const JourneyArchiveScreen({super.key});

  @override
  State<JourneyArchiveScreen> createState() => _JourneyArchiveScreenState();
}

class _JourneyArchiveScreenState extends State<JourneyArchiveScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _journeys = const [];
  int _lifetimeXp = 0;
  int _evidenceEvents = 0;

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
            .from('weekly_journeys')
            .select(
                'id, week_start, stage, status, completed_at, journey_missions(id, title, mission_type, skill_dimension, estimated_minutes, status, completed_at)')
            .eq('user_id', user.uid)
            .order('week_start', ascending: false)
            .limit(26),
        client
            .from('user_experience')
            .select('lifetime_xp')
            .eq('user_id', user.uid)
            .maybeSingle(),
        client
            .from('experience_events')
            .select('id')
            .eq('user_id', user.uid)
            .limit(1000),
      ]);
      if (!mounted) return;
      setState(() {
        _journeys = (rows[0] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _lifetimeXp = (rows[1] as Map?)?['lifetime_xp'] as int? ?? 0;
        _evidenceEvents = (rows[2] as List).length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your journey archive could not be refreshed.';
      });
    }
  }

  String _weekLabel(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return 'Journey week';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return 'Week of ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _stageLabel(dynamic value) => switch (value?.toString()) {
        'proof' => 'Proof stage',
        'alumni_contribution' => 'Alumni contribution',
        _ => 'Foundation stage',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: Text('Journey archive',
              style:
                  GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
          backgroundColor: Colors.white,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text('Your progress is a record of evidence, not a public rank.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.mutedText)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Lifetime XP',
                    value: '$_lifetimeXp',
                    icon: LucideIcons.sparkles,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Evidence events',
                    value: '$_evidenceEvents',
                    icon: LucideIcons.badgeCheck,
                  ),
                ),
              ]),
              if (_loading) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ArchiveNotice(message: _error!, onRetry: _load),
              ],
              const SizedBox(height: 24),
              Text('Weekly journeys',
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (!_loading && _journeys.isEmpty && _error == null)
                const EmptyState(
                  icon: LucideIcons.archive,
                  title: 'Your first journey starts here',
                  message:
                      'Completed and active weekly journeys will remain available in this private archive.',
                )
              else
                ..._journeys.map((journey) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _JourneyCard(
                        journey: journey,
                        title: _weekLabel(journey['week_start']),
                        stage: _stageLabel(journey['stage']),
                      ),
                    )),
            ],
          ),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF20163D), Color(0xFF5B2A86)]),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: const Color(0xFFFFB899)),
          const SizedBox(height: 13),
          Text(value,
              style: GoogleFonts.sora(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 9, color: Colors.white70)),
        ]),
      );
}

class _JourneyCard extends StatelessWidget {
  final Map<String, dynamic> journey;
  final String title;
  final String stage;
  const _JourneyCard(
      {required this.journey, required this.title, required this.stage});

  @override
  Widget build(BuildContext context) {
    final missions = (journey['journey_missions'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final completed =
        missions.where((mission) => mission['status'] == 'completed').length;
    final isComplete = journey['status'] == 'completed';
    return PremiumCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(stage,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.mutedText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (isComplete ? const Color(0xFF16A34A) : AppTheme.accentCoral)
                      .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(isComplete ? 'Completed' : 'Active',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isComplete
                        ? const Color(0xFF16A34A)
                        : AppTheme.accentCoral)),
          ),
        ]),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: missions.isEmpty ? 0 : completed / missions.length,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(height: 7),
        Text('$completed of ${missions.length} missions completed',
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.mutedText)),
        if (missions.isNotEmpty) ...[
          const SizedBox(height: 13),
          ...missions.take(5).map((mission) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  Icon(
                    mission['status'] == 'completed'
                        ? LucideIcons.circleCheck
                        : LucideIcons.circle,
                    size: 15,
                    color: mission['status'] == 'completed'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(mission['title']?.toString() ?? 'Mission',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11)),
                  ),
                ]),
              )),
        ],
      ]),
    );
  }
}

class _ArchiveNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ArchiveNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
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
