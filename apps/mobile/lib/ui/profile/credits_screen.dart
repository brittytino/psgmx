import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('About PSGMX',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF20163D), Color(0xFF613390)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B2A86).withValues(alpha: .2),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/images/mascot.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PSGMX',
                            style: GoogleFonts.sora(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text('Placement preparation, made human.',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Text(
                  'A continuing companion for PSG Tech MCA students — from first foundations to placement-ready proof.',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.55,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
              title: 'Built for every stage',
              subtitle: 'The experience adapts as each batch moves forward.'),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(
              child: _JourneyCard(
                label: '25MX',
                title: 'Senior journey',
                message: 'Turn preparation into verified interview evidence.',
                icon: LucideIcons.briefcaseBusiness,
                color: Color(0xFFFF6547),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _JourneyCard(
                label: '26MX',
                title: 'Junior journey',
                message: 'Build strong daily foundations without the noise.',
                icon: LucideIcons.sprout,
                color: Color(0xFF7C3AED),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          const _SectionTitle(
              title: 'One connected preparation loop',
              subtitle: 'Practice, reflect, and take the next useful step.'),
          const SizedBox(height: 12),
          const _FeatureTile(
            icon: LucideIcons.target,
            title: 'Daily Five',
            message: 'Five targeted questions that reveal where to focus next.',
          ),
          const SizedBox(height: 10),
          const _FeatureTile(
            icon: LucideIcons.bot,
            title: 'AI Senior · Spark',
            message:
                'Personalised online coaching with useful offline guidance.',
          ),
          const SizedBox(height: 10),
          const _FeatureTile(
            icon: LucideIcons.activity,
            title: 'Progress that means something',
            message:
                'Readiness is supported by fresh evidence, not empty points.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD4BF)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.shieldCheck,
                  color: AppTheme.accentCoral, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clear and responsible',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'PSGMX supports preparation. NEO PAT remains the official source for drives, eligibility, shortlists, and offers.',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: const Color(0xFF7C5B4A)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                  : 'Checking…';
              return _InfoRow(
                icon: LucideIcons.badgeInfo,
                label: 'Installed version',
                value: version,
              );
            },
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: LucideIcons.bug,
            label: 'Found a problem?',
            value: 'Report it on GitHub',
            onTap: () => launchUrl(
              Uri.parse('https://github.com/brittytino/psgmx/issues'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 28),
          Text('Built with care for MX students, seniors, and alumni.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedText)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.4, color: AppTheme.mutedText)),
        ],
      );
}

class _JourneyCard extends StatelessWidget {
  final String label;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  const _JourneyCard({
    required this.label,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 188),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(label,
                style: GoogleFonts.sora(
                    fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ]),
          const SizedBox(height: 16),
          Text(title,
              style:
                  GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message,
              style: GoogleFonts.inter(
                  fontSize: 12, height: 1.45, color: AppTheme.mutedText)),
        ]),
      );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _FeatureTile(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.accentCoral, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 12, height: 1.4, color: AppTheme.mutedText)),
            ]),
          ),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: AppTheme.accentCoral),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onTap == null
                          ? AppTheme.mutedText
                          : AppTheme.accentCoral)),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                const Icon(LucideIcons.externalLink,
                    size: 15, color: AppTheme.accentCoral),
              ],
            ]),
          ),
        ),
      );
}
