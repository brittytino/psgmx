/// PSGMX - MCA Readiness Companion
///
/// A continuous preparation, progress and alumni companion for PSG Tech MCA.
///
/// Author: Tino Britty J
/// GitHub: https://github.com/brittytino
/// Portfolio: https://tinobritty.me
///
/// Copyright (c) 2026 Tino Britty J
/// Licensed under the MIT License

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/supabase_config.dart';
import 'core/app_router.dart';
import 'providers/user_provider.dart';
import 'providers/leetcode_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ecampus_provider.dart';
import 'providers/daily_five_provider.dart';
import 'providers/batch_provider.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/supabase_db_service.dart';
import 'services/notification_service.dart';
import 'services/birthday_notification_service.dart';
import 'services/leetcode_auto_refresh_service.dart';
import 'services/update_service.dart';
import 'services/sync_service.dart';
import 'data/local_database.dart';

import 'ui/widgets/error_boundary.dart';
import 'ui/widgets/modern_offline_banner.dart';
import 'ui/widgets/notification_listener_wrapper.dart';
import 'ui/update/update_gate.dart';
import 'core/theme/app_theme.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // flutter_native_splash's web bridge is only generated when the package's
  // optional web setup is run. PSGMX uses its own Flutter splash route on the
  // PWA, so touching the native bridge there can throw before an existing
  // authenticated session is restored. Keep the native splash lifecycle on
  // Android/iOS and let Flutter render /splash on web.
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Initialize Global Error Handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[GLOBAL ERROR] ${details.exception}');
    return GlobalErrorWidget(errorDetails: details);
  };

  try {
    debugPrint('[APP] Validating environment configuration...');
    if (!SupabaseConfig.isConfigured) {
      throw Exception(
        'Missing required environment variables.\n'
        'Run the app with: flutter run --dart-define-from-file=.env.flutter\n'
        'Copy .env.example to .env.flutter and fill in your values.',
      );
    }
    debugPrint('[APP] Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('[APP] Supabase initialized successfully');
  } catch (error, stackTrace) {
    debugPrint('[APP ERROR] Critical initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (!kIsWeb) FlutterNativeSplash.remove();
    runApp(const _StartupFailureApp());
    return;
  }

  runApp(const PsgMxApp());
  unawaited(_initializeBackgroundServices());
}

Future<void> _initializeBackgroundServices() async {
  // These enhance the experience but must never delay the first frame or
  // prevent cached study work when a permission or network call is unavailable.
  await _initializeOptionalService(
    'NotificationService',
    NotificationService().init,
  );
  await Future.wait([
    _initializeOptionalService(
      'BirthdayNotificationService',
      BirthdayNotificationService().init,
    ),
    _initializeOptionalService('SyncService', () async {
      SyncService(Supabase.instance.client, localDb);
    }),
  ]);
}

Future<void> _initializeOptionalService(
  String name,
  Future<void> Function() initialize,
) async {
  try {
    debugPrint('[APP] Initializing $name...');
    await initialize();
    debugPrint('[APP] $name initialized successfully');
  } catch (error, stackTrace) {
    debugPrint('[APP] $name unavailable; continuing safely: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 34,
                        color: AppTheme.accentCoral,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PSGMX could not start',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check your internet connection, then close and reopen the app. Your saved progress is safe.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PsgMxApp extends StatelessWidget {
  const PsgMxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services
    final supabaseService = SupabaseService();
    final supabaseDbService = SupabaseDbService();
    final authService = AuthService(supabaseService);

    return MultiProvider(
      providers: [
        Provider<SupabaseService>.value(value: supabaseService),
        Provider<SupabaseDbService>.value(value: supabaseDbService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<NotificationService>.value(
            value: NotificationService()),
        ChangeNotifierProvider<UpdateService>.value(value: UpdateService()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => UserProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => LeetCodeProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(supabaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EcampusProvider(),
        ),
        // ── v4 Providers ──────────────────────────────────────────────────
        ChangeNotifierProvider(
          create: (_) => DailyFiveProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BatchProvider(),
        ),
      ],
      child: const PsgMxAppInner(),
    );
  }
}

class PsgMxAppInner extends StatefulWidget {
  const PsgMxAppInner({super.key});

  @override
  State<PsgMxAppInner> createState() => _PsgMxAppInnerState();
}

class _PsgMxAppInnerState extends State<PsgMxAppInner> {
  late final GoRouter _router;
  LeetCodeAutoRefreshService? _autoRefreshService;

  @override
  void initState() {
    super.initState();
    // Access provider via context inside initState (listen: false)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = AppRouter.createRouter(userProvider);

    // Initialize LeetCode auto-refresh service for daily updates
    _initAutoRefresh();
  }

  void _initAutoRefresh() {
    // Schedule after build to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leetCodeProvider =
          Provider.of<LeetCodeProvider>(context, listen: false);
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);

      _autoRefreshService =
          LeetCodeAutoRefreshService(leetCodeProvider, supabaseService);
      _autoRefreshService!.start();
      debugPrint('[APP] LeetCode auto-refresh service started');
    });
  }

  @override
  void dispose() {
    _autoRefreshService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PSGMX - MCA Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) {
        final mediaData = MediaQuery.of(context);
        // Respect the user's accessibility setting while preventing extreme
        // scaling from making primary actions unreachable on small screens.
        final scale = mediaData.textScaler.scale(1.0).clamp(0.9, 2.0);
        final scaledChild = MediaQuery(
          data: mediaData.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child ?? const SizedBox(),
        );

        return UpdateGate(
          child: NotificationListenerWrapper(
              child: ModernOfflineBanner(child: scaledChild)),
        );
      },
    );
  }
}
