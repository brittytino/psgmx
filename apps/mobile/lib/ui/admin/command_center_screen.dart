import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _pulse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) throw const FormatException('Your session has expired.');
      final response = await http.get(
        Uri.parse('${SupabaseConfig.appApiUrl}/api/placement-rep/pulse'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw FormatException(body['error']?.toString() ?? 'Could not load readiness.');
      }
      if (!mounted) return;
      setState(() { _pulse = body; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loading = false; _error = error is FormatException ? error.message : 'The live batch pulse could not be refreshed.'; });
    }
  }

  num? _number(String key) => _pulse?[key] as num?;

  @override
  Widget build(BuildContext context) {
    final batch = _pulse?['batchCode']?.toString() ?? '—';
    final bands = Map<String, dynamic>.from((_pulse?['bandCounts'] as Map?) ?? const {});
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PR Command Center', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('Batch-level preparation pulse', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
        ]),
        actions: [IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(LucideIcons.refreshCw, size: 19))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) _Notice(message: _error!, onRetry: _load),
            if (_pulse != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFF17132D), borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(LucideIcons.shieldCheck, color: Colors.white)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$batch live pulse', style: GoogleFonts.sora(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('Aggregate signals only. Individual readiness stays private.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, height: 1.4))])),
                ]),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _Metric(label: 'Students', value: '${_number('totalStudents') ?? 0}', note: '${_number('activeThisWeekPct') ?? 0}% active this week', icon: LucideIcons.users),
                  _Metric(label: 'Readiness', value: _number('avgReadinessScore') == null ? '—' : '${_number('avgReadinessScore')}/100', note: 'Verified evidence', icon: LucideIcons.activity),
                  _Metric(label: 'Attendance', value: _number('avgAttendance') == null ? '—' : '${(_number('avgAttendance')!).round()}%', note: 'Preparation sessions', icon: LucideIcons.calendarCheck),
                  _Metric(label: 'Upcoming', value: '${_number('upcomingSessions') ?? 0}', note: 'Scheduled sessions', icon: LucideIcons.calendarClock),
                ],
              ),
              const SizedBox(height: 20),
              Text('Readiness distribution', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Counts guide batch preparation without exposing student scores.', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
              const SizedBox(height: 12),
              _BandCard(bands: bands),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), border: Border.all(color: const Color(0xFFFED7AA)), borderRadius: BorderRadius.circular(17)),
                child: Row(children: [const Icon(LucideIcons.shieldAlert, size: 19, color: Color(0xFFEA580C)), const SizedBox(width: 11), Expanded(child: Text('${_number('declineSignalCount') ?? 0} recovery signals were routed privately to faculty. PR accounts cannot open individual scores.', style: GoogleFonts.inter(fontSize: 10, height: 1.45, fontWeight: FontWeight.w600, color: const Color(0xFF9A3412))))]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.note, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAF0)), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppTheme.accentCoral, size: 18), const Spacer(), Text(value, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)), Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B)))]),
  );
}

class _BandCard extends StatelessWidget {
  final Map<String, dynamic> bands;
  const _BandCard({required this.bands});

  @override
  Widget build(BuildContext context) {
    const entries = [('strong', 'Strong', Color(0xFF2563EB)), ('building', 'Building', Color(0xFFF59E0B)), ('needs_attention', 'Needs attention', Color(0xFF7C3AED)), ('at_risk', 'At risk', Color(0xFFDC2626))];
    final total = entries.fold<int>(0, (sum, item) => sum + ((bands[item.$1] as num?)?.toInt() ?? 0));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAF0)), borderRadius: BorderRadius.circular(18)),
      child: total == 0 ? Text('No readiness evidence has been computed yet.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))) : Column(children: entries.map((item) { final count = (bands[item.$1] as num?)?.toInt() ?? 0; return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item.$2, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)), Text('$count', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w900))]), const SizedBox(height: 5), LinearProgressIndicator(value: count / total, minHeight: 5, borderRadius: BorderRadius.circular(8), color: item.$3, backgroundColor: const Color(0xFFF1F5F9))])); }).toList()),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _Notice({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(LucideIcons.wifiOff, color: Color(0xFFDC2626)), const SizedBox(width: 10), Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 11))), TextButton(onPressed: onRetry, child: const Text('Retry'))])));
}
