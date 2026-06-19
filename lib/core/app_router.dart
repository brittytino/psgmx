import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../ui/auth/auth_screen.dart';
import '../ui/root_layout.dart';
import '../ui/splash_screen.dart';
import '../ui/admin/team_management_screen.dart';
import '../ui/admin/member_permissions_screen.dart';
import '../ui/attendance/placement_sessions_screen.dart';
import '../ui/admin/schedule_placement_session_screen.dart';
import '../ui/daily_five/daily_five_screen.dart';
import '../ui/admin/question_bank_screen.dart';
import '../ui/placement_log/placement_log_screen.dart';
import '../ui/placement_log/company_detail_screen.dart';
import '../ui/ai_mentor/ai_mentor_screen.dart';
import '../ui/notifications/notifications_screen.dart';

import '../models/company.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// App Router: Navigation configuration with authentication guards
class AppRouter {
  static GoRouter createRouter(UserProvider userProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: userProvider,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
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
          path: '/admin/teams',
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
      ],
      redirect: (context, state) {
        final currentPath = state.uri.toString();
        debugPrint('[AppRouter] Redirect check: Path=$currentPath, Init=${userProvider.initComplete}, Auth=${userProvider.currentUser != null}');

        // 1. Still initializing - show splash screen
        if (!userProvider.initComplete) {
          if (currentPath != '/splash') {
            return '/splash';
          }
          return null; // Already at splash
        }

        // 2. After initialization is complete, route based on auth state
        final isAuthenticated = userProvider.currentUser != null;

        // If at splash and init is complete, redirect based on auth
        if (currentPath == '/splash') {
          return isAuthenticated ? '/' : '/login';
        }

        // Define auth screens (unauthenticated-only routes)
        const loginPath = '/login';

        if (isAuthenticated) {
          // If user is logged in but tries to access login/auth screens, redirect to home
          if (currentPath == loginPath) {
            return '/';
          }
        } else {
          // If user is NOT logged in and tries to access protected screens, redirect to login
          if (currentPath != loginPath) {
            return '/login';
          }
        }

        return null;
      },
    );
  }
}
