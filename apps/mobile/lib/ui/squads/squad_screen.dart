import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadMember {
  final String id;
  final String name;
  final String regNo;
  final bool isTeamLeader;
  final int currentStreak;
  final int verifiedQuestCount;
  const _SquadMember({
    required this.id,
    required this.name,
    required this.regNo,
    required this.isTeamLeader,
    required this.currentStreak,
    required this.verifiedQuestCount,
  });

  factory _SquadMember.fromMap(Map<String, dynamic> map) => _SquadMember(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Student',
        regNo: map['reg_no']?.toString() ?? '—',
        isTeamLeader: map['is_team_leader'] == true,
        currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
        verifiedQuestCount: (map['verified_quest_count'] as num?)?.toInt() ?? 0,
      );
}

class _FeedEntry {
  final String memberName;
  final String questTitle;
  final DateTime completedAt;
  const _FeedEntry({required this.memberName, required this.questTitle, required this.completedAt});

  factory _FeedEntry.fromMap(Map<String, dynamic> map) => _FeedEntry(
        memberName: map['member_name']?.toString() ?? 'A member',
        questTitle: map['quest_title']?.toString() ?? 'a quest',
        completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class _SquadScreenState extends State<SquadScreen> {
  bool _loading = true;
  String? _error;
  String? _teamName;
  String? _teamCode;
  String? _objective;
  List<_SquadMember> _members = const [];
  List<_FeedEntry> _feed = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // get_my_squad() is a SECURITY DEFINER RPC (not raw table reads) —
      // RLS on users/daily_five_streaks/code_submissions only ever granted
      // read access to the row's own owner or an admin role, never to a
      // squadmate, so this is the only path that actually returns teammates.
      final result =
          await Supabase.instance.client.rpc('get_my_squad') as Map?;
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _teamName = null;
          _members = const [];
          _loading = false;
        });
        return;
      }
      final members = (result['members'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => _SquadMember.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      final feed = (result['feed'] as List? ?? const [])
          .whereType<Map>()
          .map((f) => _FeedEntry.fromMap(Map<String, dynamic>.from(f)))
          .toList();
      setState(() {
        _teamName = result['team_name']?.toString();
        _teamCode = result['team_code']?.toString();
        _objective = result['objective']?.toString();
        _members = members;
        _feed = feed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Squad could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Your squad',
            style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Icon(LucideIcons.wifiOff,
                              size: 18, color: AppTheme.accentCoral),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.inter(fontSize: 11))),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ]),
                      ),
                    ),
                  if (_members.isEmpty && _error == null)
                    EmptyState(
                      icon: LucideIcons.usersRound,
                      title: 'No squad assigned yet',
                      message:
                          'Your Placement Rep can build balanced squads for your batch. Check back once yours is assigned.',
                    )
                  else ...[
                    Text(_teamName ?? 'Squad',
                        style: GoogleFonts.sora(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    if (_teamCode != null) ...[
                      const SizedBox(height: 4),
                      Text(_teamCode!,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.mutedText)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                        '${_members.length} members · peer competition is by completion, not raw readiness score.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.mutedText)),
                    if (_objective != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD4BF))),
                        child: Row(children: [
                          const Icon(LucideIcons.target, size: 18, color: AppTheme.accentCoral),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weekly squad objective',
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppTheme.accentCoral)),
                                const SizedBox(height: 3),
                                Text(_objective!,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ..._members.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            padding: const EdgeInsets.all(14),
                            radius: AppRadius.card,
                            child: Row(children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppTheme.accentCoral.withValues(alpha: .12),
                                child: Text(
                                    m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.sora(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accentCoral)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Flexible(
                                            child: Text(m.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w800))),
                                        if (m.isTeamLeader) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: AppTheme.primaryPurple
                                                    .withValues(alpha: .1),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text('Team Leader',
                                                style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme
                                                        .primaryPurple)),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(m.regNo,
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppTheme.mutedText)),
                                    ]),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(children: [
                                    const Icon(LucideIcons.flame,
                                        size: 13, color: Color(0xFFFF7043)),
                                    const SizedBox(width: 3),
                                    Text('${m.currentStreak}d',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text('${m.verifiedQuestCount} quests',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppTheme.mutedText)),
                                ],
                              ),
                            ]),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Text('Activity signals',
                        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    if (_feed.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.cardBorder, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(14)),
                        child: Text(
                            'Verified squad activity from the last 7 days will appear here.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedText)),
                      )
                    else
                      ..._feed.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PremiumCard(
                              padding: const EdgeInsets.all(12),
                              radius: AppRadius.card,
                              child: Row(children: [
                                const Icon(LucideIcons.checkCircle2, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: f.memberName,
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800)),
                                    TextSpan(
                                        text: ' verified "${f.questTitle}"',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedText)),
                                  ])),
                                ),
                                Text(_relativeTime(f.completedAt),
                                    style: GoogleFonts.inter(fontSize: 9, color: AppTheme.mutedText)),
                              ]),
                            ),
                          )),
                  ],
                ],
              ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
