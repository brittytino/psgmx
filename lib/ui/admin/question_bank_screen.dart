import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/daily_five.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../services/daily_five_service.dart';
import '../../core/theme/app_dimens.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  late final DailyFiveService _service;
  List<DailyFiveQuestion>? _questions;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = DailyFiveService(Supabase.instance.client);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final questions = await _service.fetchAllQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
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

  void _showEditor([DailyFiveQuestion? question]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _QuestionEditorSheet(
        service: _service,
        initialQuestion: question,
        onSaved: _loadQuestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    
    if (!userProvider.hasPermission(UserPermission.publishTasks)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question Bank')),
        body: const Center(child: Text('You do not have permission to manage questions.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQuestions),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search topic or text...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            FilledButton(onPressed: _loadQuestions, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    if (_questions == null || _questions!.isEmpty) {
      return const Center(child: Text('Question bank is empty.'));
    }

    final filtered = _questions!.where((q) {
      return q.topic.toLowerCase().contains(_searchQuery) || 
             q.questionText.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final q = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${q.topic.toUpperCase()} • ${q.difficulty}', style: TextStyle(color: theme.colorScheme.primary)),
            trailing: q.isActive ? null : const Chip(label: Text('Inactive'), visualDensity: VisualDensity.compact),
            onTap: () => _showEditor(q),
          ),
        );
      },
    );
  }
}

class _QuestionEditorSheet extends StatefulWidget {
  final DailyFiveService service;
  final DailyFiveQuestion? initialQuestion;
  final VoidCallback onSaved;

  const _QuestionEditorSheet({required this.service, this.initialQuestion, required this.onSaved});

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textCtrl;
  late List<TextEditingController> _optCtrls;
  late String _topic;
  late String _difficulty;
  late int _correctIdx;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    _textCtrl = TextEditingController(text: q?.questionText ?? '');
    _optCtrls = List.generate(4, (i) => TextEditingController(text: q?.options[i] ?? ''));
    _topic = q?.topic ?? 'dsa';
    _difficulty = q?.difficulty ?? 'medium';
    _correctIdx = q?.correctOption ?? 0;
    _isActive = q?.isActive ?? true;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (var c in _optCtrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    try {
      final user = context.read<UserProvider>().currentUser!;
      final options = _optCtrls.map((c) => c.text.trim()).toList();
      
      if (widget.initialQuestion == null) {
        await widget.service.createQuestion(
          createdBy: user.uid,
          questionText: _textCtrl.text.trim(),
          options: options,
          correctOption: _correctIdx,
          topic: _topic,
          difficulty: _difficulty,
        );
      } else {
        await widget.service.updateQuestion(
          questionId: widget.initialQuestion!.id,
          questionText: _textCtrl.text.trim(),
          options: options,
          correctOption: _correctIdx,
          topic: _topic,
          difficulty: _difficulty,
          isActive: _isActive,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialQuestion == null ? 'New Question' : 'Edit Question'),
          leading: CloseButton(onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(onPressed: _isSaving ? null : _save, child: const Text('Save')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _topic,
                    decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'dsa', child: Text('DSA')),
                      DropdownMenuItem(value: 'dbms', child: Text('DBMS')),
                      DropdownMenuItem(value: 'os', child: Text('OS')),
                      DropdownMenuItem(value: 'networks', child: Text('Networks')),
                      DropdownMenuItem(value: 'oops', child: Text('OOPs')),
                      DropdownMenuItem(value: 'aptitude', child: Text('Aptitude')),
                    ],
                    onChanged: (v) => setState(() => _topic = v!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            TextFormField(
              controller: _textCtrl,
              decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            const Text('Options (Select the correct one)'),
            const SizedBox(height: AppSpacing.sm),
            
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctIdx,
                      onChanged: (v) => setState(() => _correctIdx = v!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optCtrls[i],
                        decoration: InputDecoration(labelText: 'Option ${i+1}', border: const OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            if (widget.initialQuestion != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Inactive questions won\'t be picked'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
