import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

class InterviewPatternsScreen extends StatefulWidget {
  const InterviewPatternsScreen({super.key});

  @override
  State<InterviewPatternsScreen> createState() =>
      _InterviewPatternsScreenState();
}

class _InterviewPatternsScreenState extends State<InterviewPatternsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patterns = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

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
          .limit(100);
      final values = List<Map<String, dynamic>>.from(rows).where((row) {
        final tags = (row['tags'] as List?)
                ?.map((item) => item.toString().toLowerCase())
                .toList() ??
            const <String>[];
        final source = row['source']?.toString().toLowerCase() ?? '';
        return source.contains('placement') ||
            source.contains('interview') ||
            tags.any((tag) =>
                tag.contains('interview') ||
                tag.contains('experience') ||
                tag.contains('pattern'));
      }).toList();
      if (!mounted) return;
      setState(() {
        _patterns = values;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Interview patterns could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('Interview Pattern Library'),
          backgroundColor: const Color(0xFFF7F8FA),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: const Color(0xFFFFD4BF))),
                child: Row(children: [
                  const Icon(LucideIcons.shieldCheck,
                      color: AppTheme.accentCoral),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Historical preparation insight—not an official drive list. Use NEO PAT for current placement operations.',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              height: 1.45,
                              fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 18),
              if (_loading) const LinearProgressIndicator(minHeight: 3),
              if (_error != null)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                )),
              if (!_loading && _error == null && _patterns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(children: [
                    const Icon(LucideIcons.libraryBig,
                        size: 38, color: AppTheme.accentCoral),
                    const SizedBox(height: 12),
                    Text('No approved patterns yet',
                        style: GoogleFonts.sora(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(
                        'Faculty-reviewed senior and alumni insight will appear here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF64748B))),
                  ]),
                ),
              ..._patterns.map((pattern) => Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      collapsedShape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFFE8EAF0)),
                          borderRadius: BorderRadius.circular(18)),
                      leading: const Icon(LucideIcons.messagesSquare,
                          color: AppTheme.accentCoral),
                      title: Text(pattern['title']?.toString() ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          pattern['batch_year']?.toString() ??
                              'Faculty-reviewed insight',
                          style: GoogleFonts.inter(
                              fontSize: 9, color: const Color(0xFF64748B))),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              pattern['summary']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? pattern['summary'].toString()
                                  : pattern['content']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  height: 1.55,
                                  color: const Color(0xFF475569))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
}
