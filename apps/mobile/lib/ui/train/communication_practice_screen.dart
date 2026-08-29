import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class CommunicationPracticeScreen extends StatefulWidget {
  const CommunicationPracticeScreen({super.key});

  @override
  State<CommunicationPracticeScreen> createState() => _CommunicationPracticeScreenState();
}

class _CommunicationPracticeScreenState extends State<CommunicationPracticeScreen> {
  bool _isRecording = false;
  bool _isRecorded = false;
  bool _isEvaluating = false;
  int _seconds = 0;
  Timer? _timer;
  Map<String, dynamic>? _evaluation;

  final String _prompt =
      "Tell me about a time you faced a technical challenge in a team project and how you resolved it.";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isRecorded = false;
      _seconds = 0;
      _evaluation = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds >= 120) {
        _stopRecording();
      } else {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isRecorded = true;
    });
  }

  void _evaluateAudio() async {
    setState(() {
      _isEvaluating = true;
    });

    // Simulate STT + OpenRouter evaluation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _evaluation = {
          'clarity_score': 8,
          'structure_score': 7,
          'filler_word_count': 2,
          'relevance_score': 9,
          'brief_feedback':
              'Well-structured answer following the STAR methodology. You clearly identified the database query latency issue and described adding index caching.',
          'suggested_improvement':
              'Try to reduce filler pauses and quantify the exact throughput gain achieved.',
        };
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Communication Practice',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic, color: AppTheme.primaryPurple, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'PRACTICE PROMPT · AUDIO ONLY (MAX 2M)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _prompt,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recording Controls Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  // Timer
                  Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _isRecording ? Colors.red : AppTheme.textMain,
                    ),
                  ),
                  const Text(
                    '/ 02:00 MAX',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),

                  const SizedBox(height: 32),

                  // Mic Button
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : AppTheme.primaryPurple,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : AppTheme.primaryPurple).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    _isRecording
                        ? 'Tap to finish recording'
                        : _isRecorded
                            ? 'Recording ready for evaluation'
                            : 'Tap mic to start speaking',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),

                  if (_isRecorded && _evaluation == null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isEvaluating ? null : _evaluateAudio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isEvaluating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Evaluate with AI Senior',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Evaluation Feedback Display
            if (_evaluation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Evaluation Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricTile('Clarity', '${_evaluation!['clarity_score']}/10', Colors.purple),
                        _buildMetricTile('Structure', '${_evaluation!['structure_score']}/10', Colors.indigo),
                        _buildMetricTile('Fillers', '${_evaluation!['filler_word_count']}', Colors.amber.shade800),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _evaluation!['brief_feedback'],
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMain, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tip: ${_evaluation!['suggested_improvement']}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
      ],
    );
  }
}
