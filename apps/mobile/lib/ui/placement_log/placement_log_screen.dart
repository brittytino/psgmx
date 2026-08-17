import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/company.dart';
import '../../services/placement_log_service.dart';

class PlacementLogScreen extends StatefulWidget {
  const PlacementLogScreen({super.key});

  @override
  State<PlacementLogScreen> createState() => _PlacementLogScreenState();
}

class _PlacementLogScreenState extends State<PlacementLogScreen> {
  final _service = PlacementLogService(Supabase.instance.client);

  List<Company> _companies = [];
  List<Company> _filtered = [];
  Map<String, List<PlacementLogEntry>> _experiences = {};
  Set<String> _expandedIds = {};

  bool _isLoading = true;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _yearFilter = 'All Years';
  List<String> _availableYears = ['All Years'];

  StreamSubscription<List<Company>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _subscribe() {
    setState(() { _isLoading = true; _error = null; });
    _subscription = _service.streamCompanies().listen(
      (companies) {
        final years = companies.map((c) => c.visitDate.year.toString()).toSet().toList();
        years.sort((a, b) => b.compareTo(a));

        if (mounted) {
          setState(() {
            _companies = companies;
            _availableYears = ['All Years', ...years];
            _isLoading = false;
          });
          _applyFilters();
        }
      },
      onError: (e) {
        if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
      },
    );
  }

  Future<void> _reload() async {
    _subscription?.cancel();
    _subscribe();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _companies.where((c) {
        final matchesSearch = q.isEmpty || c.name.toLowerCase().contains(q);
        final matchesYear = _yearFilter == 'All Years' ||
            c.visitDate.year.toString() == _yearFilter;
        return matchesSearch && matchesYear;
      }).toList();
    });
  }

  Future<void> _toggleExpand(String companyId) async {
    if (_expandedIds.contains(companyId)) {
      setState(() => _expandedIds.remove(companyId));
      return;
    }
    setState(() => _expandedIds.add(companyId));
    if (!_experiences.containsKey(companyId)) {
      try {
        final entries = await _service.fetchEntriesForCompany(companyId);
        if (mounted) setState(() => _experiences[companyId] = entries);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
              : _error != null
                  ? _buildError()
                  : Column(
                      children: [
                        _buildHeader(),
                        _buildSearchFilters(),
                        Expanded(child: _buildTimeline()),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Placement Log',
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Stories. Insights. Inspiration.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Company count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_companies.length} companies',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentCoral,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Search box
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search company',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.search, size: 14, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentCoral),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Year filter
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _yearFilter,
                icon: const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF64748B)),
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
                items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() { _yearFilter = v; _applyFilters(); });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.building2, size: 32, color: AppTheme.accentCoral),
              ),
              const SizedBox(height: 16),
              Text('No companies found', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text('Try adjusting your search or filters.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppTheme.accentCoral,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: _filtered.length,
        itemBuilder: (_, index) {
          final company = _filtered[index];
          final isFirstOfYear = index == 0 ||
              _filtered[index - 1].visitDate.year != company.visitDate.year;
          final isLast = index == _filtered.length - 1;
          final isExpanded = _expandedIds.contains(company.id);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline column
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      if (isFirstOfYear)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            company.visitDate.year.toString(),
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentCoral,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 26),
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.accentCoral.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppTheme.accentCoral, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppTheme.accentCoral.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                ),
                // Card column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 12),
                    child: _CompanyCard(
                      company: company,
                      isExpanded: isExpanded,
                      experiences: _experiences[company.id],
                      onToggle: () => _toggleExpand(company.id),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('Could not load placement log', style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(_error ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accentCoral),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Company Card ──────────────────────────────────────────────────────────
class _CompanyCard extends StatelessWidget {
  final Company company;
  final bool isExpanded;
  final List<PlacementLogEntry>? experiences;
  final VoidCallback onToggle;

  const _CompanyCard({
    required this.company,
    required this.isExpanded,
    required this.experiences,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final visitStr = DateFormat('d MMM yyyy').format(company.visitDate);

    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFFFF8F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppTheme.accentCoral.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ────────────────────────────────────────────
          InkWell(
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo placeholder
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Text(
                        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                        style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                company.name,
                                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                            ),
                            if (company.packageBand != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCoral.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  company.packageBand!,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.rolesOffered.isNotEmpty ? company.rolesOffered.join(', ') : 'Multiple Roles',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(LucideIcons.calendar, size: 12, color: const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('Visited on $visitStr', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                            const Spacer(),
                            Icon(
                              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              size: 16,
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded experiences ───────────────────────────────────
          if (isExpanded) ...[
            Divider(height: 1, color: AppTheme.accentCoral.withValues(alpha: 0.15)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: experiences == null
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.accentCoral, strokeWidth: 2)))
                  : experiences!.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Text(
                                'No student experiences shared yet.',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Experiences (${experiences!.length})',
                              style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),
                            ...experiences!.take(3).map((e) => _ExperienceEntry(entry: e)),
                            if (experiences!.length > 3) ...[
                              const SizedBox(height: 8),
                              Text(
                                'View all experiences (${experiences!.length}) →',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentCoral,
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Experience Entry ──────────────────────────────────────────────────────
class _ExperienceEntry extends StatelessWidget {
  final PlacementLogEntry entry;
  const _ExperienceEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accentCoral.withValues(alpha: 0.1),
            child: Icon(LucideIcons.user, size: 16, color: AppTheme.accentCoral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.isAnonymous == true ? 'Anonymous' : 'Student',
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    if (entry.outcome == 'placed')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Placed', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E))),
                      ),
                  ],
                ),
                if (entry.roundName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.roundName, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('" ', style: GoogleFonts.sora(fontSize: 18, height: 0.8, fontWeight: FontWeight.bold, color: AppTheme.accentCoral.withValues(alpha: 0.3))),
                    Expanded(
                      child: Text(
                        entry.experienceText,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
