import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/placement_session.dart';
import '../../models/user_permission.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../services/placement_session_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';
import 'package:go_router/go_router.dart';

class PlacementSessionsScreen extends StatefulWidget {
  const PlacementSessionsScreen({super.key});

  @override
  State<PlacementSessionsScreen> createState() => _PlacementSessionsScreenState();
}

class _PlacementSessionsScreenState extends State<PlacementSessionsScreen> {
  late final PlacementSessionService _sessionService;
  List<PlacementSession>? _sessions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionService = PlacementSessionService(Supabase.instance.client);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null || user.batchId == null) throw Exception('No batch ID found');
      
      final sessions = await _sessionService.fetchSessionsForBatch(user.batchId!);
      
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _markAttendance(PlacementSession session) async {
    // Navigate to attendance marking (placeholder for now or we build it inline)
    // Actually, marking attendance might need a separate screen, but let's build a simple dialog/sheet.
    // For now, let's just show a bottom sheet with students.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AttendanceMarkerSheet(
        session: session,
        sessionService: _sessionService,
        onSaved: _loadSessions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final canSchedule = userProvider.hasPermission(UserPermission.schedulePlacementSessions);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Sessions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSessions),
        ],
      ),
      floatingActionButton: canSchedule ? FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/schedule-session');
          _loadSessions();
        },
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ) : null,
      body: _buildBody(theme, userProvider),
    );
  }

  Widget _buildBody(ThemeData theme, UserProvider userProvider) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            FilledButton(onPressed: _loadSessions, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    if (_sessions == null || _sessions!.isEmpty) {
      return const Center(child: Text('No placement sessions found.'));
    }

    final now = DateTime.now();
    final upcoming = _sessions!.where((s) => s.sessionDatetime.isAfter(now)).toList();
    final past = _sessions!.where((s) => s.sessionDatetime.isBefore(now)).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text('Upcoming Sessions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: AppSpacing.sm),
          ...upcoming.map((s) => _SessionCard(
            session: s, 
            onTap: () => _markAttendance(s),
            canMark: userProvider.hasPermission(UserPermission.markPlacementAttendance),
          )),
          const SizedBox(height: AppSpacing.xl),
        ],
        
        if (past.isNotEmpty) ...[
          Text('Past Sessions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          ...past.map((s) => _SessionCard(
            session: s, 
            onTap: () => _markAttendance(s),
            canMark: userProvider.hasPermission(UserPermission.markPlacementAttendance),
          )),
        ],
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PlacementSession session;
  final VoidCallback onTap;
  final bool canMark;

  const _SessionCard({required this.session, required this.onTap, required this.canMark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final isPast = session.sessionDatetime.isBefore(DateTime.now());

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: canMark ? onTap : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPast ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_note, 
                color: isPast ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.topic, 
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isPast ? theme.colorScheme.onSurfaceVariant : null),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(session.sessionDatetime),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (session.description != null && session.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (canMark) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.checklist, color: theme.colorScheme.primary),
            ]
          ],
        ),
      ),
    );
  }
}

class _AttendanceMarkerSheet extends StatefulWidget {
  final PlacementSession session;
  final PlacementSessionService sessionService;
  final VoidCallback onSaved;

  const _AttendanceMarkerSheet({
    required this.session,
    required this.sessionService,
    required this.onSaved,
  });

  @override
  State<_AttendanceMarkerSheet> createState() => _AttendanceMarkerSheetState();
}

class _AttendanceMarkerSheetState extends State<_AttendanceMarkerSheet> {
  List<AppUser>? _eligibleStudents;
  Map<String, PlacementAttendanceStatus> _attendanceState = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await widget.sessionService.fetchEligibleStudents(widget.session);
      
      // Attempt to load existing records
      final existingRecords = await widget.sessionService.fetchSessionAttendance(widget.session.id);
      final existingMap = { for (var r in existingRecords) r.userId : r.status };

      // Initialize state (default absent if past, none if upcoming)
      final state = <String, PlacementAttendanceStatus>{};
      for (final s in students) {
        state[s.uid] = existingMap[s.uid] ?? PlacementAttendanceStatus.absent;
      }

      if (mounted) {
        setState(() {
          _eligibleStudents = students;
          _attendanceState = state;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user = context.read<UserProvider>().currentUser!;
      await widget.sessionService.markSessionAttendance(
        sessionId: widget.session.id, 
        markedBy: user.uid, 
        records: _attendanceState,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark Attendance', style: TextStyle(fontSize: 16)),
            Text(widget.session.topic, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        leading: CloseButton(onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark All Present'),
            onPressed: () {
              setState(() {
                for (final k in _attendanceState.keys) {
                  _attendanceState[k] = PlacementAttendanceStatus.present;
                }
              });
            },
          ),
        ],
      ),
      body: _eligibleStudents == null || _eligibleStudents!.isEmpty
        ? const Center(child: Text('No eligible students found.'))
        : ListView.separated(
            itemCount: _eligibleStudents!.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = _eligibleStudents![index];
              final currentStatus = _attendanceState[student.uid]!;
              final isPresent = currentStatus == PlacementAttendanceStatus.present;

              return ListTile(
                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(student.regNo),
                trailing: Switch(
                  value: isPresent,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      _attendanceState[student.uid] = val ? PlacementAttendanceStatus.present : PlacementAttendanceStatus.absent;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _attendanceState[student.uid] = isPresent ? PlacementAttendanceStatus.absent : PlacementAttendanceStatus.present;
                  });
                },
              );
            },
          ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Attendance'),
          ),
        ),
      ),
    );
  }
}
