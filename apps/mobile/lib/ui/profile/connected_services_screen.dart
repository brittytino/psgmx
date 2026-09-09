import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/premium_card.dart';

class ConnectedServicesScreen extends StatefulWidget {
  const ConnectedServicesScreen({super.key});

  @override
  State<ConnectedServicesScreen> createState() =>
      _ConnectedServicesScreenState();
}

class _ConnectedServicesScreenState extends State<ConnectedServicesScreen> {
  bool _savingLeetCode = false;
  bool _savingGitHub = false;

  Future<void> _editLeetCode() async {
    final provider = context.read<UserProvider>();
    final value = await _showEditor(
      title: 'Connect LeetCode',
      description:
          'Your public activity becomes readiness evidence after PSGMX syncs it.',
      label: 'Username or profile URL',
      initialValue: provider.currentUser?.leetcodeUsername ?? '',
      hint: 'leetcode.com/u/your-name',
    );
    if (value == null || !mounted) return;
    setState(() => _savingLeetCode = true);
    try {
      await provider.updateLeetCodeUsername(value);
      if (mounted) _showSaved('LeetCode connected.');
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _savingLeetCode = false);
    }
  }

  Future<void> _editGitHub() async {
    final provider = context.read<UserProvider>();
    final value = await _showEditor(
      title: 'Connect GitHub',
      description:
          'Link your public developer profile so verified project evidence has a clear source.',
      label: 'Username or profile URL',
      initialValue: provider.currentUser?.githubUrl ?? '',
      hint: 'github.com/your-name',
    );
    if (value == null || !mounted) return;
    setState(() => _savingGitHub = true);
    try {
      await provider.updateGitHubUrl(value);
      if (mounted) _showSaved('GitHub connected.');
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _savingGitHub = false);
    }
  }

  Future<String?> _showEditor({
    required String title,
    required String description,
    required String label,
    required String initialValue,
    required String hint,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: GoogleFonts.sora(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(description,
                  style: GoogleFonts.inter(
                      fontSize: 11, height: 1.45, color: AppTheme.mutedText)),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: label, hintText: hint),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    Navigator.of(sheetContext).pop(text.trim());
                  }
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Enter a profile first.')),
                      );
                      return;
                    }
                    Navigator.of(sheetContext).pop(text);
                  },
                  child: const Text('Save connection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _open(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this profile.')),
      );
    }
  }

  void _showSaved(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  void _showError(Object error) {
    final message = error
        .toString()
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final leetCode = user?.leetcodeUsername?.trim() ?? '';
    final github = user?.githubUrl?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Connected services',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          Text(
            'You control what is linked. Only verified outcomes influence readiness.',
            style: GoogleFonts.inter(
                fontSize: 12, height: 1.5, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 18),
          _ServiceCard(
            icon: LucideIcons.code2,
            color: const Color(0xFFEA580C),
            title: 'LeetCode',
            value: leetCode.isEmpty ? 'Not connected' : leetCode,
            description: 'Problem-solving activity and consistency signals.',
            connected: leetCode.isNotEmpty,
            saving: _savingLeetCode,
            onEdit: _editLeetCode,
            onOpen: leetCode.isEmpty
                ? null
                : () => _open('https://leetcode.com/u/$leetCode'),
          ),
          const SizedBox(height: 12),
          _ServiceCard(
            icon: LucideIcons.gitFork,
            color: const Color(0xFF334155),
            title: 'GitHub',
            value: github.isEmpty
                ? 'Not connected'
                : github.split('/').where((part) => part.isNotEmpty).last,
            description: 'Public profile for project and portfolio evidence.',
            connected: github.isNotEmpty,
            saving: _savingGitHub,
            onEdit: _editGitHub,
            onOpen: github.isEmpty ? null : () => _open(github),
          ),
          const SizedBox(height: 18),
          PremiumCard(
            radius: AppRadius.card,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.shieldCheck,
                    size: 20, color: Color(0xFF16A34A)),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'A connection is never counted as achievement by itself. PSGMX uses synced, verified evidence and always shows the source.',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.5,
                        color: const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String description;
  final bool connected;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback? onOpen;

  const _ServiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.description,
    required this.connected,
    required this.saving,
    required this.onEdit,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) => PremiumCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: connected
                                ? const Color(0xFF16A34A)
                                : AppTheme.mutedText)),
                  ],
                ),
              ),
              if (connected)
                const Icon(LucideIcons.circleCheck,
                    size: 20, color: Color(0xFF16A34A)),
            ]),
            const SizedBox(height: 13),
            Text(description,
                style: GoogleFonts.inter(
                    fontSize: 11, height: 1.45, color: AppTheme.mutedText)),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onEdit,
                  child: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(connected ? 'Change' : 'Connect'),
                ),
              ),
              if (onOpen != null) ...[
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(LucideIcons.externalLink, size: 15),
                    label: const Text('View profile'),
                  ),
                ),
              ],
            ]),
          ],
        ),
      );
}
