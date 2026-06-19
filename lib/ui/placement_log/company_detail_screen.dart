import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/company.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../providers/placement_log_provider.dart';
import '../../core/theme/app_dimens.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Company company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlacementLogProvider>().loadEntries(widget.company.id);
    });
  }

  void _showAddLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddLogSheet(
        company: widget.company,
      ),
    );
  }

  Future<void> _toggleModeration(
      BuildContext context, PlacementLogEntry log, bool isApproved) async {
    try {
      final user = context.read<UserProvider>().currentUser!;
      await context.read<PlacementLogProvider>().moderateEntry(
            logId: log.id,
            moderatedBy: user.uid,
            isApproved: isApproved,
            companyId: widget.company.id,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final canModerate =
        userProvider.hasPermission(UserPermission.moderatePlacementLog);
    final provider = context.watch<PlacementLogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.company.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogSheet(context),
        icon: const Icon(Icons.edit_document),
        label: const Text('Add Experience'),
      ),
      body: _buildBody(context, theme, provider, canModerate),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme,
      PlacementLogProvider provider, bool canModerate) {
    if (provider.isLoadingEntriesFor(widget.company.id)) {
      return const Center(child: CircularProgressIndicator());
    }

    final logs = provider.entriesFor(widget.company.id);

    // Filter out unapproved if not moderator
    final visibleLogs = canModerate
        ? logs
        : logs.where((l) => !l.isModerated).toList();

    if (visibleLogs.isEmpty) {
      return const Center(child: Text('No experiences shared yet. Be the first!'));
    }

    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: visibleLogs.length,
      itemBuilder: (context, index) {
        final log = visibleLogs[index];
        final isAuthor =
            log.userId == context.read<UserProvider>().currentUser?.uid;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.roundName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: log.outcome == 'offer'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (log.outcome ?? 'interviewing').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: log.outcome == 'offer'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'By ${log.isAnonymous ?? false ? "Anonymous" : "Student"} • ${dateFormat.format(log.createdAt)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),
                Text(log.experienceText),
                if (canModerate || isAuthor) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      if (log.isModerated)
                        const Row(
                          children: [
                            Icon(Icons.visibility_off,
                                size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text('Hidden (Moderated)',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                        ),
                      if (!log.isModerated && canModerate)
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Approved',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      const Spacer(),
                      if (canModerate) ...[
                        if (log.isModerated)
                          TextButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            onPressed: () =>
                                _toggleModeration(context, log, true),
                          )
                        else
                          TextButton.icon(
                            icon: const Icon(Icons.visibility_off,
                                size: 16, color: Colors.red),
                            label: const Text('Hide',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () =>
                                _toggleModeration(context, log, false),
                          ),
                      ],
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Add Log Sheet ──────────────────────────────────────────────────────────

class _AddLogSheet extends StatefulWidget {
  final Company company;

  const _AddLogSheet({required this.company});

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  final _formKey = GlobalKey<FormState>();
  final _roleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _outcome = 'interviewing';
  bool _isAnonymous = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _roleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = context.read<UserProvider>().currentUser!;
      await context.read<PlacementLogProvider>().addEntry(
            companyId: widget.company.id,
            studentId: user.uid,
            roleOffered: _roleCtrl.text.trim(),
            interviewDate: _date,
            outcome: _outcome,
            experienceContent: _contentCtrl.text.trim(),
            isAnonymous: _isAnonymous,
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Share Experience: ${widget.company.name}'),
          leading: CloseButton(onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('Submit')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _roleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Role (e.g. SDE 1, Data Analyst)',
                  border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _outcome,
                    decoration: const InputDecoration(
                        labelText: 'Outcome', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'offer', child: Text('Offer')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                      DropdownMenuItem(
                          value: 'interviewing', child: Text('Interviewing')),
                      DropdownMenuItem(value: 'no_show', child: Text('No Show')),
                    ],
                    onChanged: (v) => setState(() => _outcome = v!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM d, yyyy').format(_date)),
                    onPressed: _pickDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Interview Experience / Details',
                hintText: 'Rounds, questions asked, tips...',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Post Anonymously'),
              subtitle: const Text('Your name will be hidden from other students.'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),
          ],
        ),
      ),
    );
  }
}
