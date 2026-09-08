import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

/// The PRD's real 5-minute calibration (Ch. 3.2, Step 4): a target role
/// family, a per-dimension confidence rating, practice availability, and a
/// short non-graded adaptive sample — replacing the previous 3-question
/// "vibe check" quiz whose score was computed client-side and then thrown
/// away by `completeCalibration` without ever being used.
class CalibrationQuizScreen extends StatefulWidget {
  const CalibrationQuizScreen({super.key});

  @override
  State<CalibrationQuizScreen> createState() => _CalibrationQuizScreenState();
}

const _confidenceDimensions = [
  (
    key: 'aptitude',
    question: 'How confident are you\nin Aptitude & Reasoning?',
    icon: LucideIcons.brain,
  ),
  (
    key: 'coding',
    question: 'How confident are you\nin Coding & Problem Solving?',
    icon: LucideIcons.code2,
  ),
  (
    key: 'core_cs',
    question: 'How confident are you\nin Core Computer Science?',
    icon: LucideIcons.database,
  ),
  (
    key: 'communication',
    question: 'How confident are you\nin Communication & Interviews?',
    icon: LucideIcons.messagesSquare,
  ),
];

const _confidenceOptions = [
  {'title': 'Still learning', 'subtitle': 'This feels new to me'},
  {'title': 'Getting there', 'subtitle': 'I know the basics'},
  {'title': 'Pretty confident', 'subtitle': 'I could teach someone else'},
];

const _roleFamilies = [
  ('product_engineering', 'Product engineering'),
  ('service_engineering', 'Service engineering'),
  ('research', 'Research'),
  ('undecided', "I don't know yet"),
];

const _practiceDayOptions = [2, 4, 6, 7];
const _reminderWindows = [
  ('morning', 'Morning'),
  ('afternoon', 'Afternoon'),
  ('evening', 'Evening'),
];

class _CalibrationQuizScreenState extends State<CalibrationQuizScreen> {
  final PageController _pageController = PageController();
  final _leetcodeCtrl = TextEditingController();
  int _currentStep = 0;
  int? _selectedIndex;

  final Map<String, int> _confidence = {};
  String? _roleFamily;
  int? _practiceDays;
  String? _reminderWindow;

  bool _loadingDiagnostic = true;
  List<Map<String, dynamic>> _diagnosticQuestions = const [];
  final Map<String, int> _diagnosticAnswers = {};

  // Page 0-3: confidence ratings. Page 4: role/schedule/LeetCode. Pages
  // 5..(5+n-1): the real, non-graded adaptive sample.
  int get _infoPageIndex => _confidenceDimensions.length;
  int get _diagnosticStartIndex => _infoPageIndex + 1;
  int get _totalPages => _diagnosticStartIndex + _diagnosticQuestions.length;

  @override
  void initState() {
    super.initState();
    _loadDiagnosticSample();
  }

