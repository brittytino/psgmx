import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 80.0, bottom: 48.0),
        child: Column(
          children: [
            const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 16),
            const SizedBox(height: 24),
            Text(
              'Thanks for being\npart of the journey.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'PSGMX was born from a simple belief —\nthat every student deserves clarity, support,\nand the right opportunities to grow.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.6),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Built by someone who\'s been there.\nFor students, by students.\nTo make placements less stressful\nand a little more human.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.6),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Here\'s to your journey ahead.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You\'ve got this!',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 16),
              ],
            ),
            const SizedBox(height: 24),
            
            Text(
              'Build v2.4.1  •  18 May 2024',
              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 48),
            
            // Mascot & Signature
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/mascot.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: AppTheme.accentCoral, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.flame, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'built by Tino <3',
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            
            // Contribution Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F5), // Light coral tint
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'You can also contribute to this app',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Found a bug? Have an idea? Help make PSGMX better for everyone.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  
                  // GitHub Button
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.code, size: 16),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Click me on GitHub', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                            Text('and give your pull request', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Contributors
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Top Contributors',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildContributorItem('Rohan Mehta', '@rohanmehta', '15+ PRs', theme),
                        Divider(height: 1, indent: 64, color: theme.dividerColor.withValues(alpha: 0.1)),
                        _buildContributorItem('Ananya Singh', '@ananyasingh', '8+ PRs', theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('and many more amazing people ', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                      const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Made with ', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                const Icon(Icons.favorite, color: AppTheme.accentCoral, size: 12),
                Text(' for dreamers and doers.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(height: 6),
            Text('Keep pushing. We\'re cheering for you!', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorItem(String name, String handle, String prs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(LucideIcons.user, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Text(handle, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
            ),
            child: Text(prs, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
          ),
        ],
      ),
    );
  }
}
