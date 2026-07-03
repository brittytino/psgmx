import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class GraduationScreen extends StatefulWidget {
  const GraduationScreen({super.key});

  @override
  State<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends State<GraduationScreen> {
  bool _isLoading = true;
  double _finalScore = 0.0;
  int _longestStreak = 0;
  int _leetcodeScore = 0;
  int _examsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null) return;
      
      final client = Supabase.instance.client;
      
      // Fetch readiness score history (latest)
      final scoreResp = await client
          .from('readiness_scores')
          .select('score')
          .eq('user_id', user.uid)
          .order('computed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      // Fetch streak
      final streakResp = await client
          .from('daily_five_streaks')
          .select('longest_streak')
          .eq('user_id', user.uid)
          .maybeSingle();
          
      // Fetch leetcode stats
      final leetcodeResp = await client
          .from('leetcode_stats')
          .select('batch_weighted_score')
          .eq('user_id', user.uid)
          .maybeSingle();
          
      // Fetch mock exams count
      final examsResp = await client
          .from('mock_exam_results')
          .select('id')
          .eq('student_id', user.uid);

      if (mounted) {
        setState(() {
          _finalScore = (scoreResp != null ? (scoreResp['score'] as num).toDouble() : 0.0);
          _longestStreak = (streakResp != null ? (streakResp['longest_streak'] as int?) ?? 0 : 0);
          _leetcodeScore = (leetcodeResp != null ? (leetcodeResp['batch_weighted_score'] as int?) ?? 0 : 0);
          _examsCount = (examsResp as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching graduation stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enterArchive() async {
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_graduation_${user.uid}', true);
    }
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Alumni';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(LucideIcons.graduationCap, size: 64, color: AppTheme.accentCoral),
              const SizedBox(height: 24),
              Text(
                'Happy Graduation,\n$firstName! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your batch has officially graduated.\nHere is a look back at what you achieved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              Expanded(
                child: Column(
                  children: [
                    _buildStatCard(
                      'Final Readiness Score',
                      _finalScore.toStringAsFixed(1),
                      LucideIcons.trophy,
                      AppTheme.accentCoral,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Longest Streak',
                            '$_longestStreak days',
                            LucideIcons.flame,
                            const Color(0xFFFF7043),
                            theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'LeetCode Score',
                            '$_leetcodeScore',
                            LucideIcons.code2,
                            const Color(0xFFFFB74D),
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Mock Exams Completed',
                      '$_examsCount exams',
                      LucideIcons.fileText,
                      Colors.indigo,
                      theme,
                    ),
                  ],
                ),
              ),
              
              FilledButton(
                onPressed: _enterArchive,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentCoral,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Enter Archive Mode',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
