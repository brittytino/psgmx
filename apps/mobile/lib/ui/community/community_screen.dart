import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/announcement_provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _articles = const [];

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
      final rows = await Supabase.instance.client
          .from('knowledge_brain_articles')
          .select('id, title, summary, tags, batch_year, created_at')
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .limit(5);
      if (!mounted) return;
      setState(() {
        _articles = List<Map<String, dynamic>>.from(rows);
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
                              fontSize: 13, color: const Color(0xFF64748B))),
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
              const SizedBox(height: 24),
              _SectionTitle(
                  title: 'Department inbox',
                  action: 'View all',
                  onTap: () => context.push('/notifications')),
              const SizedBox(height: 10),
              if (announcements.isEmpty && !_loading)
                const _EmptyCard(
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
                                    : const Color(0xFFE8EAF0))),
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
                                      color: const Color(0xFF64748B))),
                            ]),
                      ),
                    )),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'From the Knowledge Brain'),
              const SizedBox(height: 10),
              if (_articles.isEmpty && !_loading)
                const _EmptyCard(
                    icon: LucideIcons.bookOpen,
                    title: 'The next insight is being reviewed',
                    message: 'Only approved department knowledge appears here.')
              else
                ..._articles.map((article) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE8EAF0))),
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
                                              color: const Color(0xFF64748B))),
                                    ]
                                  ])),
                            ]),
                      ),
                    )),
              const SizedBox(height: 18),
              const _EmptyCard(
                  icon: LucideIcons.usersRound,
                  title: 'Your MX lineage',
                  message:
                      'Lineage and topic-based mentoring continue on the PSGMX web companion while mobile messaging is completed.'),
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
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFE8EAF0))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: AppTheme.accentCoral, size: 22),
              const SizedBox(height: 17),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 9, color: const Color(0xFF64748B))),
            ]),
          ),
        ),
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

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyCard(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF0))),
        child: Row(children: [
          Icon(icon, color: AppTheme.accentCoral),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(message,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        height: 1.45,
                        color: const Color(0xFF64748B))),
              ]))
        ]),
      );
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
