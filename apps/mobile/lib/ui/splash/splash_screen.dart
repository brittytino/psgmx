import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Navigation away from /splash is NOT handled here — it is driven entirely
// by AppRouter's `redirect` callback (core/app_router.dart), which reacts to
// UserProvider via `refreshListenable` the moment `initComplete` becomes
// true. This screen used to also fire its own `context.go(...)` on a fixed
// 2.5s timer, independently of real auth-state completion: on a slow
// network, that could navigate an already-authenticated user to /login (or
// otherwise disagree with the router's own reactive redirect that fires a
// moment later). Keep this screen purely decorative — animation only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3), // Light warm background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom Scenery Image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/splash/splash2.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Center Content (Mascot & Logo)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/splash/splash1.png',
                  width: 300, 
                ),
              ],
            ),
          ),

          // Bottom Progress Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 120,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: AppTheme.accentCoral.withValues(alpha: 0.2),
                        color: AppTheme.accentCoral,
                        minHeight: 4,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
