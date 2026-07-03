import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';
import '../../providers/user_provider.dart';
import '../../providers/daily_five_provider.dart';
import '../../services/task_upload_service.dart';
import '../../services/task_completion_service.dart';
import '../../models/daily_task.dart';
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  final DateTime _today = DateTime.now();
  late DateTime _selectedDate;
  late TabController _tabController;
  
  final TaskUploadService _taskUploadService = TaskUploadService();
  final TaskCompletionService _taskCompletionService = TaskCompletionService();

  List<DailyTask> _dailyTasks = [];
  bool _isLoadingTasks = false;
  bool _isDayCompleted = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
    _fetchDataForDate(_selectedDate);
  }

  Future<void> _fetchDataForDate(DateTime date) async {
    setState(() {
      _isLoadingTasks = true;
    });
    try {
      final tasks = await _taskUploadService.getTasksForDate(date);
      final completion = await _taskCompletionService.getMyTaskCompletion(date);
      setState(() {
        _dailyTasks = tasks;
        _isDayCompleted = completion?.completed ?? false;
        _isLoadingTasks = false;
      });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      setState(() {
        _isLoadingTasks = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final canUploadTasks = userProvider.isPlacementRep || userProvider.isCoordinator || userProvider.hasActualAdminAccess;

    // Re-initialize tab controller if tab length changes (not highly likely during normal use but good for hot reload)
    final tabCount = canUploadTasks ? 3 : 2;
    // Safe initialization
    try {
      if (_tabController.length != tabCount) {
        _tabController.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }
    } catch (e) {
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quests',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Your daily roadmap to growth ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
                        ],
                      ),
                    ],
                  ),
                  const RivePlaceholder(
                    width: 80,
                    height: 80,
                    label: 'Spark Map',
                    icon: LucideIcons.map,
                  ),
                ],
              ),
            ),
            
            // Custom TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentCoral, width: 2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.accentCoral.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  labelColor: AppTheme.accentCoral,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.listTodo, size: 12),
                          SizedBox(width: 8),
                          Text('My Tasks'),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.listChecks, size: 12),
                          SizedBox(width: 8),
                          Text('All Tasks'),
                        ],
                      ),
                    ),
                    if (canUploadTasks)
                      const Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.uploadCloud, size: 12),
                            SizedBox(width: 8),
                            Text('Upload Task'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyTasksView(theme),
                  _buildAllTasksView(theme),
                  if (canUploadTasks) _buildUploadTaskView(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort Tasks', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.listOrdered, color: AppTheme.accentCoral),
                title: const Text('Status: Pending First'),
                onTap: () {
                  setState(() {
                    _dailyTasks.sort((a, b) => a.title.compareTo(b.title)); // Example sort
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.checkCircle, color: Colors.green),
                title: const Text('Status: Completed First'),
                onTap: () {
                  setState(() {
                    _dailyTasks.sort((a, b) => b.title.compareTo(a.title)); // Example sort
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWhyTasksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.lightbulb, color: AppTheme.accentCoral),
            const SizedBox(width: 8),
            Text('Why tasks?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        content: Text(
          'Tasks are curated daily to keep you on track. The Daily Five builds your consistency, LeetCode Grinds sharpen your algorithms, and Core Focus ensures you master foundational subjects required for placements. Completing them every day guarantees readiness!',
          style: GoogleFonts.inter(fontSize: 11, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    final days = <DateTime>[];
    for (int i = -3; i <= 3; i++) {
      days.add(_today.add(Duration(days: i)));
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          final isToday = date.day == _today.day && date.month == _today.month;

          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() {
                  _selectedDate = date;
                });
                _fetchDataForDate(date);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.onSurface : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentCoral : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.accentCoral : AppTheme.illusGold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppTheme.accentCoral.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCoral,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 1: MY TASKS VIEW
  // ==========================================
  Widget _buildMyTasksView(ThemeData theme) {
    final dailyFiveProvider = context.watch<DailyFiveProvider>();
    final isDailyFiveDone = dailyFiveProvider.completedToday;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCoral.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.compass, color: AppTheme.accentCoral),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dailyTasks.length} tasks today',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Small steps. Big impact.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showWhyTasksDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.lightbulb, size: 12, color: AppTheme.accentCoral),
                          const SizedBox(width: 6),
                          Text(
                            'Why tasks?',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Tasks',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.target, size: 12, color: AppTheme.accentCoral),
                        const SizedBox(width: 6),
                        Text(
                          'Focus · Finish · Grow',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _showSortOptions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(LucideIcons.slidersHorizontal, size: 12),
                  label: Text('Sort', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _buildCompletedTaskCard(
                  title: 'Daily Five',
                  tagText: 'Daily',
                  subtitle: 'Complete today\'s 5 questions',
                  progressText: isDailyFiveDone ? '5 / 5 completed' : '0 / 5 completed',
                  icon: LucideIcons.bookOpen,
                  iconColor: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 16),
                if (_isLoadingTasks)
                  const Center(child: CircularProgressIndicator())
                else if (_dailyTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('No tasks uploaded for today yet.', style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    ),
                  )
                else
                  ..._dailyTasks.map((task) {
                    final isLeetcode = task.topicType == TopicType.leetcode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: isLeetcode && _isDayCompleted
                          ? _buildCompletedTaskCard(
                              title: 'LeetCode Grind',
                              tagText: 'Daily',
                              subtitle: task.title,
                              progressText: 'Completed',
                              icon: LucideIcons.code2,
                              iconColor: AppTheme.accentCoral,
                            )
                          : _buildTaskCard(
                              title: isLeetcode ? 'LeetCode Grind' : 'Core Focus',
                              tagText: 'Daily',
                              subtitle: task.title,
                              progressText: _isDayCompleted ? 'Completed' : 'Pending',
                              progressValue: _isDayCompleted ? 1.0 : 0.0,
                              icon: isLeetcode ? LucideIcons.code2 : LucideIcons.bookMarked,
                              iconColor: isLeetcode ? AppTheme.accentCoral : Colors.deepPurple.shade300,
                            ),
                    );
                  }),
                const SizedBox(height: 32),
                
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentCoral,
                    side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 12),
                  label: Text('Add Quick Task', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ALL TASKS VIEW
  // ==========================================
  Widget _buildAllTasksView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Expanded(child: _buildDateSelector()),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
                icon: const Icon(LucideIcons.chevronRight),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Tasks',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 tasks • Reset daily at 12:00 AM',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _showSortOptions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(LucideIcons.slidersHorizontal, size: 12),
                  label: Text('Sort', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                if (_isLoadingTasks)
                  const Center(child: CircularProgressIndicator())
                else if (_dailyTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('No tasks found for this date.', style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    ),
                  )
                else
                  ..._dailyTasks.map((task) {
                    final isLeetcode = task.topicType == TopicType.leetcode;
                    if (_isDayCompleted) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildDetailedCompletedCard(theme, title: isLeetcode ? 'LeetCode Grind' : 'Core Focus', subtitle: task.title),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildDetailedPendingCard(
                          title: isLeetcode ? 'LeetCode Grind' : 'Core Focus',
                          subtitle: task.title,
                          progressText: '0 / 1 completed',
                          tipText: isLeetcode ? 'Solve this problem to level up.' : 'Master this core concept.',
                          icon: isLeetcode ? LucideIcons.code2 : LucideIcons.bookOpen,
                          iconColor: isLeetcode ? AppTheme.accentCoral : Colors.deepPurple.shade300,
                          theme: theme,
                        ),
                      );
                    }
                  }),
                const SizedBox(height: 32),
                
                // Progress Banner Bottom
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: _isDayCompleted ? 1.0 : (_dailyTasks.isEmpty ? 0.0 : 0.0),
                              strokeWidth: 6,
                              backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                              color: AppTheme.accentCoral,
                            ),
                          ),
                          Text(
                            _isDayCompleted ? 'All' : '0',
                            style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isDayCompleted ? 'All tasks completed' : 'Tasks Pending', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_isDayCompleted ? 'Great job finishing today\'s tasks!' : 'You\'re on the right path. Keep going!', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: UPLOAD TASK VIEW
  // ==========================================
  Widget _buildUploadTaskView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upload Tasks',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create or upload tasks in bulk for students.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppTheme.accentCoral.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF4CAF50), size: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bulk Upload via Excel', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Upload multiple tasks at once using an Excel file.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Text('Upload Excel', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.listPlus, color: Colors.orange, size: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Tasks Manually', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Create tasks one by one.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulk Upload via Excel',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentCoral,
                  side: const BorderSide(color: AppTheme.accentCoral),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(LucideIcons.download, size: 12),
                label: Text('Download Template', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Use our template to upload tasks in bulk.', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
          const SizedBox(height: 16),

          // Dropzone
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCoral.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.uploadCloud, color: AppTheme.accentCoral, size: 16),
                ),
                const SizedBox(height: 16),
                Text('Drag & drop your Excel file here', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('or', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCoral,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.uploadCloud, size: 12),
                  label: Text('Choose File', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text('Supports .xlsx, .xls files only', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Maximum file size: ', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.accentCoral)),
                      Text('10MB', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.info, size: 12, color: AppTheme.accentCoral),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Guidelines
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAED), // Very light green
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 8),
                    Text('Excel Format Guidelines', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem('1. Use the provided template for best results.', const Color(0xFF2E7D32)),
                _buildGuidelineItem('2. Do not change the column headers.', const Color(0xFF2E7D32)),
                _buildGuidelineItem('3. Each row will be treated as a separate task.', const Color(0xFF2E7D32)),
                _buildGuidelineItem('4. Date should be in YYYY-MM-DD format.', const Color(0xFF2E7D32)),
                _buildGuidelineItem('5. Allowed task types: Daily 5, LeetCode, Core Focus', const Color(0xFF2E7D32)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text('Recent Uploads', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          _buildRecentUploadCard('Quests_22_May_2025.xlsx', '22 May 2025 • 9:30 AM • 45 tasks', true, theme),
          const SizedBox(height: 12),
          _buildRecentUploadCard('Quests_21_May_2025.xlsx', '21 May 2025 • 4:15 PM • 32 tasks', true, theme),
          const SizedBox(height: 12),
          _buildRecentUploadCard('Quests_20_May_2025.xlsx', '20 May 2025 • 11:05 AM • 28 tasks', false, theme),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Widget _buildTaskCard({
    required String title,
    required String tagText,
    required String subtitle,
    required String progressText,
    required double progressValue,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
                      child: Text(tagText, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(progressText, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                    Text('+10 Pulse', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: AppTheme.accentCoral,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(LucideIcons.chevronRight, size: 16, color: theme.dividerColor),
        ],
      ),
    );
  }

  Widget _buildCompletedTaskCard({
    required String title,
    required String tagText,
    required String subtitle,
    required String progressText,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                          child: Text(tagText, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(progressText, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                        Text('+10 Pulse', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.transparent,
                        color: Color(0xFF4CAF50),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.chevronRight, size: 16, color: theme.dividerColor),
            ],
          ),
        ),
        Positioned(
          left: -8,
          top: 40,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedCompletedCard(ThemeData theme, {required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.clipboardCheck, color: Color(0xFF4CAF50), size: 16),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                                child: Text('Daily', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 12, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 4),
                                Text('Completed', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5 / 5 completed', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                          Text('+10 Pulse', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(value: 1.0, backgroundColor: Colors.transparent, color: Color(0xFF4CAF50), minHeight: 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 16, color: theme.dividerColor),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F1),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Great job! Consistency is your superpower.', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: const Color(0xFF2E7D32))),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedPendingCard({
    required String title,
    required String subtitle,
    required String progressText,
    required String tipText,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
                                child: Text('Daily', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.circle, size: 12, color: theme.dividerColor),
                                const SizedBox(width: 4),
                                Text('Pending', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(progressText, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                          Text('+10 Pulse', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: 0.0, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppTheme.accentCoral, minHeight: 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 16, color: theme.dividerColor),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 12, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(tipText, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: iconColor.withValues(alpha: 0.8)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, color: color.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _buildRecentUploadCard(String filename, String details, bool isSuccess, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.fileSpreadsheet, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text(details, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSuccess ? const Color(0xFF4CAF50).withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(isSuccess ? Icons.check : Icons.close, size: 12, color: isSuccess ? const Color(0xFF4CAF50) : Colors.red),
                const SizedBox(width: 4),
                Text(isSuccess ? 'Completed' : 'Failed', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: isSuccess ? const Color(0xFF4CAF50) : Colors.red)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.moreVertical, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
