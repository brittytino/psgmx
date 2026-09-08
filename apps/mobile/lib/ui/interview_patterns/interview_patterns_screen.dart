import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/empty_state.dart';

const Map<String, String> _typeLabels = {
  'aptitude_screening': 'Aptitude Screening',
  'coding_round': 'Coding Round',
  'technical_deep_dive': 'Technical Deep Dive',
  'fyp_discussion': 'FYP Discussion',
  'behavioural': 'Behavioural',
  'group_discussion': 'Group Discussion',
  'general': 'General',
};

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
          .from('interview_patterns')
          .select(
              'id, title, pattern_type, historical_context, preparation_helped, mistakes, example_themes, advice, company_name, batch_year, created_at')
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() {
        _patterns = List<Map<String, dynamic>>.from(rows);
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
                          'Historical, faculty-reviewed interview accounts—not an official drive list. Use NEO PAT for current placement operations.',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              height: 1.45,
                              fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 18),
              if (_loading) const LinearProgressIndicator(minHeight: 3),
              if (_error != null)
                EmptyState(
                  icon: LucideIcons.wifiOff,
                  title: 'Could not load patterns',
                  message: _error,
                  onRetry: _load,
                ),
              if (!_loading && _error == null && _patterns.isEmpty)
                const EmptyState(
                  icon: LucideIcons.libraryBig,
                  title: 'No approved patterns yet',
                  message:
                      'Faculty-reviewed senior and alumni insight will appear here.',
                ),
              ..._patterns.map((pattern) {
                final type = pattern['pattern_type']?.toString() ?? '';
                final themes =
                    (pattern['example_themes'] as List?)?.cast<dynamic>() ??
                        const [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    backgroundColor: Colors.white,
                    collapsedBackgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    collapsedShape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppTheme.cardBorder),
                        borderRadius: BorderRadius.circular(18)),
                    leading: const Icon(LucideIcons.messagesSquare,
                        color: AppTheme.accentCoral),
                    title: Text(pattern['title']?.toString() ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    subtitle: Wrap(spacing: 6, runSpacing: 4, children: [
                      _PatternTag(label: _typeLabels[type] ?? type),
                      if ((pattern['company_name'] as String?)
                              ?.isNotEmpty ==
                          true)
                        _PatternTag(label: pattern['company_name'].toString()),
                      if ((pattern['batch_year'] as String?)?.isNotEmpty ==
                          true)
                        _PatternTag(label: pattern['batch_year'].toString()),
                    ]),
                    children: [
                      if ((pattern['historical_context'] as String?)
                              ?.trim()
                              .isNotEmpty ==
                          true) ...[
                        _Section(
                            text: pattern['historical_context'].toString()),
                        const SizedBox(height: 10),
                      ],
                      _Section(
                        label: 'What preparation helped',
                        text: pattern['preparation_helped']?.toString() ?? '',
                        color: const Color(0xFF047857),
                        background: const Color(0xFFECFDF5),
                      ),
                      if ((pattern['mistakes'] as String?)?.trim().isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 10),
                        _Section(
                          label: 'Mistakes to avoid',
                          text: pattern['mistakes'].toString(),
                          color: const Color(0xFFB91C1C),
                          background: const Color(0xFFFEF2F2),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _Section(
                        label: 'Advice',
                        text: pattern['advice']?.toString() ?? '',
                        color: AppTheme.accentCoral,
                        background: const Color(0xFFFFF4ED),
                      ),
                      if (themes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: themes
                              .map((t) => _PatternTag(label: t.toString()))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
}

class _PatternTag extends StatelessWidget {
  final String label;
  const _PatternTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF475569))),
      );
}

class _Section extends StatelessWidget {
  final String? label;
  final String text;
  final Color? color;
  final Color? background;
  const _Section({this.label, required this.text, this.color, this.background});

  @override
  Widget build(BuildContext context) {
    final body = Text(text,
        style: GoogleFonts.inter(
            fontSize: 11, height: 1.55, color: const Color(0xFF475569)));
    if (label == null) return Align(alignment: Alignment.centerLeft, child: body);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label!,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 6),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 11, height: 1.55, color: const Color(0xFF334155))),
      ]),
    );
  }
}
