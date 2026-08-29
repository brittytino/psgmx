import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
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
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
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
