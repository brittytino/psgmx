import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/premium_card.dart';

class BatchConfirmationScreen extends StatefulWidget {
  const BatchConfirmationScreen({super.key});

  @override
  State<BatchConfirmationScreen> createState() => _BatchConfirmationScreenState();
}

class _BatchConfirmationScreenState extends State<BatchConfirmationScreen> {
  Future<void> _flagCorrection(BuildContext context) async {
    final controller = TextEditingController();
    final context0 = context;
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Flag a correction', style: GoogleFonts.sora(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What looks wrong about your name, register number, or batch?',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.headingText.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Describe the issue...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty || !context0.mounted) return;

    final user = context0.read<UserProvider>().currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('support_cases').insert({
        'student_id': user.uid,
        'created_by': user.uid,
        'case_type': 'identity',
        'title': 'Identity correction requested',
        'context': note,
      });
      if (!context0.mounted) return;
      ScaffoldMessenger.of(context0).showSnackBar(
        const SnackBar(content: Text('Sent to your department for review.')),
      );
    } catch (_) {
      if (!context0.mounted) return;
      ScaffoldMessenger.of(context0).showSnackBar(
        const SnackBar(content: Text('Could not submit right now — try again shortly.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>().currentUser;
    final batchMatch = RegExp(r'^(\d{2}MX)').firstMatch(user?.regNo ?? '');
    final batchCode = batchMatch?.group(1) ?? user?.batch ?? 'MCA';
    final yearPrefix = RegExp(r'^(\d{2})MX$').firstMatch(batchCode)?.group(1);
    final startYear = yearPrefix == null ? null : int.tryParse('20$yearPrefix');
    final classYears = startYear == null
        ? 'Your MCA batch'
        : 'Batch of $startYear–${startYear + 2}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Mascot and confetti
                    Image.asset(
                      'assets/images/onboarding/JumpingMascot.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    // Welcome Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.heart,
                            color: AppTheme.accentCoral, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome to the crew!',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Headline
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          const TextSpan(text: 'You\'re in '),
                          TextSpan(
                              text: batchCode,
                              style:
                                  const TextStyle(color: AppTheme.accentCoral)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Batch Subtitle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.leaf,
                            color: AppTheme.illusSage, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          classYears,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.leaf,
                            color: AppTheme.illusSage, size: 16),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.illusGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.graduationCap,
                              color: AppTheme.illusTerracotta, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            'A new journey. Together.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Central Illustration
                    Image.asset(
                      'assets/images/onboarding/student_group2.png',
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 32),

                    // Bottom Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.illusGold.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.illusGold.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentCoral.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.users2,
                                color: AppTheme.accentCoral),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You\'re now part of the $batchCode family.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Let\'s make these years unforgettable!',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: theme
                                              .textTheme.bodyMedium?.color
                                              ?.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    const Icon(LucideIcons.heart,
                                        color: AppTheme.accentCoral, size: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Identity confirmation — PRD Ch. 3.2 Step 3: the
                    // student sees their name/reg no/batch/stage and can
                    // flag a correction, but never self-edits them directly.
                    PremiumCard(
                      radius: AppRadius.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Confirm your details',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppTheme.textMuted)),
                          const SizedBox(height: 10),
                          _DetailRow(label: 'Name', value: user?.name ?? '—'),
                          _DetailRow(label: 'Register number', value: user?.regNo ?? '—'),
                          _DetailRow(label: 'Batch', value: batchCode),
                          _DetailRow(
                              label: 'Stage',
                              value: user?.isActiveSenior == true ? 'Senior' : 'Junior'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _flagCorrection(context),
                              icon: const Icon(LucideIcons.flag, size: 14),
                              label: const Text('Something wrong? Flag a correction'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/calibration'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Let\'s Go!',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: index == 3
                              ? AppTheme.accentCoral
                              : AppTheme.illusGold.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted))),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain))),
          ],
        ),
      );
}
