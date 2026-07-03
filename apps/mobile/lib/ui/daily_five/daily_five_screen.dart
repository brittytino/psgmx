import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/daily_five_provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter/foundation.dart';

class DailyFiveScreen extends StatefulWidget {
  const DailyFiveScreen({super.key});

  @override
  State<DailyFiveScreen> createState() => _DailyFiveScreenState();
}

class _DailyFiveScreenState extends State<DailyFiveScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _timeLeft = 0;
  int _totalTime = 1;
  int? _selectedOption;
  int _warningCount = 0;
  bool _isWarningOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secureScreen();
    
    // Start initial timer after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _startTimerForCurrentQuestion();
    });
  }

  Future<void> _secureScreen() async {
    try {
      if (!kIsWeb) {
        await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      debugPrint('[DailyFiveScreen] Failed to secure screen: $e');
    }
  }

  Future<void> _unsecureScreen() async {
    try {
      if (!kIsWeb) {
        await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e) {
      debugPrint('[DailyFiveScreen] Failed to unsecure screen: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _unsecureScreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final provider = context.read<DailyFiveProvider>();
      final auth = context.read<UserProvider>();
      if (auth.currentUser != null && provider.sessionActive) {
        if (!_isWarningOpen) {
          _warningCount++;
          if (_warningCount > 3) {
            _timer?.cancel();
            provider.handleTermination(auth.currentUser!.uid);
          } else {
            _isWarningOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWarningDialog();
            });
          }
        }
      }
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red),
            const SizedBox(width: 8),
            Text('Proctoring Warning ($_warningCount/3)', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold)),
          ]
        ),
        content: Text(
          'Please do not exit the app, use split screen, or pull down the notification center during the exam.\n\nExceeding 3 warnings will terminate your exam and reset your streak to 0.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _isWarningOpen = false;
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCoral, foregroundColor: Colors.white),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _startTimerForCurrentQuestion() {
    final provider = context.read<DailyFiveProvider>();
    if (!provider.sessionActive || provider.session == null) return;

    final question = provider.session!.questions[provider.session!.currentIndex];
    
    int duration = 35; // Default medium
    if (question.difficulty == 'easy') duration = 25;
    if (question.difficulty == 'hard') duration = 45;

    setState(() {
      _timeLeft = duration;
      _totalTime = duration;
      _selectedOption = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _submitAnswer(-1); // Time up! Submit incorrect.
        }
      });
    });
  }

  void _submitAnswer(int index) {
    if (_timer != null) _timer!.cancel();
    
    final provider = context.read<DailyFiveProvider>();
    final auth = context.read<UserProvider>();
    if (auth.currentUser == null) return;

    provider.submitAnswer(userId: auth.currentUser!.uid, optionIndex: index).then((_) {
       if (provider.sessionActive) {
          _startTimerForCurrentQuestion();
       } else if (provider.sessionFinished) {
          _unsecureScreen(); // Quiz over, unsecure
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DailyFiveProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral)),
      );
    }

    if (provider.completedToday || provider.sessionFinished) {
      return _buildCompletionScreen(context, theme, provider);
    }

    if (provider.session == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: const BackButton()),
        body: Center(
           child: Text('No questions available today.', style: GoogleFonts.inter(fontSize: 11)),
        ),
      );
    }

    final session = provider.session!;
    final currentIndex = session.currentIndex;
    final question = session.questions[currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.target, size: 12, color: AppTheme.accentCoral),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Five',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentCoral,
                          ),
                          children: [
                            TextSpan(text: '${currentIndex + 1} '),
                            TextSpan(
                              text: '/ ${session.questions.length}',
                              style: TextStyle(
                                color: AppTheme.accentCoral.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / session.questions.length,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: AppTheme.accentCoral,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    // Timer
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _TimerGaugePainter(
                              progress: _totalTime > 0 ? _timeLeft / _totalTime : 0,
                              color: AppTheme.accentCoral,
                              trackColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_timeLeft',
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentCoral,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'sec',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 12, color: AppTheme.accentCoral),
                          const SizedBox(width: 6),
                          Text(
                            question.topic.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentCoral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Question Text
                    Text(
                      question.questionText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Options
                    ...List.generate(question.options.length, (index) {
                      final optionLetters = ['A', 'B', 'C', 'D', 'E'];
                      return _buildOption(index, optionLetters[index], question.options[index]);
                    }),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Submit Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _selectedOption != null ? () => _submitAnswer(_selectedOption!) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCoral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
              elevation: 0,
            ),
            child: Text(
              'Submit Answer',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int index, String letter, String text) {
    final theme = Theme.of(context);
    final isSelected = _selectedOption == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCoral : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.accentCoral.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.sora(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.accentCoral : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, ThemeData theme, DailyFiveProvider provider) {
    String accuracyStr = '0%';
    int correctCount = 0;
    if (provider.session != null) {
      accuracyStr = '${(provider.session!.accuracyRate * 100).toStringAsFixed(0)}%';
      correctCount = provider.session!.correctCount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F3), // Light warm background
      body: Stack(
        children: [
          // Background Scenery
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/exam/scenaries1.png',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mascot Image
                          Image.asset(
                            'assets/images/exam/5qCompleted1.png',
                            height: 220,
                          ),
                          const SizedBox(height: 32),
                          
                          // Title
                          Text(
                            'Daily Five Completed!',
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            provider.isSubmitting 
                               ? 'Saving your score and updating readiness...'
                               : 'Great job! You\'ve completed your daily questions.',
                            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          
                          // Stats Card
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(LucideIcons.checkCircle, const Color(0xFF65A30D), '$correctCount', 'Correct\nAnswers', theme),
                                Container(height: 50, width: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                                _buildStatColumn(LucideIcons.flame, AppTheme.accentCoral, '+10', 'Pulse\nEarned', theme),
                                Container(height: 50, width: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                                _buildStatColumn(LucideIcons.trendingUp, const Color(0xFF8B5CF6), accuracyStr, 'Accuracy', theme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Consistency Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFCCB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF84CC16).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.trophy, color: Color(0xFF65A30D)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Consistency is your superpower.', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF3F6212))),
                                      const SizedBox(height: 2),
                                      Text('Keep going, keep growing!', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF4D7C0F))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: provider.isSubmitting
                    ? const CircularProgressIndicator(color: AppTheme.accentCoral)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCoral,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Back to Dashboard', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 12),
                            ],
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, Color color, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.sora(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TimerGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _TimerGaugePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
