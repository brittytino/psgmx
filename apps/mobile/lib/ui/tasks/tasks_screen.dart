import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/daily_content.dart';
import '../../providers/user_provider.dart';
import '../../services/daily_content_service.dart';

// ─── Main Screen ───────────────────────────────────────────────────────────
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _service = DailyContentService(Supabase.instance.client);
  late TabController _tabController;

  ProjectTask? _projectTask;
  AptiDsaDailyItem? _aptiDsa;
  bool _projectTaskDone = false;
  bool _aptiDsaDone = false;
  int _projectTaskCompletedCount = 0;
  int _aptiDsaCompletedCount = 0;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final userId = context.read<UserProvider>().currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not signed in';
      });
      return;
    }
    try {
      final results = await Future.wait([
        _service.fetchTodaysProjectTask(),
        _service.fetchTodaysAptiDsa(),
        _service.isCompletedToday(userId, 'project_task'),
        _service.isCompletedToday(userId, 'apti_dsa'),
        _service.fetchCompletionCount(userId, 'project_task'),
        _service.fetchCompletionCount(userId, 'apti_dsa'),
      ]);
      if (!mounted) return;
      setState(() {
        _projectTask = results[0] as ProjectTask?;
        _aptiDsa = results[1] as AptiDsaDailyItem?;
        _projectTaskDone = results[2] as bool;
        _aptiDsaDone = results[3] as bool;
        _projectTaskCompletedCount = results[4] as int;
        _aptiDsaCompletedCount = results[5] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markComplete(String contentType) async {
    final userId = context.read<UserProvider>().currentUser?.uid;
    if (userId == null) return;
    HapticFeedback.mediumImpact();
    try {
      await _service.markComplete(userId, contentType);
      if (!mounted) return;
      setState(() {
        if (contentType == 'project_task') {
          _projectTaskDone = true;
          _projectTaskCompletedCount++;
        } else {
          _aptiDsaDone = true;
          _aptiDsaCompletedCount++;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not save — check your connection and try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildHeader(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildTabBar(),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accentCoral))
                    : _error != null
                        ? _buildError()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppTheme.accentCoral,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildProjectTaskTab(),
                                _buildAptiDsaTab(),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quests',
              style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Your daily preparation roadmap.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF64748B))),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles,
                    size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentCoral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.calendarCheck,
                  size: 14, color: AppTheme.accentCoral),
              const SizedBox(width: 6),
              Text(
                'Day ${DateFormatDoy.format(DateTime.now())}',
                style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentCoral),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(11),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Project Tasks'),
          Tab(text: 'Apti & DSA'),
        ],
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
            Text('Could not load today\'s content',
                style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(_error ?? '',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.accentCoral),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(LucideIcons.clipboardList,
                  size: 32, color: AppTheme.accentCoral),
            ),
            const SizedBox(height: 16),
            Text('No $label for today',
                style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('Check back tomorrow for fresh content.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTaskTab() {
    final task = _projectTask;
    if (task == null) {
      return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 500, child: _buildEmpty('project task')));
    }

    const accentColor = Color(0xFF6366F1);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressStrip(
              '$_projectTaskCompletedCount / 365 completed', accentColor),
          const SizedBox(height: 12),
          _ContentCard(
            accentColor: accentColor,
            tagIcon: LucideIcons.folderKanban,
            tagLabel: task.category,
            difficulty: task.difficulty,
            title: task.title,
            body: task.description,
            referenceLink: task.referenceLink,
            done: _projectTaskDone,
            onMarkComplete: () => _markComplete('project_task'),
          ),
        ],
      ),
    );
  }

  Widget _buildAptiDsaTab() {
    final item = _aptiDsa;
    if (item == null) {
      return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 500, child: _buildEmpty('Apti & DSA set')));
    }

    const accentColor = Color(0xFFEF4444);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressStrip(
              '$_aptiDsaCompletedCount / 365 completed', accentColor),
          const SizedBox(height: 12),
          _ContentCard(
            accentColor: accentColor,
            tagIcon: LucideIcons.code,
            tagLabel: item.dsaTopic,
            difficulty: item.dsaDifficulty,
            title: item.dsaTitle,
            body: item.dsaHint,
            referenceLink: item.dsaExternalLink,
            done: false,
            showMarkComplete: false,
          ),
          const SizedBox(height: 16),
          Text('Quick Aptitude Practice',
              style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          ...item.aptitudeQuestions.asMap().entries.map(
                (e) => _AptitudeQuestionCard(index: e.key, question: e.value),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _aptiDsaDone ? null : () => _markComplete('apti_dsa'),
              icon: Icon(
                  _aptiDsaDone ? LucideIcons.checkCircle2 : LucideIcons.check,
                  size: 16),
              label: Text(_aptiDsaDone
                  ? 'Completed for today'
                  : 'Mark Today\'s Set Complete'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    _aptiDsaDone ? const Color(0xFF22C55E) : accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip(String label, Color accentColor) {
    return Row(
      children: [
        Icon(LucideIcons.flame, size: 14, color: accentColor),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B))),
      ],
    );
  }
}

