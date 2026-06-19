import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/company.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../providers/placement_log_provider.dart';
import '../../core/theme/app_dimens.dart';

class PlacementLogScreen extends StatefulWidget {
  const PlacementLogScreen({super.key});

  @override
  State<PlacementLogScreen> createState() => _PlacementLogScreenState();
}

class _PlacementLogScreenState extends State<PlacementLogScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      context.read<PlacementLogProvider>().loadCompanies(
            batchId: user?.batchId,
          );
    });
  }

  void _showAddCompanySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddCompanySheet(
        onSaved: () {
          final user = context.read<UserProvider>().currentUser;
          context
              .read<PlacementLogProvider>()
              .loadCompanies(batchId: user?.batchId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final canManage =
        userProvider.hasPermission(UserPermission.manageCompanyRecords);
    final provider = context.watch<PlacementLogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search companies…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddCompanySheet(context),
              icon: const Icon(Icons.business),
              label: const Text('Add Company'),
            )
          : null,
      body: _buildBody(theme, provider),
    );
  }

  Widget _buildBody(ThemeData theme, PlacementLogProvider provider) {
    if (provider.isLoadingCompanies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                provider.clearError();
                final user = context.read<UserProvider>().currentUser;
                provider.loadCompanies(batchId: user?.batchId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.companies.isEmpty) {
      return const Center(child: Text('No companies found.'));
    }

    final filtered = provider.companies
        .where((c) => c.name.toLowerCase().contains(_searchQuery))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final company = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(company.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(company.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(company.packageBand ?? company.eligibility ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.push('/placement-log/company/${company.id}', extra: company),
          ),
        );
      },
    );
  }
}

// ── Add Company Sheet ──────────────────────────────────────────────────────

class _AddCompanySheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddCompanySheet({required this.onSaved});

  @override
  State<_AddCompanySheet> createState() => _AddCompanySheetState();
}

class _AddCompanySheetState extends State<_AddCompanySheet> {
  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final user = context.read<UserProvider>().currentUser!;
      if (user.batchId == null) throw Exception('No batch ID found for user');
      
      await context.read<PlacementLogProvider>().createCompany(
            name: name,
            batchId: user.batchId!,
            industry: _industryCtrl.text.trim().isEmpty
                ? null
                : _industryCtrl.text.trim(),
            website:
                _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
            createdBy: user.uid,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Company',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Company Name *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _industryCtrl,
            decoration: const InputDecoration(
                labelText: 'Industry', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _websiteCtrl,
            decoration: const InputDecoration(
                labelText: 'Website', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Company'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
