import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

/// PRD Ch. 14.3 — Community Board: project collaboration, open-source
/// opportunities, alumni-hosted events, career info sessions, mentoring
/// circles. Posts are visible immediately and can be hidden by a faculty/
/// HOD/PR moderator (see migration 48 for why this is post-hoc, not a
/// pre-publish queue). Backed by the real `collaboration_posts` table that
/// already existed but had no mobile UI and no student-facing web route.
class CommunityBoardScreen extends StatefulWidget {
  const CommunityBoardScreen({super.key});

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

// Matches the real post_type CHECK constraint (migrations 04 + 21) and the
// same 5 user-facing categories apps/web/app/alumni/marketplace/page.tsx
// offers — 'job' still exists in the DB as a legacy value but isn't offered
// as a choice on either surface, `unofficial_opportunity` replaced it.
const _postTypes = [
  ('project', 'Project', LucideIcons.folderKanban),
  ('mentorship', 'Mentorship', LucideIcons.handshake),
  ('learning_event', 'Learning event', LucideIcons.calendarDays),
  ('career_information', 'Career info', LucideIcons.briefcase),
  ('unofficial_opportunity', 'Opportunity', LucideIcons.sparkles),
];

class _CommunityBoardScreenState extends State<CommunityBoardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];
  String? _filterType;

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
      final rows = await Supabase.instance.client
          .from('collaboration_posts')
          .select(
              'id, post_type, title, description, visibility, posted_by, created_at, poster:posted_by(name)')
          .order('created_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Community Board could not be refreshed.';
      });
    }
  }

  Future<void> _hidePost(String postId) async {
    try {
      await Supabase.instance.client.rpc('moderate_collaboration_post',
          params: {'p_post_id': postId, 'p_hide': true});
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p['id'] == postId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post hidden.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not hide: $e')));
    }
  }

  Future<void> _openComposeSheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String postType = 'project';
    String visibility = 'batch';
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
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
                  Text('New post',
                      style: GoogleFonts.sora(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      'Project collaboration, an opportunity, or a mentoring offer — not an official drive.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.mutedText)),
                  const SizedBox(height: 16),
                  Wrap(
                      spacing: 8,
                      children: _postTypes
                          .map((t) => ChoiceChip(
                                label: Text(t.$2),
                                selected: postType == t.$1,
                                onSelected: (_) =>
                                    setSheetState(() => postType = t.$1),
                              ))
                          .toList()),
                  const SizedBox(height: 12),
                  TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Title', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: visibility,
                    decoration: const InputDecoration(
                        labelText: 'Visible to', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'batch', child: Text('My batch')),
                      DropdownMenuItem(
                          value: 'department', child: Text('Whole department')),
                      DropdownMenuItem(
                          value: 'lineage_only',
                          child: Text('My lineage only')),
                    ],
                    onChanged: (v) =>
                        setSheetState(() => visibility = v ?? visibility),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().length < 3 ||
                            descCtrl.text.trim().length < 10) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Add a fuller title and description first.')));
                          return;
                        }
                        final userId =
                            context.read<UserProvider>().currentUser?.uid;
                        if (userId == null) return;
                        try {
                          await Supabase.instance.client
                              .from('collaboration_posts')
                              .insert({
                            'post_type': postType,
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'visibility': visibility,
                            'posted_by': userId,
                          });
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text('Could not post: $e')));
                          }
                        }
                      },
                      child: const Text('Post to Community Board'),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
    if (posted == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final canModerate = user != null &&
        (user.roleLabel == 'Faculty' ||
            user.roleLabel == 'HOD' ||
            user.isPlacementRep);
    final filtered = _filterType == null
        ? _posts
        : _posts
            .where((p) =>
                (p['post_type'] == 'job'
                    ? 'unofficial_opportunity'
                    : p['post_type']) ==
                _filterType)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Community Board',
            style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposeSheet,
        icon: const Icon(LucideIcons.plus),
        label: const Text('New post'),
        backgroundColor: AppTheme.accentCoral,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentCoral))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                children: [
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                        label: const Text('All'),
                        selected: _filterType == null,
                        onSelected: (_) => setState(() => _filterType = null)),
                    ..._postTypes.map((t) => ChoiceChip(
                          label: Text(t.$2),
                          selected: _filterType == t.$1,
                          onSelected: (_) => setState(() => _filterType = t.$1),
                        )),
                  ]),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Icon(LucideIcons.wifiOff,
                              size: 18, color: AppTheme.accentCoral),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.inter(fontSize: 11))),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ]),
                      ),
                    ),
                  if (filtered.isEmpty && _error == null)
                    const EmptyState(
                      icon: LucideIcons.messageSquarePlus,
                      title: 'Nothing posted yet',
                      message:
                          'Share a project, an opportunity, or offer mentorship — the first post starts the board.',
                    )
                  else
                    ...filtered.map((post) {
                      // Legacy 'job' rows (pre-migration-21 data) display as
                      // "Opportunity", matching the web page's normalization.
                      final effectiveType = post['post_type'] == 'job'
                          ? 'unofficial_opportunity'
                          : post['post_type'];
                      final typeInfo = _postTypes.firstWhere(
                          (t) => t.$1 == effectiveType,
                          orElse: () => _postTypes.first);
                      final poster = Map<String, dynamic>.from(
                          post['poster'] as Map? ?? const {});
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PremiumCard(
                          radius: AppRadius.card,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primaryPurple
                                            .withValues(alpha: .1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(typeInfo.$3,
                                              size: 11,
                                              color: AppTheme.primaryPurple),
                                          const SizedBox(width: 4),
                                          Text(typeInfo.$2,
                                              style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AppTheme.primaryPurple)),
                                        ]),
                                  ),
                                  const Spacer(),
                                  if (canModerate)
                                    IconButton(
                                      tooltip: 'Hide this post',
                                      icon: const Icon(LucideIcons.eyeOff,
                                          size: 16),
                                      onPressed: () =>
                                          _hidePost(post['id'] as String),
                                    ),
                                ]),
                                const SizedBox(height: 6),
                                Text(post['title']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(post['description']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: AppTheme.mutedText)),
                                const SizedBox(height: 8),
                                Text('by ${poster['name'] ?? 'a member'}',
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.mutedText)),
                              ]),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