// ─── Content Card (shared shape for Project Task + DSA problem) ────────────
class _ContentCard extends StatelessWidget {
  final Color accentColor;
  final IconData tagIcon;
  final String tagLabel;
  final String difficulty;
  final String title;
  final String? body;
  final String? referenceLink;
  final bool done;
  final bool showMarkComplete;
  final VoidCallback? onMarkComplete;

  const _ContentCard({
    required this.accentColor,
    required this.tagIcon,
    required this.tagLabel,
    required this.difficulty,
    required this.title,
    this.body,
    this.referenceLink,
    this.done = false,
    this.showMarkComplete = true,
    this.onMarkComplete,
  });

  Color get _difficultyColor {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF22C55E);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not open link', style: GoogleFonts.inter()),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(tagIcon, size: 11, color: accentColor),
                    const SizedBox(width: 5),
                    Text(tagLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(difficulty,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _difficultyColor)),
              ),
              const Spacer(),
              if (done)
                const Icon(LucideIcons.checkCircle2,
                    size: 18, color: Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.4)),
          if (body != null && body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body!,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B), height: 1.5)),
          ],
          if (referenceLink != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openLink(context, referenceLink!),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(LucideIcons.externalLink,
                        size: 13, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        referenceLink!.length > 50
                            ? '${referenceLink!.substring(0, 50)}…'
                            : referenceLink!,
                        style:
                            GoogleFonts.inter(fontSize: 12, color: accentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('Open →',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor)),
                  ],
                ),
              ),
            ),
          ],
          if (showMarkComplete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: done ? null : onMarkComplete,
                icon: Icon(done ? LucideIcons.checkCircle2 : LucideIcons.check,
                    size: 16),
                label: Text(done ? 'Completed for today' : 'Mark Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: done ? const Color(0xFF22C55E) : accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Embedded Aptitude Question Card ────────────────────────────────────────
class _AptitudeQuestionCard extends StatefulWidget {
  final int index;
  final EmbeddedAptitudeQuestion question;
  const _AptitudeQuestionCard({required this.index, required this.question});

  @override
  State<_AptitudeQuestionCard> createState() => _AptitudeQuestionCardState();
}

class _AptitudeQuestionCardState extends State<_AptitudeQuestionCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final answered = _selected != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${widget.index + 1}. ${widget.question.question}',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                height: 1.4),
          ),
          const SizedBox(height: 10),
          ...widget.question.options.asMap().entries.map((e) {
            final isCorrect = e.key == widget.question.correctOption;
            final isSelected = e.key == _selected;
            Color bg = const Color(0xFFF8FAFC);
            Color border = const Color(0xFFE2E8F0);
            Color text = const Color(0xFF1E293B);
            if (answered) {
              if (isCorrect) {
                bg = const Color(0xFF22C55E).withValues(alpha: 0.1);
                border = const Color(0xFF22C55E);
                text = const Color(0xFF15803D);
              } else if (isSelected) {
                bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
                border = const Color(0xFFEF4444);
                text = const Color(0xFFB91C1C);
              }
            }
            return GestureDetector(
              onTap: answered ? null : () => setState(() => _selected = e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border)),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(e.value,
                            style:
                                GoogleFonts.inter(fontSize: 12, color: text))),
                    if (answered && isCorrect)
                      const Icon(LucideIcons.check,
                          size: 14, color: Color(0xFF22C55E)),
                    if (answered && isSelected && !isCorrect)
                      const Icon(LucideIcons.x,
                          size: 14, color: Color(0xFFEF4444)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
