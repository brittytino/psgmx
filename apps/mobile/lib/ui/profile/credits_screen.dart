import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
            
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => Text(
                snapshot.hasData
                    ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : 'Checking installed version…',
                style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              ),
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
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://github.com/brittytino/psgmx/issues'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.code, size: 16),
                    label: const Text('Report an issue on GitHub'),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Contributions are reviewed in the public repository so fixes remain traceable and safe for future MX batches.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 9, height: 1.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65)),
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

}
