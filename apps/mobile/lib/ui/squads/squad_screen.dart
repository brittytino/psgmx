import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/placement_teams_repository.dart';
import '../../providers/user_provider.dart';
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
  const _FeedEntry(
      {required this.memberName,
      required this.questTitle,
      required this.completedAt});

  factory _FeedEntry.fromMap(Map<String, dynamic> map) => _FeedEntry(
        memberName: map['member_name']?.toString() ?? 'A member',
        questTitle: map['quest_title']?.toString() ?? 'a quest',
        completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class _SquadScreenState extends State<SquadScreen> {
  int _selectedTab = 0; // 0 = My Squad, 1 = All 2026 Teams
  bool _loading = true;
  String? _error;
  String? _teamName;
  String? _teamCode;
  String? _objective;
  List<_SquadMember> _members = const [];
  List<_FeedEntry> _feed = const [];

  // All Teams from Database
  List<PlacementTeam> _allTeams = const [];
  bool _allTeamsLoading = false;

  // Search in All Teams
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadAllTeams();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllTeams({bool force = false}) async {
    if (_allTeams.isNotEmpty && !force) return;
    setState(() => _allTeamsLoading = true);
    try {
      final teams = await PlacementTeamsRepository().getTeams(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _allTeams = teams;
        _allTeamsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _allTeamsLoading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc('get_my_squad') as Map?;
      if (!mounted) return;

      if (result != null) {
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
      } else {
        await _applyDynamicFallback();
      }
    } catch (_) {
      if (!mounted) return;
      await _applyDynamicFallback();
    }
  }

  Future<void> _applyDynamicFallback() async {
    final user = context.read<UserProvider>().currentUser;
    if (user != null && user.regNo.isNotEmpty) {
      final matchedTeam = await PlacementTeamsRepository().findTeamForRollNo(user.regNo);
      if (matchedTeam != null && mounted) {
        setState(() {
          _teamName = matchedTeam.teamName;
          _teamCode = matchedTeam.teamCode;
          _objective = matchedTeam.objective ??
              'Complete combined CodeBox quests and maintain active Daily Five streaks.';
          _members = matchedTeam.members
              .map((m) => _SquadMember(
                    id: m.id.isNotEmpty ? m.id : m.rollNo,
                    name: m.name,
                    regNo: m.rollNo,
                    isTeamLeader: m.isLeader,
                    currentStreak: 0,
                    verifiedQuestCount: 0,
                  ))
              .toList();
          _feed = const [];
          _loading = false;
          _error = null;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _teamName = null;
        _members = const [];
        _loading = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Placement 2026 Squads',
            style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.userCheck,
                              size: 14,
                              color: _selectedTab == 0
                                  ? AppTheme.accentCoral
                                  : AppTheme.mutedText),
                          const SizedBox(width: 6),
                          Text('My Squad',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedTab == 0
                                      ? AppTheme.accentCoral
                                      : AppTheme.mutedText)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.usersRound,
                              size: 14,
                              color: _selectedTab == 1
                                  ? AppTheme.accentCoral
                                  : AppTheme.mutedText),
                          const SizedBox(width: 6),
                          Text('All 21 Teams',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedTab == 1
                                      ? AppTheme.accentCoral
                                      : AppTheme.mutedText)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildMySquadTab() : _buildAllTeamsTab(),
    );
  }

  Widget _buildMySquadTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCoral))
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
                        TextButton(
                            onPressed: _load, child: const Text('Retry')),
                      ]),
                    ),
                  ),
                if (_members.isEmpty && _error == null)
                  Column(
                    children: [
                      const EmptyState(
                        icon: LucideIcons.usersRound,
                        title: 'No squad assigned yet',
                        message:
                            'You can browse all 21 Placement 2026 teams in the tab above to find your squad.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() => _selectedTab = 1),
                        icon: const Icon(LucideIcons.usersRound, size: 16),
                        label: const Text('Browse All 2026 Teams'),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_teamName ?? 'Squad',
                                style: GoogleFonts.sora(
                                    fontSize: 22, fontWeight: FontWeight.w900)),
                            if (_teamCode != null) ...[
                              const SizedBox(height: 2),
                              Text('Code: ${_teamCode!}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryPurple)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_members.length} members',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2E7D32))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                      'Peer competition is by completion, not raw readiness score.',
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
                        const Icon(LucideIcons.target,
                            size: 18, color: AppTheme.accentCoral),
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
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text('Squad Members',
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ..._members.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PremiumCard(
                          padding: const EdgeInsets.all(14),
                          radius: AppRadius.card,
                          child: Row(children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: m.isTeamLeader
                                    ? AppTheme.primaryPurple
                                    : const Color(0xFFEFF1F5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                m.name.isNotEmpty ? m.name[0] : 'S',
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w900,
                                  color: m.isTeamLeader
                                      ? Colors.white
                                      : const Color(0xFF241B47),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Flexible(
                                        child: Text(m.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800)),
                                      ),
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
                                            fontWeight: FontWeight.w600,
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
                      style: GoogleFonts.sora(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (_feed.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.cardBorder,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(
                          'Verified squad activity from the last 7 days will appear here.',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppTheme.mutedText)),
                    )
                  else
                    ..._feed.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PremiumCard(
                            padding: const EdgeInsets.all(12),
                            radius: AppRadius.card,
                            child: Row(children: [
                              const Icon(LucideIcons.checkCircle2,
                                  size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: f.memberName,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                  TextSpan(
                                      text: ' verified "${f.questTitle}"',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppTheme.mutedText)),
                                ])),
                              ),
                              Text(_relativeTime(f.completedAt),
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: AppTheme.mutedText)),
                            ]),
                          ),
                        )),
                ],
              ],
            ),
    );
  }

  Widget _buildAllTeamsTab() {
    if (_allTeamsLoading && _allTeams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing placement teams from database...'),
            ],
          ),
        ),
      );
    }

    if (!_allTeamsLoading && _allTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.users, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load placement teams right now.',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Make sure your database connection is active.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadAllTeams(force: true),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredTeams = _allTeams.where((team) {
      if (_searchQuery.isEmpty) return true;
      final matchTeam = team.teamName.toLowerCase().contains(_searchQuery) ||
          team.teamCode.toLowerCase().contains(_searchQuery);
      final matchMember = team.members.any((m) =>
          m.name.toLowerCase().contains(_searchQuery) ||
          m.rollNo.toLowerCase().contains(_searchQuery));
      return matchTeam || matchMember;
    }).toList();

    return Column(
      children: [
        // Search and Stats bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by roll no or name (e.g. 26MX...)...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PSG Tech · Placement Squads',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText)),
                  Text(
                    '${filteredTeams.length} / ${_allTeams.length} Teams',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentCoral),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Teams List
        Expanded(
          child: filteredTeams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.searchX,
                            size: 36, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No teams or members match "$_searchQuery"',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadAllTeams(force: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      return _TeamDirectoryCard(team: team, searchQuery: _searchQuery);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time.toLocal());
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TeamDirectoryCard extends StatefulWidget {
  final PlacementTeam team;
  final String searchQuery;

  const _TeamDirectoryCard({required this.team, required this.searchQuery});

  @override
  State<_TeamDirectoryCard> createState() => _TeamDirectoryCardState();
}

class _TeamDirectoryCardState extends State<_TeamDirectoryCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _TeamDirectoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if matching search query
    if (widget.searchQuery.isNotEmpty && !_expanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leader = widget.team.leader;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        radius: AppRadius.card,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF241B47), Color(0xFF4A3E80)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'T${widget.team.teamNumber.toString().padLeft(2, '0')}',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.team.teamName,
                                style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${widget.team.members.length} members',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (leader != null)
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                  text: 'Lead: ',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accentCoral)),
                              TextSpan(
                                  text: '${leader.name} (${leader.rollNo})',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.black87)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 20),
              Column(
                children: widget.team.members.map((member) {
                  final isLeader = member.isLeader;
                  final isSearched = widget.searchQuery.isNotEmpty &&
                      (member.name
                              .toLowerCase()
                              .contains(widget.searchQuery) ||
                          member.rollNo
                              .toLowerCase()
                              .contains(widget.searchQuery));

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSearched
                          ? const Color(0xFFFFF3E0)
                          : isLeader
                              ? const Color(0xFFF7F5FF)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text('${member.sNo}.',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.rollNo,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF241B47),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            member.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isLeader
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLeader)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple
                                  .withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Leader',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
