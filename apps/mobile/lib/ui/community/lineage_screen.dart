import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class LineageScreen extends StatefulWidget {
  const LineageScreen({super.key});

  @override
  State<LineageScreen> createState() => _LineageScreenState();
}

class _LineageScreenState extends State<LineageScreen> {
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Map<String, dynamic>? _senior;
  List<Map<String, dynamic>> _requests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait<dynamic>([
        client.rpc('get_my_lineage'),
        client
            .from('lineage_requests')
            .select(
                'id, alumni_id, topic, question, status, created_at, responded_at')
            .eq('student_id', user.uid)
            .order('created_at', ascending: false)
            .limit(30),
      ]);
      final lineage = (results[0] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _senior = lineage.isEmpty ? null : lineage.first;
        _requests = (results[1] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your lineage could not be refreshed.';
      });
    }
  }

  Future<void> _askSenior() async {
    final user = context.read<UserProvider>().currentUser;
    final seniorId = _senior?['senior_user_id']?.toString();
    if (user == null || seniorId == null || _sending) return;

    final topicController = TextEditingController();
    final questionController = TextEditingController();
    final draft = await showModalBottomSheet<({String topic, String question})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SingleChildScrollView(
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
                Text('Ask ${_senior?['senior_name'] ?? 'your senior'}',
                    style: GoogleFonts.sora(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(
                  'A focused question is easier to answer well than a general chat request.',
                  style: GoogleFonts.inter(
                      fontSize: 11, height: 1.4, color: AppTheme.mutedText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: topicController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    hintText: 'System design interviews',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: questionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Your specific question',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final topic = topicController.text.trim();
                      final question = questionController.text.trim();
                      if (topic.length < 2 || question.length < 5) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Add a topic and a fuller question first.')),
                        );
                        return;
                      }
                      Navigator.of(sheetContext)
                          .pop((topic: topic, question: question));
                    },
                    child: const Text('Review and send'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    topicController.dispose();
    questionController.dispose();
    if (draft == null || !mounted) return;

    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('lineage_requests').insert({
        'student_id': user.uid,
        'alumni_id': seniorId,
        'topic': draft.topic,
        'question': draft.question,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question sent to your MX senior.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not send the question. Try again shortly.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openLinkedIn() async {
    final raw = _senior?['senior_linkedin_url']?.toString().trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open LinkedIn.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorshipOpen = _senior?['senior_mentorship_open'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Your MX lineage',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text('One suffix, years of experience.',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedText)),
            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _LineageNotice(message: _error!, onRetry: _load),
            ],
            const SizedBox(height: 18),
            if (!_loading && _senior == null)
              const EmptyState(
                icon: LucideIcons.usersRound,
                title: 'Your lineage is being connected',
                message:
                    'The suffix-based link appears here once your roster identity is confirmed.',
              )
            else if (_senior != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20163D), Color(0xFF5B2A86)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.graduationCap,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_senior?['senior_name']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(
                              _senior?['senior_reg_no']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFFFB899),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    if ([
                      _senior?['senior_current_role_title'],
                      _senior?['senior_current_company']
                    ].any((item) =>
                        item?.toString().trim().isNotEmpty == true)) ...[
                      const SizedBox(height: 14),
                      Text(
                        [
                          _senior?['senior_current_role_title'],
                          _senior?['senior_current_company']
                        ]
                            .where((item) =>
                                item?.toString().trim().isNotEmpty == true)
                            .join(' · '),
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                    if ((_senior?['senior_quote']?.toString().trim() ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Text('“${_senior!['senior_quote']}”',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.5,
                              fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 17),
                    Row(children: [
                      if ((_senior?['senior_linkedin_url']?.toString().trim() ??
                              '')
                          .isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openLinkedIn,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: .35)),
                            ),
                            icon:
                                const Icon(LucideIcons.externalLink, size: 16),
                            label: const Text('LinkedIn'),
                          ),
                        ),
                      if ((_senior?['senior_linkedin_url']?.toString().trim() ??
                              '')
                          .isNotEmpty)
                        const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              mentorshipOpen && !_sending ? _askSenior : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3B2261),
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.messageCircle, size: 16),
                          label: const Text('Ask'),
                        ),
                      ),
                    ]),
                    if (!mentorshipOpen) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Your senior is not accepting new requests right now.',
                        style: GoogleFonts.inter(
                            color: Colors.white60, fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Your questions',
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (_requests.isEmpty)
                const EmptyState(
                  icon: LucideIcons.messageCircleQuestion,
                  title: 'No questions sent yet',
                  message:
                      'Ask about one specific preparation topic when you need a human perspective.',
                )
              else
                ..._requests.map((request) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: PremiumCard(
                        radius: AppRadius.card,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(request['topic']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                              _StatusChip(
                                  status: request['status']?.toString() ??
                                      'pending'),
                            ]),
                            const SizedBox(height: 7),
                            Text(request['question']?.toString() ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    height: 1.45,
                                    color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' => const Color(0xFF16A34A),
      'declined' => const Color(0xFF64748B),
      'redirected' => const Color(0xFF2563EB),
      _ => const Color(0xFFEA580C),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(status,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _LineageNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LineageNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(LucideIcons.wifiOff,
              size: 18, color: AppTheme.accentCoral),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 11))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
