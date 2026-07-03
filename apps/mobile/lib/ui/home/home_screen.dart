import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/avatar_widget.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../services/readiness_score_service.dart';
import '../../models/readiness_score.dart';
import '../../models/leetcode_stats.dart';
import '../../providers/daily_five_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  ReadinessScore? _readinessScore;
  LeetCodeStats? _leetCodeStats;
  List<LeetCodeStats> _leetcodeLeaderboard = [];
  List<ReadinessScore> _readinessLeaderboard = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  String _scoreTrend = 'New';
  int _weeksLeft = 0;
  late AnimationController _fireAnimController;
  late Animation<double> _fireGlowAnim;

  @override
  void initState() {
    super.initState();
    _fireAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fireGlowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _fireAnimController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final readinessService = ReadinessScoreService(Supabase.instance.client);
    final leetcodeProvider = context.read<LeetCodeProvider>();
    final dailyFiveProvider = context.read<DailyFiveProvider>();

    try {
      // Use Future.wait to run independent data fetches in parallel for blazing fast load times
      final results = await Future.wait([
        dailyFiveProvider.loadState(user.uid),
        readinessService.fetchLatestScore(user.uid),
        readinessService.fetchScoreHistory(user.uid, limit: 2),
        if (user.leetcodeUsername != null && user.leetcodeUsername!.isNotEmpty)
          leetcodeProvider.fetchStats(user.leetcodeUsername!)
        else
          Future.value(null),
        leetcodeProvider.fetchAllUsers(),
        if (user.batchId != null)
          readinessService.fetchBatchLatestScores(user.batchId!)
        else
          Future.value(<ReadinessScore>[]),
      ]);

      _currentStreak = dailyFiveProvider.streak?.currentStreak ?? 0;
      _readinessScore = results[1] as ReadinessScore?;
      
      final history = results[2] as List<ReadinessScore>;
      if (history.length >= 2) {
        final diff = (history[0].score - history[1].score).round();
        _scoreTrend = diff >= 0 ? '+$diff' : '$diff';
      } else if (history.length == 1) {
        _scoreTrend = '+0';
      }

      final now = DateTime.now();
      var targetDate = DateTime(now.year, 8, 1);
      if (now.isAfter(targetDate)) {
        targetDate = DateTime(now.year + 1, 8, 1);
      }
      _weeksLeft = targetDate.difference(now).inDays ~/ 7;

      _leetCodeStats = results[3] as LeetCodeStats?;

      final allLeetcodeUsers = results[4] as List<LeetCodeStats>;
      _leetcodeLeaderboard = allLeetcodeUsers.take(10).toList();

      _readinessLeaderboard = (results[5] as List<ReadinessScore>?) ?? [];
      _readinessLeaderboard.sort((a, b) => b.score.compareTo(a.score));
      if (_readinessLeaderboard.length > 10) {
        _readinessLeaderboard = _readinessLeaderboard.sublist(0, 10);
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fireAnimController.dispose();
    super.dispose();
  }

  // --- Level System ---
  String _getLevel(int solved) {
    if (solved < 50) return 'Beginner';
    if (solved < 150) return 'Apprentice';
    if (solved < 300) return 'Knight';
    if (solved < 500) return 'Master';
    return 'Guardian';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Beginner': return const Color(0xFF94A3B8);
      case 'Apprentice': return const Color(0xFF22C55E);
      case 'Knight': return const Color(0xFF3B82F6);
      case 'Master': return const Color(0xFF8B5CF6);
      case 'Guardian': return const Color(0xFFD4AF37);
      default: return const Color(0xFF94A3B8);
    }
  }

  List<Color> _getLevelGradient(String level) {
    switch (level) {
      case 'Beginner': return const [Color(0xFF94A3B8), Color(0xFF64748B)];
      case 'Apprentice': return const [Color(0xFF22C55E), Color(0xFF16A34A)];
      case 'Knight': return const [Color(0xFF60A5FA), Color(0xFF3B82F6)];
      case 'Master': return const [Color(0xFFA78BFA), Color(0xFF8B5CF6)];
      case 'Guardian': return const [Color(0xFFFACC15), Color(0xFFD4AF37)];
      default: return const [Color(0xFF94A3B8), Color(0xFF64748B)];
    }
  }

  /// XP within the current level bracket (relative progress)
  double _getLevelProgress(int solved) {
    if (solved < 50) return solved / 50;
    if (solved < 150) return (solved - 50) / 100;
    if (solved < 300) return (solved - 150) / 150;
    if (solved < 500) return (solved - 300) / 200;
    return math.min(1.0, (solved - 500) / 500); // Guardian caps at 1000
  }

  String _getLevelXpText(int solved) {
    if (solved < 50) return '$solved / 50';
    if (solved < 150) return '${solved - 50} / 100';
    if (solved < 300) return '${solved - 150} / 150';
    if (solved < 500) return '${solved - 300} / 200';
    return '${solved - 500} / 500';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Student';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildHeader(firstName),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 24),

                    // Placement Readiness
                    _buildReadinessCard(),
                    const SizedBox(height: 24),

                    // Dual Cards (Spark Five & Logbook)
                    Row(
                      children: [
                        Expanded(child: _buildSparkCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLogCard(context)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // LeetCode Progress
                    _buildLeetCodeCard(),
                    const SizedBox(height: 32),

                    // Readiness Top Performers Podium
                    _buildReadinessLeaderboardList(user?.uid ?? ''),
                    const SizedBox(height: 32),
                    
                    // LeetCode Top Solvers Medals
                    _buildLeetCodeLeaderboardList(),
                    const SizedBox(height: 32),
                    
                    // Bottom Promotional Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(LucideIcons.trophy, color: Color(0xFF4F46E5), size: 12),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Climb the ranks, inspire others!', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                const SizedBox(height: 2),
                                Text('Consistency today, leadership tomorrow.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/ai-mentor'),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          child: ClipOval(child: Image.asset('assets/images/home/sparkAI.png', width: 44, height: 44, fit: BoxFit.cover)),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildHeader(String name) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name! 👋',
                style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s make today count.',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Streak
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _fireGlowAnim,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _currentStreak > 0 ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B00).withValues(alpha: 0.3 + _fireGlowAnim.value * 0.4),
                            blurRadius: 8 + _fireGlowAnim.value * 8,
                            spreadRadius: _fireGlowAnim.value * 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2 + _fireGlowAnim.value * 0.2),
                            blurRadius: 4 + _fireGlowAnim.value * 4,
                            spreadRadius: _fireGlowAnim.value,
                          ),
                        ] : [],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFD700), Color(0xFFFF6B00), Color(0xFFFF4500)],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: const FaIcon(FontAwesomeIcons.fire, color: Colors.white, size: 16),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentStreak',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Bell
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(LucideIcons.bell, color: Color(0xFF1E293B), size: 16),
                  Positioned(
                    right: 0, top: 0,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accentCoral, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 90,
          child: Image.asset(
            'assets/images/home/homeBanner.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLeetCodeCard() {
    final solved = _leetCodeStats?.totalSolved ?? 0;
    final easy = _leetCodeStats?.easySolved ?? 0;
    final medium = _leetCodeStats?.mediumSolved ?? 0;
    final hard = _leetCodeStats?.hardSolved ?? 0;
    
    final level = _getLevel(solved);
    final levelColor = _getLevelColor(level);
    final levelGradient = _getLevelGradient(level);
    final progress = _getLevelProgress(solved);
    final xpText = _getLevelXpText(solved);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.code, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LeetCode Progress', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('Keep building. Every problem counts.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/leetcode-arena'),
                child: Row(
                  children: [
                    Text('View All', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: AppTheme.accentCoral)),
                    const Icon(LucideIcons.chevronRight, size: 12, color: AppTheme.accentCoral),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Gauge
              SizedBox(
                width: 120, height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _GradientGaugePainter(
                        progress: math.min(1.0, progress),
                        gradientColors: levelGradient,
                        trackColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(solved.toString(), style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), height: 1.0)),
                        const SizedBox(height: 2),
                        Text('Solved\nTotal', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Level & XP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: levelColor, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('Current Level', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(level, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: levelColor)),
                        Text(xpText, 
                          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: math.min(1.0, progress),
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: levelColor,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat(const Color(0xFF22C55E), 'Easy', easy.toString()),
                        _buildMiniStat(const Color(0xFFEAB308), 'Medium', medium.toString()),
                        _buildMiniStat(const Color(0xFFEF4444), 'Hard', hard.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(Color color, String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        Text('Solved', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildReadinessCard() {
    final comps = _readinessScore?.components ?? const ReadinessComponents(
      placementAttendancePct: 0,
      dailyFiveAdherencePct: 0,
      taskCompletionRatePct: 0,
      dailyFiveAccuracyPct: 0,
      leetcodeMomentumPercentile: 0,
    );
    final score = _readinessScore?.score ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.target, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Placement Readiness', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('Track your readiness. Own your future.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/pulse-rankings'),
                child: Row(
                  children: [
                    Text('View All', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
                    const Icon(LucideIcons.chevronRight, size: 12, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Gauge & Stats
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90, height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _GradientGaugePainter(
                              progress: score / 100,
                              gradientColors: const [Color(0xFF818CF8), Color(0xFF4F46E5)],
                              trackColor: const Color(0xFFF1F5F9),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(score.round().toString(), style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), height: 1.0)),
                              Text('/ 100', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text('Readiness Score', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('You\'re improving! 🔥', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text('Great job staying consistent.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildReadinessStat(LucideIcons.trendingUp, const Color(0xFF8B5CF6), _scoreTrend, 'vs last week')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildReadinessStat(LucideIcons.target, const Color(0xFF3B82F6), '80', 'Target')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildReadinessStat(LucideIcons.calendarDays, const Color(0xFF22C55E), '$_weeksLeft', 'Weeks Left')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side: Radar Chart
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: RadarChart(
                        RadarChartData(
                          radarShape: RadarShape.polygon,
                          tickCount: 1,
                          ticksTextStyle: const TextStyle(color: Colors.transparent),
                          gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
                          radarBorderData: const BorderSide(color: Colors.transparent),
                          radarBackgroundColor: Colors.transparent,
                          getTitle: (index, angle) {
                            final titles = ['DSA', 'Aptitude', 'Core CS', 'Soft Skills', 'Consistency'];
                            return RadarChartTitle(text: titles[index]);
                          },
                          titleTextStyle: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF1E293B)),
                          dataSets: [
                            RadarDataSet(
                              fillColor: const Color(0xFF818CF8).withValues(alpha: 0.3),
                              borderColor: const Color(0xFF6366F1),
                              entryRadius: 3,
                              dataEntries: [
                                RadarEntry(value: comps.leetcodeMomentumPercentile),
                                RadarEntry(value: comps.dailyFiveAccuracyPct),
                                RadarEntry(value: comps.taskCompletionRatePct),
                                RadarEntry(value: comps.placementAttendancePct),
                                RadarEntry(value: comps.dailyFiveAdherencePct),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    _buildRadarLegend('DSA', comps.leetcodeMomentumPercentile.round()),
                    _buildRadarLegend('Aptitude', comps.dailyFiveAccuracyPct.round()),
                    _buildRadarLegend('Core CS', comps.taskCompletionRatePct.round()),
                    _buildRadarLegend('Soft Skills', comps.placementAttendancePct.round()),
                    _buildRadarLegend('Consistency', comps.dailyFiveAdherencePct.round()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessStat(IconData icon, Color color, String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildRadarLegend(String title, int val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF818CF8), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500)),
            ],
          ),
          Text(val.toString(), style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSparkCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/spark-five'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/home/notebook.png', width: 32, height: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spark Five', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('5 focused questions.\nSharpen daily.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B), height: 1.2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Start Now', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: AppTheme.accentCoral)),
                      const SizedBox(width: 2),
                      const Icon(LucideIcons.arrowRight, size: 10, color: AppTheme.accentCoral),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/logbook'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/home/placmentlogicon.png', width: 32, height: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logbook', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('Your journey,\nTracked.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B), height: 1.2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('View Logs', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                      const SizedBox(width: 2),
                      const Icon(LucideIcons.arrowRight, size: 10, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeetCodeLeaderboardList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFF97316).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFFFFF7ED), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.code, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LeetCode Top Solvers', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text('Solve more. Rank higher.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/leetcode-arena'),
                child: Row(
                  children: [
                    Text('View All', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFFF97316))),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 12, color: Color(0xFFF97316)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(
            10,
            (index) {
              if (index < _leetcodeLeaderboard.length) {
                final stat = _leetcodeLeaderboard[index];
                return _buildLeetCodeListItem(index + 1, stat.name ?? stat.username, stat.totalSolved.toString(), stat.profilePicture);
              }
              return _buildEmptyLeetCodeListItem(index + 1);
            },
          ),
          const SizedBox(height: 8),
          // Bottom Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                 Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle), child: const Icon(LucideIcons.trendingUp, color: Color(0xFFF97316), size: 12)),
                 const SizedBox(width: 10),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text('Climb the ranks!', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        Text('Solve daily. Stay consistent. Be the best.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                     ],
                   ),
                 ),
                 const Icon(LucideIcons.barChart2, color: Color(0xFFFB923C), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessLeaderboardList(String currentUserId) {
    final stat1 = _readinessLeaderboard.isNotEmpty ? _readinessLeaderboard[0] : null;
    final stat2 = _readinessLeaderboard.length > 1 ? _readinessLeaderboard[1] : null;
    final stat3 = _readinessLeaderboard.length > 2 ? _readinessLeaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFFF8FAFC), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.target, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Readiness Top Performers', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text('Track your placement readiness', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/pulse-rankings'),
                child: Row(
                  children: [
                    Text('View All', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronRight, size: 12, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Podium
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumItem(stat2, 2, 110, const Color(0xFFE2E8F0), const Color(0xFF94A3B8), currentUserId),
                const SizedBox(width: 8),
                _buildPodiumItem(stat1, 1, 140, const Color(0xFFE0E7FF), const Color(0xFF6366F1), currentUserId),
                const SizedBox(width: 8),
                _buildPodiumItem(stat3, 3, 90, const Color(0xFFFFEDD5), const Color(0xFFF97316), currentUserId),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bottom Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Row(
              children: [
                 Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle), child: const Icon(LucideIcons.trophy, color: Color(0xFF4F46E5), size: 16)),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text('Keep going, you\'re building your future!', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        Text('Consistency today, success tomorrow.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                     ],
                   ),
                 ),
                 const Icon(LucideIcons.sparkles, color: Color(0xFFFACC15), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(ReadinessScore? stat, int rank, double height, Color bgColor, Color badgeColor, String currentUserId) {
    final isMe = stat?.userId == currentUserId;
    final name = stat == null ? '--' : (isMe ? '${stat.userName?.split(' ').first ?? 'You'} (You)' : (stat.userName ?? 'Student'));
    final score = stat == null ? '--' : stat.score.round().toString();
    final avatarRadius = rank == 1 ? 30.0 : 22.0;
    
    return Expanded(
      child: SizedBox(
        height: height + 100,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Pedestal
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgColor, bgColor.withValues(alpha: 0.1)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(name, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 2),
                  Text(score, style: GoogleFonts.sora(fontSize: rank == 1 ? 14 : 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                  if (rank == 1) ...[
                    const SizedBox(height: 2),
                    Text('Readiness Score', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B))),
                  ],
                ],
              ),
            ),
            // Avatar + Crown + Badge
            Positioned(
              bottom: height - 12,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.crown, color: badgeColor, size: rank == 1 ? 20 : 16),
                      const SizedBox(height: 4),
                      if (stat != null)
                         AvatarWidget(name: name, avatarUrl: stat.avatarUrl, gender: stat.gender, radius: avatarRadius)
                      else
                         Container(width: avatarRadius*2, height: avatarRadius*2, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(LucideIcons.user, color: const Color(0xFF94A3B8), size: avatarRadius)),
                      const SizedBox(height: 10),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
                      child: Text(rank.toString(), style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8)),
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

  Widget _buildLeetCodeListItem(int rank, String name, String score, String? avatarUrl) {
    Color? bgColor;
    if (rank == 1) {
      bgColor = const Color(0xFFFEF3C7);
    } else if (rank == 2) {
      bgColor = const Color(0xFFF1F5F9);
    } else if (rank == 3) {
      bgColor = const Color(0xFFFFEDD5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: _buildRankBadge(rank),
          ),
          const SizedBox(width: 10),
          AvatarWidget(name: name, avatarUrl: avatarUrl, radius: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.fire, color: Color(0xFFF97316), size: 12),
              const SizedBox(width: 4),
              Text(score, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFEA580C))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Color textColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFF59E0B);
      textColor = Colors.white;
    } else if (rank == 2) {
      badgeColor = const Color(0xFF94A3B8);
      textColor = Colors.white;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFD97706);
      textColor = Colors.white;
    } else {
      return Center(child: Text(rank.toString(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))));
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Center(
        child: Text(rank.toString(), style: GoogleFonts.sora(fontSize: 8, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  Widget _buildEmptyLeetCodeListItem(int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(child: Text(rank.toString(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
          ),
          const SizedBox(width: 10),
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(LucideIcons.user, size: 12, color: Color(0xFF94A3B8))),
          const SizedBox(width: 10),
          Expanded(child: Text('-', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)))),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.fire, color: Color(0xFFCBD5E1), size: 12),
              const SizedBox(width: 4),
              Text('-', style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientGaugePainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final Color trackColor;

  _GradientGaugePainter({required this.progress, required this.gradientColors, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: math.pi * 0.75,
      endAngle: math.pi * 2.25,
      colors: gradientColors,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi * 0.75,
      (math.pi * 1.5) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
