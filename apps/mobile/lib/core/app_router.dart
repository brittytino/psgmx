import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../ui/auth/auth_screen.dart';
import '../ui/auth/onboarding_story_screen.dart';
import '../ui/auth/batch_confirmation_screen.dart';
import '../ui/auth/calibration_quiz_screen.dart';
import '../ui/auth/outcome_reveal_screen.dart';

import '../ui/root_layout.dart';
import '../ui/daily_five/daily_five_screen.dart';
import '../ui/interview_patterns/interview_patterns_screen.dart';
import '../ui/bunker/bunker_screen.dart';
import '../ui/ai_mentor/ai_mentor_screen.dart';
import '../ui/notifications/notifications_screen.dart';
import '../ui/rankings/pulse_rankings_screen.dart';
import '../ui/rankings/leetcode_arena_screen.dart';
import '../ui/profile/credits_screen.dart';
import '../ui/profile/graduation_screen.dart';
import '../ui/profile/help_support_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/exam/proctored_exam_screen.dart';
import '../ui/splash/splash_screen.dart';
import '../ui/train/train_hub_screen.dart';
import '../ui/train/communication_practice_screen.dart';
import '../ui/admin/command_center_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App Router: Navigation configuration with authentication guards
class AppRouter {
  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: userProvider,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingStoryScreen(),
        ),
        GoRoute(
          path: '/batch-confirmation',
          builder: (context, state) => const BatchConfirmationScreen(),
        ),
        GoRoute(
          path: '/calibration',
          builder: (context, state) => const CalibrationQuizScreen(),
        ),
        GoRoute(
          path: '/outcome',
          builder: (context, state) => const OutcomeRevealScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const RootLayout(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const _CompanionTabRoute(index: 2),
        ),
        GoRoute(
          path: '/progress/dimension/:dimension',
          builder: (context, state) => const _CompanionTabRoute(index: 2),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const _CompanionTabRoute(index: 3),
        ),
        GoRoute(
          path: '/community/knowledge-brain',
          builder: (context, state) => const _CompanionTabRoute(index: 3),
        ),
        GoRoute(
          path: '/community/lineage',
          builder: (context, state) => const _CompanionTabRoute(index: 3),
        ),
        GoRoute(
          path: '/community/squads',
          builder: (context, state) => const _CompanionTabRoute(index: 3),
        ),
        GoRoute(
          path: '/you',
          builder: (context, state) => const _CompanionTabRoute(index: 4),
        ),
        GoRoute(
          path: '/you/connected-services',
          builder: (context, state) => const _CompanionTabRoute(index: 4),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/inbox',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/you/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/you/archive',
          builder: (context, state) => const GraduationScreen(),
        ),
        GoRoute(
          path: '/train',
          builder: (context, state) => const TrainHubScreen(),
        ),
        GoRoute(
          path: '/train/daily-five',
          builder: (context, state) => const DailyFiveScreen(),
        ),
        GoRoute(
          path: '/train/sprint',
          builder: (context, state) => const DailyFiveScreen(),
        ),
        GoRoute(
          path: '/train/communication',
          builder: (context, state) => const CommunicationPracticeScreen(),
        ),
        GoRoute(
          path: '/daily-five',
          builder: (context, state) => const DailyFiveScreen(),
        ),
        GoRoute(
          path: '/interview-patterns',
          builder: (context, state) => const InterviewPatternsScreen(),
        ),
        GoRoute(
          path: '/placement-log',
          redirect: (context, state) => '/interview-patterns',
        ),
        GoRoute(
          path: '/placement-log/company/:id',
          redirect: (context, state) => '/interview-patterns',
        ),
        GoRoute(
          path: '/campus',
          builder: (context, state) => const BunkerScreen(),
        ),
        GoRoute(
          path: '/ai-mentor',
          builder: (context, state) => const AiMentorScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const CommandCenterScreen(),
        ),
        GoRoute(
          path: '/pulse-rankings',
          builder: (context, state) => const PulseRankingsScreen(),
        ),
        GoRoute(
          path: '/leetcode-arena',
          builder: (context, state) => const LeetcodeArenaScreen(),
        ),
        GoRoute(
          path: '/credits',
          builder: (context, state) => const CreditsScreen(),
        ),
        GoRoute(
          path: '/help-support',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/proctored-exam',
          builder: (context, state) => const ProctoredExamScreen(),
        ),
        GoRoute(
          path: '/graduation',
          builder: (context, state) => const GraduationScreen(),
        ),
      ],
      redirect: (context, state) {
        final currentPath = state.uri.toString();

        if (!userProvider.initComplete) {
          return null; // Native splash handles this
        }

        final isAuthenticated = userProvider.currentUser != null;
        final isPreAuthRoute =
            currentPath == '/login' || currentPath == '/onboarding';
        final isPostAuthOnboarding = currentPath == '/batch-confirmation' ||
            currentPath == '/calibration' ||
            currentPath == '/outcome';

        if (isAuthenticated) {
          // PR is a student with an additional workspace. Keep the companion
          // available to them, while protecting the PR console from students
          // who do not hold that capability.
          if (currentPath == '/admin' && !userProvider.isPlacementRep) {
            return '/';
          }
          if (userProvider.needsGraduationScreen &&
              currentPath != '/graduation') {
            return '/graduation';
          }
          if (userProvider.needsCalibration) {
            if (!isPostAuthOnboarding) {
              return '/batch-confirmation';
            }
          } else {
            if (isPreAuthRoute ||
                isPostAuthOnboarding ||
                currentPath == '/splash') {
              return '/';
            }
          }
        } else {
          if (!isPreAuthRoute) {
            return '/onboarding';
          }
        }

        return null;
      },
    );
  }
}

class _CompanionTabRoute extends StatefulWidget {
  final int index;
  const _CompanionTabRoute({required this.index});

  @override
  State<_CompanionTabRoute> createState() => _CompanionTabRouteState();
}

class _CompanionTabRouteState extends State<_CompanionTabRoute> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navigation = context.read<NavigationProvider>();
    if (navigation.currentIndex != widget.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigation.setIndex(widget.index);
      });
    }
  }

  @override
  Widget build(BuildContext context) => const RootLayout();
}
