import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/daily_five_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/premium_card.dart';

class TrainHubScreen extends StatefulWidget {
  const TrainHubScreen({super.key});

  @override
  State<TrainHubScreen> createState() => _TrainHubScreenState();
}

class _TrainHubScreenState extends State<TrainHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null) context.read<DailyFiveProvider>().loadState(user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dailyFive = context.watch<DailyFiveProvider>();
    final user = context.watch<UserProvider>().currentUser;
    final streak = dailyFive.streak?.currentStreak ?? 0;
    final completedToday = dailyFive.completedToday;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) await dailyFive.loadState(user.uid);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Text('Train',
                  style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF17132D))),
              const SizedBox(height: 5),
              Text(
                user?.isActiveSenior == true
                    ? 'Turn preparation into interview-ready proof.'
                    : 'Small, focused practice that compounds every day.',
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 18),
              _DailyFiveHero(
                completed: completedToday,
                streak: streak,
                onTap: () => context.push('/train/daily-five'),
              ),
              const SizedBox(height: 24),
              Text('Quick practice',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _PracticeCard(
                icon: LucideIcons.timerReset,
                title: 'Adaptive Skill Sprint',
                subtitle:
                    'Choose 5, 10 or 20 minutes. Difficulty grows with you.',
                action: 'Launch sprint',
                onTap: () => context.push('/train/sprint'),
              ),
              const SizedBox(height: 10),
              _PracticeCard(
                icon: LucideIcons.mic,
                title: 'Communication Practice',
                subtitle:
                    'Record a private two-minute answer and receive clear feedback.',
                action: 'Record audio',
                onTap: () => context.push('/train/communication'),
              ),
              const SizedBox(height: 10),
              _PracticeCard(
                icon: LucideIcons.libraryBig,
                title: 'Interview Pattern Library',
                subtitle:
                    'Learn reusable round patterns contributed by seniors and alumni.',
                action: 'Explore patterns',
                onTap: () => context.push('/interview-patterns'),
              ),
              const SizedBox(height: 24),
              Text('Deep work',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _DeepWorkGateway(
                onTap: () => context.push('/train/deep-work'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyFiveHero extends StatelessWidget {
  final bool completed;
  final int streak;
  final VoidCallback onTap;
  const _DailyFiveHero(
      {required this.completed, required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF20163D), Color(0xFF5B2A86)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B2A86).withValues(alpha: .2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  streak > 0 ? '$streak day rhythm' : 'Start your rhythm',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Icon(completed ? LucideIcons.circleCheck : LucideIcons.brain,
                  size: 21,
                  color: completed
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFFB899)),
            ]),
            const SizedBox(height: 18),
            Text('Daily Five',
                style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              completed
                  ? 'Today\'s five are complete. Reopen your explanations any time.'
                  : 'Five targeted questions selected from your learning gaps.',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3B2261),
                ),
                child: Text(completed ? 'Review today' : 'Start Daily Five'),
              ),
            ),
          ],
        ),
      );
}

class _PracticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PremiumCard(
        radius: AppRadius.card,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppTheme.accentCoral, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, height: 1.4, color: AppTheme.mutedText)),
              const SizedBox(height: 9),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(action,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentCoral)),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight,
                    size: 14, color: AppTheme.accentCoral),
              ]),
            ]),
          ),
        ]),
      );
}

class _DeepWorkGateway extends StatelessWidget {
  final VoidCallback onTap;
  const _DeepWorkGateway({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: const Color(0xFFFFD4BF)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(children: [
              const Icon(LucideIcons.monitorUp,
                  color: AppTheme.accentCoral, size: 23),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CodeBox & mock assessments',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'See open work here, then continue in the secure full-screen web workspace.',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.4,
                          color: const Color(0xFF7C5B4A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight,
                  color: AppTheme.accentCoral, size: 18),
            ]),
          ),
        ),
      );
}
