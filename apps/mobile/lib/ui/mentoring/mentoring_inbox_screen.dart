import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

/// The alumni side of PRD Ch. 14.2's lineage request model: accept,
/// decline, or redirect a junior's specific topic/question. The junior's
/// side (sending a request) lives in community_screen.dart.
class MentoringInboxScreen extends StatefulWidget {
  const MentoringInboxScreen({super.key});

  @override
  State<MentoringInboxScreen> createState() => _MentoringInboxScreenState();
}

class _MentoringInboxScreenState extends State<MentoringInboxScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _requests = const [];
  final Set<String> _responding = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final rows = await Supabase.instance.client
          .from('lineage_requests')
          .select(
              'id, topic, question, status, created_at, student:student_id(name, reg_no)')
          .eq('alumni_id', userId as Object)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _requests = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(String id, String status) async {
    setState(() => _responding.add(id));
    try {
      await Supabase.instance.client
          .from('lineage_requests')
          .update({'status': status, 'responded_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      if (!mounted) return;
      setState(() {
        final index = _requests.indexWhere((r) => r['id'] == id);
        if (index != -1) _requests[index]['status'] = status;
        _responding.remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _responding.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update — try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final resolved = _requests.where((r) => r['status'] != 'pending').toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Mentoring requests', style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  if (pending.isEmpty && resolved.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.handshake,
                      title: 'No requests yet',
                      message: 'When a junior asks you a specific question, it will show up here.',
                    )
                  else ...[
                    if (pending.isNotEmpty) ...[
                      Text('Pending (${pending.length})', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...pending.map((r) => _RequestCard(
                            request: r,
                            responding: _responding.contains(r['id']),
                            onAccept: () => _respond(r['id'] as String, 'accepted'),
                            onDecline: () => _respond(r['id'] as String, 'declined'),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (resolved.isNotEmpty) ...[
                      Text('Past requests', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...resolved.map((r) => _RequestCard(request: r, responding: false)),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool responding;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  const _RequestCard({required this.request, required this.responding, this.onAccept, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final student = Map<String, dynamic>.from(request['student'] as Map? ?? const {});
    final status = request['status'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        radius: AppRadius.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${student['name'] ?? 'A student'} · ${request['topic']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            if (status != 'pending')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 6),
          Text(request['question']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppTheme.mutedText)),
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            responding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(children: [
                    FilledButton(onPressed: onAccept, child: const Text('Accept')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: onDecline, child: const Text('Decline')),
                  ]),
          ],
        ]),
      ),
    );
  }
}
