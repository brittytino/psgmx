import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/daily_five_provider.dart';

class TrainHubScreen extends StatelessWidget {
  const TrainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyFive = context.watch<DailyFiveProvider>();
    final streak = dailyFive.streak?.currentStreak ?? 0;
    final completedToday = dailyFive.completedToday;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Preparation Gymnasium',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Five Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              streak > 0
                                  ? '$streak DAY STREAK'
                                  : 'START YOUR STREAK',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'DAILY HABIT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Five Concept Drill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '5 targeted questions across DSA, DBMS, OS & Aptitude calibrated to your recent learning gaps.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/daily-five'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        completedToday ? 'Completed Today' : 'Start Daily Five',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Targeted Micro-Drills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 12),

            // Adaptive Skill Sprint Card
            _buildDrillCard(
              context: context,
              icon: Icons.psychology_outlined,
              color: Colors.blue,
              title: 'Adaptive Skill Sprint',
              subtitle:
                  '5, 10, or 20 min focus drills that adapt question difficulty to live performance.',
              actionLabel: 'Launch Sprint',
              onTap: () => context.push('/daily-five'),
            ),

            const SizedBox(height: 12),

            // Communication Audio Practice Card
            _buildDrillCard(
              context: context,
              icon: Icons.mic_none_outlined,
              color: Colors.orange,
              title: 'Communication Practice',
              subtitle:
                  '2-minute audio recording evaluated by AI for clarity, answer structure & filler words.',
              actionLabel: 'Record Audio (2m)',
              onTap: () => context.push('/train/communication'),
            ),

            const SizedBox(height: 12),

            // Interview Patterns Card
            _buildDrillCard(
              context: context,
              icon: Icons.pattern_outlined,
              color: Colors.teal,
              title: 'Interview Pattern Library',
              subtitle:
                  'Real company interview rounds and problem breakdowns shared by alumni.',
              actionLabel: 'Explore Patterns',
              onTap: () => context.push('/interview-patterns'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrillCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                    ],
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
