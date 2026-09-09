import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/user_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _articles = const [];
  Map<String, dynamic>? _lineage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AnnouncementProvider>()
          .fetchAnnouncements(forceRefresh: true);
      final client = Supabase.instance.client;
      final results = await Future.wait<dynamic>([
        client
            .from('knowledge_brain_articles')
            .select('id, title, summary, tags, batch_year, created_at')
            .eq('approval_status', 'approved')
            .order('created_at', ascending: false)
            .limit(5),
        client.rpc('get_my_lineage'),
      ]);
      if (!mounted) return;
      final lineageRows = List<Map<String, dynamic>>.from(results[1] as List);
      setState(() {
        _articles = List<Map<String, dynamic>>.from(results[0] as List);
        _lineage = lineageRows.isNotEmpty ? lineageRows.first : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Community updates could not be refreshed.';
      });
    }
  }

  Future<void> _openLineageRequestSheet(
      String? seniorId, String seniorName) async {
    if (seniorId == null) return;
    final topicCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask $seniorName',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    'A specific topic and question, not a general chat request.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.mutedText)),
                const SizedBox(height: 16),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. System design interviews'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: questionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Your question', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final topic = topicCtrl.text.trim();
                      final question = questionCtrl.text.trim();
                      if (topic.length < 2 || question.length < 5) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Add a topic and a fuller question first.')));
                        return;
                      }
                      // A student may sign in through either their personal or
                      // college email. Use the logical profile id, not the auth
                      // identity id, for every row owned by the student.
                      final studentId =
                          context.read<UserProvider>().currentUser?.uid;
                      if (studentId == null) return;
                      try {
                        await Supabase.instance.client
                            .from('lineage_requests')
                            .insert({
                          'student_id': studentId,
                          'alumni_id': seniorId,
                          'topic': topic,
                          'question': question,
                        });
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop(true);
                        }
                      } catch (_) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Could not send — try again shortly.')));
                        }
                      }
                    },
                    child: const Text('Send request'),
                  ),
                ),
              ]),
        ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Sent. Your senior will accept, decline, or redirect it.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AnnouncementProvider>().announcements;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Community',
                          style: GoogleFonts.sora(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF17132D))),
                      const SizedBox(height: 5),
                      Text('Learn from MX, then leave it stronger.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.mutedText)),
                    ])),
                IconButton.filledTonal(
                    tooltip: 'Open inbox',
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(LucideIcons.bell, size: 20)),
              ]),
              if (_loading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (_error != null)
                _CommunityNotice(message: _error!, onTap: _load),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                    child: _ActionCard(
                        icon: LucideIcons.messageCircleQuestion,
                        title: 'Ask AI Senior',
                        subtitle: 'Source-grounded guidance',
                        onTap: () => context.push('/ai-mentor'))),
                const SizedBox(width: 10),
                Expanded(
                    child: _ActionCard(
                        icon: LucideIcons.libraryBig,
                        title: 'Interview patterns',
                        subtitle: 'Reusable alumni insight',
                        onTap: () => context.push('/interview-patterns'))),
              ]),
              const SizedBox(height: 10),
              _ActionCard(
                  icon: LucideIcons.usersRound,
                  title: 'Your squad',
                  subtitle: 'See your teammates\' streaks and verified quests',
                  onTap: () => context.push('/community/squads')),
              const SizedBox(height: 10),
              _ActionCard(
                  icon: LucideIcons.messageSquarePlus,
                  title: 'Community Board',
                  subtitle: 'Projects, opportunities and mentoring offers',
                  onTap: () => context.push('/community/board')),
              const SizedBox(height: 24),
              _SectionTitle(
                  title: 'Department inbox',
                  action: 'View all',
                  onTap: () => context.push('/notifications')),
              const SizedBox(height: 10),
              if (announcements.isEmpty && !_loading)
                const EmptyState(
                    icon: LucideIcons.circleCheck,
                    title: 'You are up to date',
                    message: 'Important department updates will appear here.')
              else
                ...announcements.take(3).map((announcement) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: announcement.isPriority
                                ? const Color(0xFFFFF4ED)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: announcement.isPriority
                                    ? const Color(0xFFFFD4BF)
                                    : AppTheme.cardBorder)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(announcement.title,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(announcement.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      height: 1.45,
                                      color: AppTheme.mutedText)),
                            ]),
                      ),
                    )),
              const SizedBox(height: 22),
              _SectionTitle(
                  title: 'From the Knowledge Brain',
                  action: 'Explore',
                  onTap: () => context.push('/community/knowledge-brain')),
              const SizedBox(height: 10),
              if (_articles.isEmpty && !_loading)
                const EmptyState(
                    icon: LucideIcons.bookOpen,
                    title: 'The next insight is being reviewed',
                    message: 'Only approved department knowledge appears here.')
              else
                ..._articles.map((article) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: PremiumCard(
                        onTap: () => context.push('/community/knowledge-brain'),
                        radius: AppRadius.card,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppTheme.accentCoral
                                          .withValues(alpha: .09),
                                      borderRadius: BorderRadius.circular(11)),
                                  child: const Icon(LucideIcons.bookOpen,
                                      size: 18, color: AppTheme.accentCoral)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(article['title']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800)),
                                    if (article['summary'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(article['summary'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              height: 1.45,
                                              color: AppTheme.mutedText)),
                                    ]
                                  ])),
                            ]),
                      ),
                    )),
              const SizedBox(height: 22),
              _SectionTitle(
                  title: 'Your MX lineage',
                  action: 'Open',
                  onTap: () => context.push('/community/lineage')),
              const SizedBox(height: 10),
              if (_lineage == null && !_loading)
                const EmptyState(
                    icon: LucideIcons.usersRound,
                    title: 'No senior assigned yet',
                    message:
                        'Your department mentor pairs each junior with a senior. Check back once yours is assigned.')
              else if (_lineage != null)
                PremiumCard(
                  onTap: () => context.push('/community/lineage'),
                  radius: AppRadius.card,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color:
                                    AppTheme.accentCoral.withValues(alpha: .09),
                                shape: BoxShape.circle),
                            child: const Icon(LucideIcons.usersRound,
                                size: 20, color: AppTheme.accentCoral)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  _lineage!['senior_name']?.toString() ??
                                      'Your senior',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              if ((_lineage!['senior_current_company']
                                              as String?)
                                          ?.isNotEmpty ==
                                      true ||
                                  (_lineage!['senior_current_role_title']
                                              as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                const SizedBox(height: 2),
                                Text(
                                    [
                                      _lineage!['senior_current_role_title'],
                                      _lineage!['senior_current_company']
                                    ]
                                        .where((v) =>
                                            (v as String?)?.isNotEmpty == true)
                                        .join(' · '),
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppTheme.mutedText)),
                              ],
                              if ((_lineage!['senior_quote'] as String?)
                                      ?.trim()
                                      .isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Text('"${_lineage!['senior_quote']}"',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        height: 1.45,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF334155))),
                              ],
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => _openLineageRequestSheet(
                                      _lineage!['senior_user_id']?.toString(),
                                      _lineage!['senior_name']?.toString() ??
                                          'your senior'),
                                  icon: const Icon(LucideIcons.messageCircle,
                                      size: 14),
                                  label: const Text('Ask a specific question'),
                                ),
                              ),
                            ])),
                      ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => PremiumCard(
        onTap: onTap,
        radius: AppRadius.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.accentCoral, size: 22),
          const SizedBox(height: 17),
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 9, color: AppTheme.mutedText)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const _SectionTitle({required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: GoogleFonts.sora(
                    fontSize: 17, fontWeight: FontWeight.w800))),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ]);
}

class _CommunityNotice extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _CommunityNotice({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF4ED),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(LucideIcons.wifiOff,
              size: 18, color: AppTheme.accentCoral),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 11))),
          TextButton(onPressed: onTap, child: const Text('Retry')),
        ]),
      );
}