  Future<void> _loadDiagnosticSample() async {
    try {
      final rows = await Supabase.instance.client
          .from('question_bank')
          .select('id, question_text, options, topic, difficulty')
          .eq('is_active', true)
          .limit(60);
      final all = List<Map<String, dynamic>>.from(rows)..shuffle();
      // Prefer topic variety over duplicates of the same topic.
      final seenTopics = <String>{};
      final picked = <Map<String, dynamic>>[];
      for (final q in all) {
        final topic = q['topic']?.toString() ?? '';
        if (seenTopics.contains(topic) && picked.length < all.length) continue;
        seenTopics.add(topic);
        picked.add(q);
        if (picked.length == 5) break;
      }
      if (picked.length < 5) {
        for (final q in all) {
          if (picked.length == 5) break;
          if (!picked.contains(q)) picked.add(q);
        }
      }
      if (!mounted) return;
      setState(() {
        _diagnosticQuestions = picked;
        _loadingDiagnostic = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDiagnostic = false);
    }
  }

  bool get _canAdvance {
    if (_currentStep < _infoPageIndex) return _selectedIndex != null;
    if (_currentStep == _infoPageIndex) {
      return _roleFamily != null && _practiceDays != null && _reminderWindow != null;
    }
    return true; // diagnostic questions are optional/non-blocking
  }

  void _nextStep() {
    if (!_canAdvance) return;

    if (_currentStep < _infoPageIndex) {
      final dimension = _confidenceDimensions[_currentStep];
      _confidence[dimension.key] = _selectedIndex! + 1; // 1-3 scale
    } else if (_currentStep > _infoPageIndex) {
      final question = _diagnosticQuestions[_currentStep - _diagnosticStartIndex];
      if (_selectedIndex != null) {
        _diagnosticAnswers[question['id'].toString()] = _selectedIndex!;
      }
    }

    if (_currentStep < _totalPages - 1) {
      setState(() => _selectedIndex = null);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/outcome', extra: {
        'confidence': _confidence,
        'roleFamily': _roleFamily,
        'practiceDays': _practiceDays,
        'reminderWindow': _reminderWindow,
        'leetcodeUsername': _leetcodeCtrl.text.trim(),
        'diagnosticAnswered': _diagnosticAnswers.length,
        'diagnosticTotal': _diagnosticQuestions.length,
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _leetcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPages = _totalPages;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, size: 16, color: AppTheme.headingText),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / totalPages,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: AppTheme.illusGold.withValues(alpha: 0.15),
                        color: AppTheme.accentCoral,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.headingText,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(text: 'Let\'s '),
                        TextSpan(text: 'personalize\n', style: TextStyle(color: AppTheme.accentCoral)),
                        TextSpan(text: 'your journey'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A 5-minute calibration to build your starting plan. 🤍',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.headingText.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index < _infoPageIndex) {
                    return _buildConfidenceCard(theme, _confidenceDimensions[index]);
                  } else if (index == _infoPageIndex) {
                    return _buildInfoCard(theme);
                  } else {
                    final q = _diagnosticQuestions[index - _diagnosticStartIndex];
                    return _buildDiagnosticCard(theme, q, index - _diagnosticStartIndex);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canAdvance ? _nextStep : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCoral,
                    disabledBackgroundColor: AppTheme.accentCoral.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == totalPages - 1 ? 'See My Starting Plan' : 'Next',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardShell(String eyebrow, String question, Widget content, {String? mascotLine}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, mascotLine != null ? 80 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(children: [
                Text(eyebrow,
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Text(question,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.headingText, height: 1.3)),
                const SizedBox(height: 24),
                content,
              ]),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -24,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Image.asset('assets/images/onboarding/SmilingMascot.png', width: 110, height: 110, fit: BoxFit.contain),
              if (mascotLine != null) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Text(mascotLine,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.headingText)),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _optionsList(List<({String title, String? subtitle})> options) {
    return Column(children: List.generate(options.length, (idx) {
      final isSelected = _selectedIndex == idx;
      final option = options[idx];
      return GestureDetector(
        onTap: () => setState(() => _selectedIndex = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCoral.withValues(alpha: 0.02) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accentCoral : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.accentCoral : AppTheme.accentCoral.withValues(alpha: 0.05),
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(option.title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.headingText)),
                if (option.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(option.subtitle!, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.headingText.withValues(alpha: 0.5))),
                ],
              ]),
            ),
          ]),
        ),
      );
    }));
  }

  Widget _buildConfidenceCard(ThemeData theme, ({String key, String question, IconData icon}) dimension) {
    return _buildCardShell(
      'Question ${_currentStep + 1} of $_totalPages',
      dimension.question,
      _optionsList(_confidenceOptions.map((o) => (title: o['title']!, subtitle: o['subtitle'])).toList()),
      mascotLine: _selectedIndex != null ? 'Good to know! 🤍' : null,
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Question ${_currentStep + 1} of $_totalPages',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Text('What role are you aiming for,\nand how will you practice?',
                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.headingText, height: 1.3)),
            const SizedBox(height: 20),
            Text('Target role', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.headingText)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _roleFamilies.map((r) {
              final selected = _roleFamily == r.$1;
              return ChoiceChip(
                label: Text(r.$2, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                selected: selected,
                selectedColor: AppTheme.accentCoral.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _roleFamily = r.$1),
              );
            }).toList()),
            const SizedBox(height: 20),
            Text('Days available to practice weekly',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.headingText)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _practiceDayOptions.map((d) {
              final selected = _practiceDays == d;
              return ChoiceChip(
                label: Text('$d days', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                selected: selected,
                selectedColor: AppTheme.accentCoral.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _practiceDays = d),
              );
            }).toList()),
            const SizedBox(height: 20),
            Text('Preferred reminder time',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.headingText)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _reminderWindows.map((w) {
              final selected = _reminderWindow == w.$1;
              return ChoiceChip(
                label: Text(w.$2, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                selected: selected,
                selectedColor: AppTheme.accentCoral.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _reminderWindow = w.$1),
              );
            }).toList()),
            const SizedBox(height: 20),
            Text('LeetCode username (optional — you can add this later too)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.headingText)),
            const SizedBox(height: 8),
            TextField(
              controller: _leetcodeCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. tourist',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard(ThemeData theme, Map<String, dynamic> question, int position) {
    if (_loadingDiagnostic) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral));
    }
    final options = (question['options'] as List? ?? const [])
        .map((o) => (title: o.toString(), subtitle: null as String?))
        .toList();
    return _buildCardShell(
      'Quick sample ${position + 1} of ${_diagnosticQuestions.length} · not graded',
      question['question_text']?.toString() ?? '',
      _optionsList(options),
      mascotLine: _selectedIndex != null ? 'Noted — building your plan.' : null,
    );
  }
}
