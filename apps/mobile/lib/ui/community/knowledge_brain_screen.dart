import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class KnowledgeBrainScreen extends StatefulWidget {
  const KnowledgeBrainScreen({super.key});

  @override
  State<KnowledgeBrainScreen> createState() => _KnowledgeBrainScreenState();
}

class _KnowledgeBrainScreenState extends State<KnowledgeBrainScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _selectedTag;
  List<Map<String, dynamic>> _articles = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilter);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  void _refreshFilter() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('knowledge_brain_articles')
          .select(
              'id, title, summary, content, tags, source, batch_year, created_at')
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .limit(150);
      if (!mounted) return;
      setState(() {
        _articles = (rows as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Approved knowledge could not be refreshed.';
      });
    }
  }

  List<String> get _tags {
    final tags = <String>{};
    for (final article in _articles) {
      for (final tag in article['tags'] as List? ?? const []) {
        final value = tag.toString().trim();
        if (value.isNotEmpty) tags.add(value);
      }
    }
    final result = tags.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result.take(12).toList();
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _articles.where((article) {
      final tags = (article['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList();
      if (_selectedTag != null && !tags.contains(_selectedTag)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        article['title'],
        article['summary'],
        article['content'],
        ...tags,
      ].whereType<Object>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openArticle(Map<String, dynamic> article) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .88,
        minChildSize: .55,
        maxChildSize: .96,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 36),
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
            const SizedBox(height: 22),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(article['title']?.toString() ?? '',
                    style: GoogleFonts.sora(
                        fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(LucideIcons.x),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              [article['batch_year'], _sourceLabel(article['source'])]
                  .where((item) => item?.toString().trim().isNotEmpty == true)
                  .join(' · '),
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.mutedText),
            ),
            if ((article['summary']?.toString().trim() ?? '').isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(article['summary'].toString(),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C5B4A))),
              ),
            ],
            const SizedBox(height: 20),
            Text(article['content']?.toString() ?? '',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.65,
                    color: const Color(0xFF334155))),
            const SizedBox(height: 22),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: (article['tags'] as List? ?? const [])
                  .map((tag) => Chip(label: Text(tag.toString())))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(LucideIcons.shieldCheck,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Faculty-approved Knowledge Brain source',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF166534))),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(dynamic source) {
    final value = source?.toString() ?? '';
    if (value.startsWith('interview_pattern:')) return 'Interview pattern';
    return value.isEmpty ? 'Knowledge Brain' : 'Approved source';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Knowledge Brain',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text('Only reviewed department knowledge appears here.',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedText)),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search DBMS, interviews, projects…',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
              ),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedTag == null,
                      onSelected: (_) => setState(() => _selectedTag = null),
                    ),
                  ),
                  ..._tags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(tag),
                          selected: _selectedTag == tag,
                          onSelected: (_) => setState(() => _selectedTag = tag),
                        ),
                      )),
                ]),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _KnowledgeNotice(message: _error!, onRetry: _load),
            ],
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Text('Approved resources',
                    style: GoogleFonts.sora(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text('${filtered.length}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentCoral)),
            ]),
            const SizedBox(height: 10),
            if (!_loading && filtered.isEmpty && _error == null)
              EmptyState(
                icon: LucideIcons.searchX,
                title: 'No approved resource matches',
                message: _searchController.text.isEmpty
                    ? 'New resources appear after faculty review.'
                    : 'Try a broader topic or clear the selected filter.',
              )
            else
              ...filtered.map((article) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumCard(
                      radius: AppRadius.card,
                      padding: const EdgeInsets.all(15),
                      onTap: () => _openArticle(article),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentCoral.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.bookOpen,
                                size: 19, color: AppTheme.accentCoral),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(article['title']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                if ((article['summary']?.toString().trim() ??
                                        '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(article['summary'].toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          height: 1.4,
                                          color: AppTheme.mutedText)),
                                ],
                                const SizedBox(height: 7),
                                Text(
                                  _sourceLabel(article['source']),
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _KnowledgeNotice({required this.message, required this.onRetry});

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
