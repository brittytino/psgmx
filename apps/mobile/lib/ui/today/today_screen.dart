import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/daily_five_provider.dart';
import '../../providers/ecampus_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/user_provider.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  double? readiness;
  int assignedTasks = 0;
  bool taskCompleted = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    await Future.wait([
      context.read<DailyFiveProvider>().loadState(user.uid),
      context.read<AnnouncementProvider>().fetchAnnouncements(),
      if (user.regNo.isNotEmpty)
        context.read<EcampusProvider>().init(user.regNo),
    ]);
    final supabase = Supabase.instance.client;
    final today = DateTime.now().toIso8601String().split('T').first;
    final scoreResult = await supabase
        .from('current_readiness_scores')
        .select('score')
        .eq('user_id', user.uid)
        .maybeSingle();
    final taskResult =
        await supabase.from('daily_tasks').select('id').eq('date', today);
    final completionResult = await supabase
        .from('task_completions')
        .select('completed')
        .eq('user_id', user.uid)
        .eq('task_date', today)
        .maybeSingle();
    if (!mounted) return;
    setState(() {
      final score = scoreResult;
      readiness =
          score == null ? null : double.tryParse(score['score'].toString());
      assignedTasks = taskResult.length;
      taskCompleted = completionResult?['completed'] == true;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser!;
    final dailyFive = context.watch<DailyFiveProvider>();
    final ecampus = context.watch<EcampusProvider>();
    final announcements = context.watch<AnnouncementProvider>().announcements;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final batchCode = RegExp(r'\d{2}MX').firstMatch(user.regNo)?.group(0) ??
        (user.isActiveSenior ? '25MX' : '26MX');
    final campusIndex = user.isActiveSenior ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(greeting,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B))),
                                Text(user.name.split(' ').first,
                                    style: GoogleFonts.sora(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF17132D)))
                              ])),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                      color: const Color(0xFFE8EAF0))),
                              child: Text(batchCode,
                                  style: GoogleFonts.sora(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.accentCoral)))
                        ]))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _HeroCard(
                            completed: dailyFive.completedToday,
                            streak: dailyFive.streak?.currentStreak ?? 0,
                            onTap: () => context.push('/daily-five')))),
                if (batchCode == '26MX' &&
                    (user.leetcodeUsername == null ||
                        user.leetcodeUsername!.isEmpty))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context
                            .read<NavigationProvider>()
                            .setIndex(user.isActiveSenior ? 4 : 3),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: const Color(0xFFFFD4BF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCoral
                                      .withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(LucideIcons.code2,
                                    color: AppTheme.accentCoral, size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Connect your LeetCode profile',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 3),
                                    Text(
                                        'Enter it once in You to activate live progress.',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight,
                                  size: 18, color: AppTheme.accentCoral),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        child: Row(children: [
                          Text('Your five-minute loop',
                              style: GoogleFonts.sora(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text(
                              loading
                                  ? '…'
                                  : '${[
                                      ecampus.attendance != null,
                                      dailyFive.completedToday,
                                      taskCompleted
                                    ].where((v) => v).length}/3',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accentCoral))
                        ]))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          _LoopTile(
                              icon: LucideIcons.graduationCap,
                              title: 'Check attendance',
                              subtitle: ecampus.attendance == null
                                  ? 'Refresh your academic attendance'
                                  : '${ecampus.attendance!.summary.overallPercentage.toStringAsFixed(1)}% overall attendance',
                              done: ecampus.attendance != null,
                              onTap: () => context
                                  .read<NavigationProvider>()
                                  .setIndex(campusIndex)),
                          const SizedBox(height: 10),
                          _LoopTile(
                              icon: LucideIcons.brain,
                              title: 'Complete Daily Five',
                              subtitle: dailyFive.completedToday
                                  ? 'Done for today · ${dailyFive.streak?.currentStreak ?? 0} day streak'
                                  : 'Five focused questions · about 3 minutes',
                              done: dailyFive.completedToday,
                              primary: !dailyFive.completedToday,
                              onTap: () => context.push('/daily-five')),
                          const SizedBox(height: 10),
                          _LoopTile(
                              icon: LucideIcons.listChecks,
                              title: 'Finish today’s quest',
                              subtitle: assignedTasks == 0
                                  ? 'No task has been published yet'
                                  : taskCompleted
                                      ? 'Today’s quest is complete'
                                      : '$assignedTasks task${assignedTasks == 1 ? '' : 's'} waiting',
                              done: taskCompleted,
                              onTap: () => context
                                  .read<NavigationProvider>()
                                  .setIndex(1)),
                        ]))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        child: Text('Progress',
                            style: GoogleFonts.sora(
                                fontSize: 17, fontWeight: FontWeight.w800)))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: const Color(0xFFE8EAF0))),
                            child: Row(children: [
                              Container(
                                  width: 58,
                                  height: 58,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.accentCoral
                                          .withValues(alpha: .1)),
                                  child: Text(
                                      readiness == null
                                          ? '—'
                                          : '${readiness!.round()}',
                                      style: GoogleFonts.sora(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentCoral))),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Placement readiness',
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 3),
                                    Text(
                                        readiness == null
                                            ? 'Your score appears as you build a routine.'
                                            : 'Small daily actions are moving your score.',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B)))
                                  ])),
                              const Icon(LucideIcons.trendingUp,
                                  color: Color(0xFF16A34A))
                            ])))),
                if (announcements.isNotEmpty)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
                          child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                  color: announcements.first.isPriority
                                      ? const Color(0xFFFFF0EA)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: announcements.first.isPriority
                                          ? const Color(0xFFFFCAB8)
                                          : const Color(0xFFE8EAF0))),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.megaphone,
                                        size: 19, color: AppTheme.accentCoral),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(announcements.first.title,
                                              style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(announcements.first.message,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  height: 1.45,
                                                  color:
                                                      const Color(0xFF64748B)))
                                        ]))
                                  ])))),
                if (announcements.isEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ])),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.completed, required this.streak, required this.onTap});
  final bool completed;
  final int streak;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF241B47), Color(0xFF4A2E80)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF241B47).withValues(alpha: .22),
                blurRadius: 26,
                offset: const Offset(0, 14))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(99)),
              child: Text('TODAY',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70))),
          const Spacer(),
          const Icon(LucideIcons.flame, color: Color(0xFFFFB35C)),
          Text(' $streak',
              style: GoogleFonts.sora(
                  fontWeight: FontWeight.w900, color: Colors.white))
        ]),
        const SizedBox(height: 18),
        Text(completed ? 'Daily Five complete.' : 'Build today’s edge.',
            style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 6),
        Text(
            completed
                ? 'Come back tomorrow to continue your streak.'
                : 'Five questions. Immediate feedback. Three focused minutes.',
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.45, color: Colors.white70)),
        const SizedBox(height: 18),
        FilledButton.icon(
            onPressed: completed ? null : onTap,
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF241B47),
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70),
            icon: Icon(completed ? LucideIcons.check : LucideIcons.play,
                size: 16),
            label: Text(completed ? 'Completed today' : 'Start Daily Five',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900)))
      ]));
}

class _LoopTile extends StatelessWidget {
  const _LoopTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.done,
      required this.onTap,
      this.primary = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool primary;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: primary ? const Color(0xFFFFF0EA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: primary
                        ? const Color(0xFFFFCAB8)
                        : const Color(0xFFE8EAF0))),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: primary
                          ? AppTheme.accentCoral
                          : const Color(0xFFF1EEFA),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon,
                      size: 19,
                      color: primary ? Colors.white : const Color(0xFF5B3D91))),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: const Color(0xFF64748B)))
                  ])),
              Icon(done ? LucideIcons.circleCheckBig : LucideIcons.chevronRight,
                  size: 19,
                  color:
                      done ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)),
            ]),
          ),
        ),
      );
}
