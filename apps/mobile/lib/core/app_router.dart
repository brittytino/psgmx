import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../ui/auth/auth_screen.dart';
import '../ui/auth/onboarding_story_screen.dart';
import '../ui/auth/batch_confirmation_screen.dart';
import '../ui/auth/calibration_quiz_screen.dart';
import '../ui/auth/outcome_reveal_screen.dart';

import '../ui/root_layout.dart';
import '../ui/admin/team_management_screen.dart';
import '../ui/admin/member_permissions_screen.dart';
import '../ui/attendance/placement_sessions_screen.dart';
import '../ui/attendance/new_session_screen.dart';
import '../ui/admin/schedule_placement_session_screen.dart';
import '../ui/daily_five/daily_five_screen.dart';
import '../ui/admin/question_bank_screen.dart';
import '../ui/placement_log/placement_log_screen.dart';
import '../ui/placement_log/add_experience_screen.dart';
import '../ui/placement_log/company_detail_screen.dart';
import '../ui/ai_mentor/ai_mentor_screen.dart';
import '../ui/notifications/notifications_screen.dart';
import '../ui/tasks/bulk_upload_screen.dart';
import '../ui/rankings/pulse_rankings_screen.dart';
import '../ui/rankings/leetcode_arena_screen.dart';
import '../ui/admin/command_center_screen.dart';
import '../ui/profile/credits_screen.dart';
import '../ui/profile/graduation_screen.dart';
import '../ui/exam/proctored_exam_screen.dart';
import '../ui/splash/splash_screen.dart';

import '../models/company.dart';

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
          path: '/admin/team-management',
          builder: (context, state) => const TeamManagementScreen(),
        ),
        GoRoute(
          path: '/admin/permissions',
          builder: (context, state) => const MemberPermissionsScreen(),
        ),
        GoRoute(
          path: '/placement-sessions',
          builder: (context, state) => const PlacementSessionsScreen(),
        ),
        GoRoute(
          path: '/admin/schedule-session',
          builder: (context, state) => const SchedulePlacementSessionScreen(),
        ),
        GoRoute(
          path: '/admin/new-session',
          builder: (context, state) => const NewSessionScreen(),
        ),
        GoRoute(
          path: '/daily-five',
          builder: (context, state) => const DailyFiveScreen(),
        ),
        GoRoute(
          path: '/admin/question-bank',
          builder: (context, state) => const QuestionBankScreen(),
        ),
        GoRoute(
          path: '/placement-log',
          builder: (context, state) => const PlacementLogScreen(),
        ),
        GoRoute(
          path: '/placement-log/add',
          builder: (context, state) => const AddExperienceScreen(),
        ),
        GoRoute(
          path: '/placement-log/company/:id',
          builder: (context, state) {
            final company = state.extra as Company;
            return CompanyDetailScreen(company: company);
          },
        ),
        GoRoute(
          path: '/ai-mentor',
          builder: (context, state) => const AiMentorScreen(),
        ),
        GoRoute(
          path: '/admin/bulk-upload',
          builder: (context, state) => const BulkUploadScreen(),
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
          path: '/admin/command-center',
          builder: (context, state) => const CommandCenterScreen(),
        ),
        GoRoute(
          path: '/credits',
          builder: (context, state) => const CreditsScreen(),
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
        final isPreAuthRoute = currentPath == '/login' || currentPath == '/onboarding';
        final isPostAuthOnboarding = currentPath == '/batch-confirmation' || 
                                     currentPath == '/calibration' || 
                                     currentPath == '/outcome';

        if (isAuthenticated) {
          if (userProvider.needsGraduationScreen && currentPath != '/graduation') {
            return '/graduation';
          }
          if (userProvider.needsCalibration) {
            if (!isPostAuthOnboarding) {
              return '/batch-confirmation';
            }
          } else {
            if (isPreAuthRoute || isPostAuthOnboarding || currentPath == '/splash') {
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
