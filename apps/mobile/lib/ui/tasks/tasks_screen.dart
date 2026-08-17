import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/daily_task.dart';

// ─── Service: stream all tasks (no uploads) ──────────────────────────────────
class _QuestReadService {
  final _db = Supabase.instance.client;

  Stream<List<DailyTask>> streamAll() {
    return _db.from('daily_tasks').stream(primaryKey: ['id']).map((data) {
      final list = data.map((r) => DailyTask.fromMap(r)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }
}

// ─── Main Screen ───────────────────────────────────────────────────────────
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _service = _QuestReadService();
  late TabController _tabController;

  List<DailyTask> _projectTasks = [];
  List<DailyTask> _aptiDsaTasks = [];
  bool _isLoading = true;
  String? _error;
  
  StreamSubscription<List<DailyTask>>? _subscription;

  // Filter
  String _filter = 'All'; // All | This Week | This Month
  static const _filters = ['All', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribe() {
    setState(() { _isLoading = true; _error = null; });
    _subscription = _service.streamAll().listen(
      (tasks) {
        if (mounted) {
          setState(() {
            _projectTasks = tasks.where((t) => t.topicType == TopicType.core).toList();
            _aptiDsaTasks = tasks.where((t) => t.topicType == TopicType.leetcode).toList();
            _isLoading = false;
          });
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

  List<DailyTask> _filtered(List<DailyTask> tasks) {
    final now = DateTime.now();
    switch (_filter) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return tasks.where((t) =>
            t.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfWeek.add(const Duration(days: 1)))).toList();
      case 'This Month':
        return tasks.where((t) =>
            t.date.year == now.year && t.date.month == now.month).toList();
      default:
        return tasks;
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
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildHeader(),
              ),
              // ── Tabs ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildTabBar(),
              ),
              // ── Filters ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildFilterRow(),
              ),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
                    : _error != null
                        ? _buildError()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTaskList(_filtered(_projectTasks), 'Project Tasks'),
                              _buildTaskList(_filtered(_aptiDsaTasks), 'Apti & DSA'),
                            ],
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
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Your placement roadmap.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        // Total task count pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentCoral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.map, size: 14, color: AppTheme.accentCoral),
              const SizedBox(width: 6),
              Text(
                '${_projectTasks.length + _aptiDsaTasks.length} tasks',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentCoral,
                ),
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

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                f,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
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
            Text('Could not load tasks', style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
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

  Widget _buildTaskList(List<DailyTask> tasks, String label) {
    if (tasks.isEmpty) {
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
                child: const Icon(LucideIcons.clipboardList, size: 32, color: AppTheme.accentCoral),
              ),
              const SizedBox(height: 16),
              Text('No $label found', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text('Tasks will appear once they are published by your placement team.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Group by week
    final groups = _groupByWeek(tasks);

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppTheme.accentCoral,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        itemCount: groups.length,
        itemBuilder: (_, i) {
          final entry = groups[i];
          if (entry['isHeader'] == true) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry['label'] as String,
                      style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: const Color(0xFFE2E8F0), height: 1)),
                  const SizedBox(width: 8),
                  Text(
                    '${entry['count']} tasks',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }
          return _TaskCard(task: entry['task'] as DailyTask);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupByWeek(List<DailyTask> tasks) {
    final result = <Map<String, dynamic>>[];
    String? currentWeek;
    int weekCount = 0;

    for (final task in tasks) {
      final monday = task.date.subtract(Duration(days: task.date.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final label = 'Week of ${DateFormat('MMM d').format(monday)} – ${DateFormat('d').format(sunday)}';

      if (label != currentWeek) {
        if (currentWeek != null && result.isNotEmpty) {
          // Update count in previous header
          final headerIdx = result.lastIndexWhere((e) => e['isHeader'] == true);
          if (headerIdx >= 0) result[headerIdx]['count'] = weekCount;
        }
        currentWeek = label;
        weekCount = 0;
        result.add({'isHeader': true, 'label': label, 'count': 0});
      }
      weekCount++;
      result.add({'isHeader': false, 'task': task});
    }

    // Fix last header count
    final headerIdx = result.lastIndexWhere((e) => e['isHeader'] == true);
    if (headerIdx >= 0) result[headerIdx]['count'] = weekCount;

    return result;
  }
}

// ─── Task Card ─────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final DailyTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isLeetcode = task.topicType == TopicType.leetcode;
    final accentColor = isLeetcode ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
    final tagLabel = isLeetcode ? 'LeetCode' : (task.subject ?? 'Project');
    final formattedDate = DateFormat('EEE, d MMM').format(task.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: task.referenceLink != null ? () => _openLink(context, task.referenceLink!) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: tag + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLeetcode ? LucideIcons.code : LucideIcons.folderKanban,
                          size: 11,
                          color: accentColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tagLabel,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.calendarDays, size: 12, color: const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Task title
              Text(
                task.title,
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
              // Subject (for project tasks)
              if (!isLeetcode && task.subject != null) ...[
                const SizedBox(height: 4),
                Text(
                  task.subject!,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
              // Link
              if (task.referenceLink != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.externalLink, size: 13, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.referenceLink!.length > 50
                              ? '${task.referenceLink!.substring(0, 50)}…'
                              : task.referenceLink!,
                          style: GoogleFonts.inter(fontSize: 12, color: accentColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('Open →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
