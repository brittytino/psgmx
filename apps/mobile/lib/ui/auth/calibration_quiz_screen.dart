 import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

class CalibrationQuizScreen extends StatefulWidget {
  const CalibrationQuizScreen({super.key});

  @override
  State<CalibrationQuizScreen> createState() => _CalibrationQuizScreenState();
}

class _CalibrationQuizScreenState extends State<CalibrationQuizScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int? _selectedIndex;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How many DSA problems\nhave you solved so far?',
      'icon': LucideIcons.code2,
      'options': [
        {'title': '0 – 50', 'subtitle': 'Just getting started'},
        {'title': '51 – 200', 'subtitle': 'Learning and building'},
        {'title': '201 – 500', 'subtitle': 'Consistent problem solver'},
        {'title': '500+', 'subtitle': 'Love the challenge!'},
      ],
      'reaction': 'Nice! You\'re on\na great path! 🤍',
    },
    {
      'question': 'How consistent are you\nwith classes?',
      'icon': LucideIcons.calendarDays,
      'options': [
        {'title': 'Struggling', 'subtitle': 'Less than 75%'},
        {'title': 'Around 75%', 'subtitle': 'Just enough to pass'},
        {'title': 'Mostly regular', 'subtitle': '80% - 90%'},
        {'title': 'Never miss a day', 'subtitle': '90%+ attendance'},
      ],
      'reaction': 'Consistency is key! ⚡',
    },
    {
      'question': 'Have you built any\npersonal projects?',
      'icon': LucideIcons.laptop,
      'options': [
        {'title': 'Not yet', 'subtitle': 'Planning to start soon'},
        {'title': 'Following tutorials', 'subtitle': 'Learning the basics'},
        {'title': 'Built 1-2 projects', 'subtitle': 'Independent builder'},
        {'title': 'Solid portfolio', 'subtitle': 'Ready for placements'},
      ],
      'reaction': 'Building is learning! 🚀',
    },
  ];

  int _scoreAccumulator = 0;

  void _nextQuestion() {
    if (_selectedIndex == null) return;
    
    _scoreAccumulator += (_selectedIndex! * 15);

    if (_currentStep < _questions.length - 1) {
      setState(() {
        _selectedIndex = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final finalScore = 20 + (_scoreAccumulator / _questions.length).round();
      context.go('/outcome', extra: finalScore);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      icon: const Icon(LucideIcons.arrowLeft, size: 16, color: Color(0xFF1E293B)),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 16,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _currentStep 
                              ? AppTheme.accentCoral 
                              : AppTheme.illusGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            
            // Headline & Subtitle
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Decorative sparks
                Positioned(top: 0, left: 24, child: Icon(LucideIcons.sparkles, color: AppTheme.illusGold.withValues(alpha: 0.5), size: 16)),
                Positioned(top: 10, right: 24, child: Transform.rotate(angle: 0.5, child: Icon(LucideIcons.sparkles, color: AppTheme.illusGold.withValues(alpha: 0.5), size: 16))),
                
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
                            color: const Color(0xFF1E293B),
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
                        'Just 3 quick questions to get your\nstarting readiness score right. 🤍',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Question Card PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Force using buttons
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(theme, _questions[index]);
                },
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedIndex != null ? _nextQuestion : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        disabledBackgroundColor: AppTheme.accentCoral.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _questions.length - 1 ? 'See Results' : 'Next Question',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Press Enter ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(LucideIcons.cornerDownLeft, size: 12, color: const Color(0xFF1E293B).withValues(alpha: 0.4)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, Map<String, dynamic> q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // White Card
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 80), // bottom padding for mascot
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Illustration Graphic
                  _buildGraphic(q['icon']),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Question ${_currentStep + 1} of 3',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCoral,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    q['question'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Options
                  ...List.generate(
                    (q['options'] as List).length,
                    (idx) {
                      final option = q['options'][idx];
                      final isSelected = _selectedIndex == idx;
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedIndex = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentCoral.withValues(alpha: 0.02) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: AppTheme.accentCoral.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Row(
                                children: [
                                  // Custom Radio
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppTheme.accentCoral : AppTheme.accentCoral.withValues(alpha: 0.05),
                                    ),
                                    child: isSelected 
                                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                                      : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['title'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          option['subtitle'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Selected Sparks
                          if (isSelected)
                            Positioned(
                              right: -20,
                              top: 20,
                              child: Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 16),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Mascot Overlapping Bottom Left
          Positioned(
            left: -16,
            bottom: -24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/onboarding/SmilingMascot.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                if (_selectedIndex != null) ...[
                  // Speech Bubble
                  Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4), // tail effect
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      q['reaction'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphic(IconData icon) {
    // Custom drawn graphic resembling the code window from the screenshot
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Background leaves
        Positioned(
          left: -20,
          top: 10,
          child: Transform.rotate(
            angle: -0.5,
            child: Icon(LucideIcons.leaf, color: AppTheme.illusSage.withValues(alpha: 0.3), size: 16),
          ),
        ),
        Positioned(
          right: -15,
          bottom: 10,
          child: Transform.rotate(
            angle: 0.8,
            child: Icon(LucideIcons.leaf, color: AppTheme.illusGold.withValues(alpha: 0.3), size: 16),
          ),
        ),
        Positioned(
          right: -5,
          top: -10,
          child: Icon(LucideIcons.sparkles, color: AppTheme.accentCoral, size: 16),
        ),
        
        // Code Window
        Transform.rotate(
          angle: -0.05,
          child: Container(
            width: 110,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF2E3239),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.accentCoral,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ),
                // Icon content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

