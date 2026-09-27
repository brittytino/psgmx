import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/update_service.dart';
import '../../models/release_note.dart';

/// What's New Screen
///
/// Shown automatically on first launch after an app update.
/// Content is fetched from [app_release_notes] Supabase table.
/// Dismissed by tapping "Let's Go" — persists current version to prefs.
class WhatsNewScreen extends StatefulWidget {
  /// Called when user dismisses the screen
  final VoidCallback onDismiss;

  const WhatsNewScreen({super.key, required this.onDismiss});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Stagger the entrance
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    final svc = context.read<UpdateService>();
    await svc.dismissWhatsNew();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<UpdateService>();
    final notes = svc.pendingReleaseNotes;
    final version = svc.currentVersion ?? '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg1 = isDark ? const Color(0xFF070D1A) : const Color(0xFFF4F8FF);
    final bg2 = isDark ? const Color(0xFF0D1829) : const Color(0xFFE8F0FF);
    final surface = isDark ? const Color(0xFF111D33) : Colors.white;
    final border = isDark ? const Color(0xFF253959) : const Color(0xFFD0DFF8);
    final titleColor = isDark ? Colors.white : const Color(0xFF0B1F40);
    final subtitleColor =
        isDark ? const Color(0xFF8CAAD4) : const Color(0xFF4B6B9A);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bg1, bg2],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth =
                        math.min(560.0, constraints.maxWidth - 32.0);

                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            children: [
                              // ── Header ────────────────────────────────
                              _HeaderSection(
                                version: version,
                                isDark: isDark,
                                titleColor: titleColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 20),

                              // ── Release Notes ─────────────────────────
                              if (notes.isNotEmpty)
                                ...notes.map((note) => _ReleaseNoteCard(
                                      note: note,
                                      surface: surface,
                                      border: border,
                                      isDark: isDark,
                                    ))
                              else
                                _EmptyNotesCard(
                                  surface: surface,
                                  border: border,
                                  isDark: isDark,
                                  version: version,
                                ),

                              const SizedBox(height: 24),

                              // ── CTA ───────────────────────────────────
                              _CtaButton(onTap: _handleDismiss),

                              const SizedBox(height: 12),

                              Text(
                                'PSGMX v$version',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: subtitleColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final String version;
  final bool isDark;
  final Color titleColor;
  final Color subtitleColor;

  const _HeaderSection({
    required this.version,
    required this.isDark,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 12, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'JUST UPDATED',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Emoji icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E2D50), const Color(0xFF162340)]
                  : [const Color(0xFFEEF3FF), const Color(0xFFDDE8FF)],
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A4070)
                  : const Color(0xFFBDD0FF),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Text('🎉', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          "What's New",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: titleColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Here's what changed in v$version",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}

class _ReleaseNoteCard extends StatelessWidget {
  final ReleaseNote note;
  final Color surface;
  final Color border;
  final bool isDark;

  const _ReleaseNoteCard({
    required this.note,
    required this.surface,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        isDark ? const Color(0xFF8CAAD4) : const Color(0xFF4B6B9A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version badge + title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            const Color(0xFF6366F1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'v${note.version}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0B1F40),
                      ),
                    ),
                  ),
                ],
              ),

              if (note.description != null &&
                  note.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.description!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.55,
                    color: subtitleColor,
                  ),
                ),
              ],

              if (note.highlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...note.highlights.map(
                  (h) => _HighlightRow(text: h, isDark: isDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String text;
  final bool isDark;

  const _HighlightRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: isDark
                    ? const Color(0xFFCDD8EE)
                    : const Color(0xFF1E3358),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotesCard extends StatelessWidget {
  final Color surface;
  final Color border;
  final bool isDark;
  final String version;

  const _EmptyNotesCard({
    required this.surface,
    required this.border,
    required this.isDark,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'v$version is here!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0B1F40),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bug fixes, performance improvements, and under-the-hood enhancements.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.55,
              color: isDark
                  ? const Color(0xFF8CAAD4)
                  : const Color(0xFF4B6B9A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
          label: Text(
            "Let's Go!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
