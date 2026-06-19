import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_five.dart';
import '../../providers/daily_five_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';

/// The Daily Five quiz screen.
///
/// Delegates all data loading, answer tracking and submission to
/// [DailyFiveProvider]. This keeps the widget stateless with respect to
/// business logic — it only owns local UI state (animation controllers etc.).
class DailyFiveScreen extends StatefulWidget {
  const DailyFiveScreen({super.key});

  @override
  State<DailyFiveScreen> createState() => _DailyFiveScreenState();
}

class _DailyFiveScreenState extends State<DailyFiveScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load streak + questions via provider on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        context.read<DailyFiveProvider>().loadState(user.uid);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anti-cheat: auto-fail if app is backgrounded mid-quiz
    if ((state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive)) {
      final provider = context.read<DailyFiveProvider>();
      if (provider.sessionActive) {
        final userId = context.read<UserProvider>().currentUser?.uid;
        if (userId != null) {
          provider.handleViolation(userId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Five')),
      body: Consumer<DailyFiveProvider>(
        builder: (context, provider, _) => _buildBody(context, theme, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, DailyFiveProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Already completed today
    if (provider.completedToday && !provider.sessionFinished) {
      return _buildCompletedView(theme, provider.streak!);
    }

    // Results after finishing this session
    if (provider.sessionFinished) {
      return _buildResultsView(theme, provider);
    }

    // Error state
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  provider.clearError();
                  final user = context.read<UserProvider>().currentUser;
                  if (user != null) provider.loadState(user.uid);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Active quiz
    if (provider.session != null) {
      return _buildActiveQuiz(context, theme, provider);
    }

    return const Center(child: Text('Unexpected state.'));
  }

  // ── Completed Today View ─────────────────────────────────────────────────

  Widget _buildCompletedView(ThemeData theme, DailyFiveStreak streak) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "You're all done for today!",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Come back tomorrow for 5 new questions.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(theme, 'Current Streak', '${streak.currentStreak} 🔥'),
                  _buildStat(theme, 'Longest', '${streak.longestStreak} 🔥'),
                  _buildStat(
                    theme,
                    'Accuracy',
                    streak.lastAccuracyRate != null
                        ? '${(streak.lastAccuracyRate! * 100).toStringAsFixed(1)}%'
                        : 'N/A',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Quiz View ─────────────────────────────────────────────────────

  Widget _buildActiveQuiz(
      BuildContext context, ThemeData theme, DailyFiveProvider provider) {
    if (provider.isSubmitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Submitting results…'),
          ],
        ),
      );
    }

    final session = provider.session!;
    final currentQ = session.currentQuestion;
    final progress = session.currentIndex / session.questions.length;

    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${session.currentIndex + 1} of ${session.questions.length}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentQ.topic.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                currentQ.questionText,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...List.generate(currentQ.options.length, (idx) {
                final isSelected =
                    session.selectedAnswers[session.currentIndex] == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () {
                      final userId =
                          context.read<UserProvider>().currentUser?.uid;
                      if (userId != null) {
                        context.read<DailyFiveProvider>().submitAnswer(
                              userId: userId,
                              optionIndex: idx,
                            );
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSelected ? 6 : 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              currentQ.options[idx],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Results View ─────────────────────────────────────────────────────────

  Widget _buildResultsView(ThemeData theme, DailyFiveProvider provider) {
    final session = provider.session!;
    final correctCount = session.correctCount;
    final total = session.questions.length;
    final color = correctCount >= 3 ? Colors.green : Colors.orange;
    final streak = provider.streak;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PremiumCard(
          child: Column(
            children: [
              Icon(
                correctCount >= 3 ? Icons.emoji_events : Icons.thumb_up,
                size: 64,
                color: color,
              ),
              const SizedBox(height: 16),
              Text('Quiz Complete!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('You scored $correctCount out of $total',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(
                    theme,
                    'Accuracy',
                    '${(session.accuracyRate * 100).toStringAsFixed(0)}%',
                  ),
                  if (streak != null)
                    _buildStat(theme, 'Streak', '${streak.currentStreak} 🔥'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Review Answers',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(session.questions.length, (i) {
          final q = session.questions[i];
          final selected = session.selectedAnswers[i];
          final isCorrect = selected == q.correctOption;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Q${i + 1}: ${q.questionText}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Correct: ${q.options[q.correctOption]}',
                      style: const TextStyle(color: Colors.green)),
                  if (!isCorrect && selected != null && selected >= 0)
                    Text('Your answer: ${q.options[selected]}',
                        style: const TextStyle(color: Colors.red)),
                  if (selected == -1)
                    const Text('Violation: not answered in time',
                        style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
