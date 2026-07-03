import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import 'dart:math' as math;

class OutcomeRevealScreen extends StatefulWidget {
  const OutcomeRevealScreen({super.key});

  @override
  State<OutcomeRevealScreen> createState() => _OutcomeRevealScreenState();
}

class _OutcomeRevealScreenState extends State<OutcomeRevealScreen> with SingleTickerProviderStateMixin {
  late AnimationController _sparkController;
  late Animation<double> _sparkJumpAnimation;
  int _finalScore = 68;
  bool _hasJumped = false;

  @override
  void initState() {
    super.initState();
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sparkJumpAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -30.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 50),
    ]).animate(_sparkController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is int) {
      _finalScore = extra;
    }
  }

  @override
  void dispose() {
    _sparkController.dispose();
    super.dispose();
  }

  Future<void> _handleEnterApp() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.completeCalibration(_finalScore);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Student';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Confetti
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfettiPainter(),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Indicators (3 dashes, 3rd active)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 20,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == 2 ? AppTheme.accentCoral : AppTheme.illusGold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Top Text Section
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.star, color: AppTheme.accentCoral, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  'All set, $firstName!',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentCoral,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                              children: const [
                                TextSpan(text: 'Here\'s your\n'),
                                TextSpan(text: 'Starting Readiness', style: TextStyle(color: AppTheme.accentCoral)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your personalized readiness score',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Circular Gauge
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _finalScore.toDouble()),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            if (value >= _finalScore - 0.5 && !_hasJumped) {
                              _hasJumped = true;
                              _sparkController.forward();
                            }
                            
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  painter: _GaugePainter(
                                    progress: value / 100,
                                    color: AppTheme.accentCoral,
                                    trackColor: Colors.white,
                                    shadowColor: Colors.black.withValues(alpha: 0.04),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.sora(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
                                        height: 1.0,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '/ 100',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9), // Light green tint
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.arrowUpRight, color: Color(0xFF4CAF50), size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Good Start!',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2E7D32), // Darker green
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Mascot and Speech Bubble
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 120.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                        bottomLeft: Radius.circular(4), // tail effect
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Keep going!',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Consistency is your\nsuperpower.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(LucideIcons.zap, color: AppTheme.illusGold, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: -20,
                            bottom: -30,
                            child: AnimatedBuilder(
                              animation: _sparkController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _sparkJumpAnimation.value),
                                  child: Image.asset(
                                    'assets/images/onboarding/SmilingMascot.png',
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Bottom Text
                      Text(
                        'This is just day one — most students\ngrow 30+ points in their first month. 🤍',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _handleEnterApp,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentCoral,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Enter PSGMX',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 16),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Column(
                        children: [
                          Text(
                            'Excited for what\'s ahead?',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 12,
                            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final Color shadowColor;

  _GaugePainter({required this.progress, required this.color, required this.trackColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 28.0;

    // Draw drop shadow for the gauge
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      shadowPaint,
    );

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Draw progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      (math.pi * 1.5) * progress,
      false,
      progressPaint,
    );

    // Draw Radiating Spark Lines
    final sparkPaint = Paint()
      ..color = AppTheme.illusGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    void drawSparks(Offset origin, double startAngle, int count) {
      for (int i = 0; i < count; i++) {
        final angle = startAngle + (i * 0.4);
        final innerRadius = radius + 30;
        final outerRadius = radius + 45;
        
        final start = Offset(
          center.dx + innerRadius * math.cos(angle),
          center.dy + innerRadius * math.sin(angle),
        );
        final end = Offset(
          center.dx + outerRadius * math.cos(angle),
          center.dy + outerRadius * math.sin(angle),
        );
        canvas.drawLine(start, end, sparkPaint);
      }
    }

    drawSparks(center, math.pi * 1.1, 3); // Top left sparks
    drawSparks(center, math.pi * 1.7, 3); // Top right sparks
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    void drawShape(double dx, double dy, Color color, double rotation) {
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      paint.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -8, 8, 16), const Radius.circular(2)), paint);
      canvas.restore();
    }
    
    // Draw hardcoded background confetti pieces from s7
    drawShape(size.width * 0.1, size.height * 0.15, AppTheme.accentCoral, math.pi / 4);
    drawShape(size.width * 0.2, size.height * 0.1, AppTheme.illusGold, -math.pi / 6);
    drawShape(size.width * 0.85, size.height * 0.12, AppTheme.illusGold, math.pi / 3);
    drawShape(size.width * 0.9, size.height * 0.25, AppTheme.illusGold, -math.pi / 4);
    
    drawShape(size.width * 0.15, size.height * 0.25, AppTheme.illusSage, math.pi / 5);
    drawShape(size.width * 0.8, size.height * 0.18, AppTheme.illusSage, -math.pi / 7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
