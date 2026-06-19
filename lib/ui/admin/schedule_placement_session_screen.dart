import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/team.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../services/placement_session_service.dart';
import '../../services/batch_service.dart';
import '../../core/theme/app_dimens.dart';

class SchedulePlacementSessionScreen extends StatefulWidget {
  const SchedulePlacementSessionScreen({super.key});

  @override
  State<SchedulePlacementSessionScreen> createState() => _SchedulePlacementSessionScreenState();
}

class _SchedulePlacementSessionScreenState extends State<SchedulePlacementSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  
  late final PlacementSessionService _sessionService;
  late final BatchService _batchService;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0); // 5 PM
  
  List<Team> _availableTeams = [];
  Set<String> _selectedTeamIds = {};
  bool _isBatchWide = true;
  
  bool _isLoadingTeams = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sessionService = PlacementSessionService(Supabase.instance.client);
    _batchService = BatchService(Supabase.instance.client);
    _loadTeams();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final user = context.read<UserProvider>().currentUser!;
      final teams = await _batchService.fetchTeamsForBatch(user.batchId!);
      if (mounted) {
        setState(() {
          _availableTeams = teams;
          _isLoadingTeams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teams: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isBatchWide && _selectedTeamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one team')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = context.read<UserProvider>().currentUser!;
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _sessionService.schedulePlacementSession(
        batchId: user.batchId!,
        scheduledBy: user.uid,
        sessionDatetime: finalDateTime,
        topic: _topicController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        targetTeamIds: _isBatchWide ? null : _selectedTeamIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context); // Go back
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session scheduled successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    if (!userProvider.hasPermission(UserPermission.schedulePlacementSessions)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule Session')),
        body: const Center(child: Text('You lack permission to schedule sessions.')),
      );
    }

    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Placement Session')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                hintText: 'e.g. System Design Mock Interviews',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Any prerequisites or notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text('Date & Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateFormat.format(_selectedDate)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text('Target Audience', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Entire Batch'), icon: Icon(Icons.group)),
                ButtonSegment(value: false, label: Text('Specific Teams'), icon: Icon(Icons.safety_divider)),
              ],
              selected: {_isBatchWide},
              onSelectionChanged: (set) => setState(() => _isBatchWide = set.first),
            ),
            
            if (!_isBatchWide) ...[
              const SizedBox(height: AppSpacing.md),
              if (_isLoadingTeams)
                const Center(child: CircularProgressIndicator())
              else if (_availableTeams.isEmpty)
                const Text('No teams found in this batch.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTeams.map((team) {
                    final isSelected = _selectedTeamIds.contains(team.id);
                    return FilterChip(
                      label: Text(team.teamName),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedTeamIds.add(team.id);
                          else _selectedTeamIds.remove(team.id);
                        });
                      },
                    );
                  }).toList(),
                )
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Schedule Session'),
          ),
        ),
      ),
    );
  }
}
