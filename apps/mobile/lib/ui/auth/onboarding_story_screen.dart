import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';


class OnboardingStoryScreen extends StatefulWidget {
  const OnboardingStoryScreen({super.key});

  @override
  State<OnboardingStoryScreen> createState() => _OnboardingStoryScreenState();
}

class _OnboardingStoryScreenState extends State<OnboardingStoryScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() {
    context.go('/login');
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _StoryPage(
                    titleSpan: const TextSpan(
                      children: [
                        TextSpan(text: 'Built by an\n'),
                        TextSpan(text: 'MX', style: TextStyle(color: AppTheme.accentCoral)),
                        TextSpan(text: ' student,\nfor '),
                        TextSpan(text: 'MX', style: TextStyle(color: AppTheme.accentCoral)),
                        TextSpan(text: ' students.'),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('From our dorm rooms to yours. ', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                        const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 12),
                      ],
                    ),
                    bottomTitle: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCoral,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text('Every feature you need,\nbuilt with love. ', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600, height: 1.4)),
                        const SizedBox(height: 4),
                        const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 16),
                      ],
                    ),
                    imagePath: 'assets/images/onboarding/studying.png',
                  ),
                  _StoryPage(
                    titleSpan: const TextSpan(
                      children: [
                        TextSpan(text: 'One place.\n'),
                        TextSpan(text: 'Everything', style: TextStyle(color: AppTheme.accentCoral)),
                        TextSpan(text: ' that\nmatters.'),
                      ],
                    ),
                    bottomTitle: Column(
                      children: [
                        Text('All your prep, progress and placements.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontWeight: FontWeight.w500, height: 1.4)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Now working together for you. ', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
                            const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 12),
                          ],
                        ),
                      ],
                    ),
                    imagePath: 'assets/images/onboarding/glowing_app.png',
                  ),
                  _StoryPage(
                    titleSpan: const TextSpan(
                      children: [
                        TextSpan(text: 'Your whole batch,\n'),
                        TextSpan(text: 'one app.', style: TextStyle(color: AppTheme.accentCoral)),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 12),
                        const SizedBox(width: 6),
                        Text('Together, we grow.', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    bottomTitle: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.illusGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.illusGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.users, color: AppTheme.illusTerracotta, size: 12),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From first years to final placements,', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                              Row(
                                children: [
                                  Text('we\'re in this together. ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                  const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 12),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    imagePath: 'assets/images/onboarding/student_group1.png',
                  ),
                ],
              ),
            ),
            
            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.accentCoral
                                : AppTheme.illusGold.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.accentCoral,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentCoral.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.arrowRight,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final TextSpan titleSpan;
  final Widget? subtitle;
  final Widget? bottomTitle;
  final String imagePath;

  const _StoryPage({
    required this.titleSpan,
    this.subtitle,
    this.bottomTitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.1,
                letterSpacing: -0.5,
              ),
              children: [titleSpan],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            subtitle!,
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (bottomTitle != null) ...[
            Center(child: bottomTitle!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
