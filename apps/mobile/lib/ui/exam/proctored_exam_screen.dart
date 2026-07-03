import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import 'dart:async';

class ProctoredExamScreen extends StatefulWidget {
  const ProctoredExamScreen({super.key});

  @override
  State<ProctoredExamScreen> createState() => _ProctoredExamScreenState();
}

class _ProctoredExamScreenState extends State<ProctoredExamScreen> with WidgetsBindingObserver {
  int _violationCount = 0;
  bool _isTerminated = false;
  final int _maxViolations = 3;
  Timer? _examTimer;
  int _secondsRemaining = 3600; // 1 hour exam

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Hide status bar and navigation bar for immersive proctoring mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startTimer();
  }

  void _startTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _submitExam();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _examTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isTerminated) return;

    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.hidden) {
      _recordViolation();
    }
  }

  void _recordViolation() {
    setState(() {
      _violationCount++;
      if (_violationCount >= _maxViolations) {
        _isTerminated = true;
        _examTimer?.cancel();
        _showTerminationDialog();
      } else {
        _showWarningDialog();
      }
    });
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red),
            const SizedBox(width: 8),
            Text('Proctoring Warning', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You left the exam screen. This is violation $_violationCount of $_maxViolations.\n\nFurther violations will result in automatic termination of your exam.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showTerminationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.shieldAlert, color: Colors.red),
            const SizedBox(width: 8),
            Text('Exam Terminated', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your exam has been terminated due to multiple proctoring violations.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit Exam'),
          ),
        ],
      ),
    );
  }

  void _submitExam() {
    // Logic to submit exam
    _examTimer?.cancel();
    context.go('/');
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isTerminated) {
      return Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shieldAlert, size: 16, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Exam Terminated',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                'Multiple proctoring violations detected.',
                style: GoogleFonts.inter(color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.radio, color: Colors.red, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    'PROCTORED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, color: AppTheme.accentCoral, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCoral,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _submitExam,
              icon: const Icon(LucideIcons.checkCircle, size: 12),
              label: const Text('Finish'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentCoral,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question 1 of 50',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentCoral,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Explain the difference between a process and a thread in operating systems.',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              // Dummy options
              _buildOption('A', 'A process has its own memory space, while threads share memory within a process.'),
              _buildOption('B', 'A thread is heavier than a process.'),
              _buildOption('C', 'Processes share memory, threads do not.'),
              _buildOption('D', 'There is no difference between them.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String letter, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
