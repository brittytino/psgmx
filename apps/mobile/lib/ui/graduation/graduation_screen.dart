import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/user_provider.dart';

/// Graduation Screen
///
/// Shown once to the user when their batch transitions to 'graduated'.
/// Displays their final readiness score, longest streak, and LeetCode stats.
/// After dismissal, sets SharedPreferences flag so it never shows again.
class GraduationScreen extends StatefulWidget {
  const GraduationScreen({super.key});

  @override
  State<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends State<GraduationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  double _finalScore = 0;
  int _longestStreak = 0;
  int _leetcodeSolved = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleIn = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _loadStats();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final client = Supabase.instance.client;

    final results = await Future.wait([
      client
          .from('readiness_scores')
          .select('score')
          .eq('user_id', uid)
          .maybeSingle(),
      client
          .from('daily_five_streaks')
          .select('longest_streak')
          .eq('user_id', uid)
          .maybeSingle(),
      client
          .from('leetcode_stats')
          .select('total_solved')
          .eq('user_id', uid)
          .maybeSingle(),
    ]);

    if (mounted) {
      setState(() {
        _finalScore    = (results[0]?['score'] as num?)?.toDouble() ?? 0;
        _longestStreak = (results[1]?['longest_streak'] as int?) ?? 0;
        _leetcodeSolved = (results[2]?['total_solved'] as int?) ?? 0;
        _loading       = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.currentUser?.uid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_graduation_$uid', true);
    }
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  String get _scoreBand {
    if (_finalScore >= 80) return 'Strong';
    if (_finalScore >= 60) return 'Building';
    if (_finalScore >= 40) return 'Needs Attention';
    return 'At Risk';
  }

  Color get _scoreBandColor {
    if (_finalScore >= 80) return const Color(0xFF22C55E);
    if (_finalScore >= 60) return const Color(0xFF3B82F6);
    if (_finalScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Graduate';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)))
            : FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Animated trophy emoji
                      ScaleTransition(
                        scale: _scaleIn,
                        child: const Text('🎓', style: TextStyle(fontSize: 80)),
                      ),
                      const SizedBox(height: 24),

                      // Headline
                      Text(
                        'Congratulations,\n$firstName!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'ve completed your MCA journey at PSG Tech.\nWelcome to the PSGMX alumni network.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Final Readiness Score Card
                      _StatCard(
                        emoji: '📊',
                        label: 'Final Readiness Score',
                        value: _finalScore.toStringAsFixed(1),
                        suffix: '/ 100',
                        badge: _scoreBand,
                        badgeColor: _scoreBandColor,
                      ),
                      const SizedBox(height: 16),

                      // Streak + LeetCode row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              emoji: '🔥',
                              label: 'Longest Streak',
                              value: '$_longestStreak',
                              suffix: 'days',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              emoji: '💻',
                              label: 'LeetCode Solved',
                              value: '$_leetcodeSolved',
                              suffix: 'problems',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF818CF8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Continue to Alumni Dashboard',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String suffix;
  final String? badge;
  final Color? badgeColor;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.suffix,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.green).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (badgeColor ?? Colors.green).withValues(alpha: 0.4)),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  color: badgeColor ?? Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
