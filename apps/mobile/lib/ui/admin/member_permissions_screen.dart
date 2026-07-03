import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../services/permission_service.dart';
import '../../core/theme/app_dimens.dart';

class MemberPermissionsScreen extends StatefulWidget {
  const MemberPermissionsScreen({super.key});

  @override
  State<MemberPermissionsScreen> createState() => _MemberPermissionsScreenState();
}

class _MemberPermissionsScreenState extends State<MemberPermissionsScreen> {
  late final PermissionService _permissionService;
  List<AppUser>? _users;
  Map<String, Set<UserPermission>> _userPermissions = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _permissionService = PermissionService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;
      if (currentUser == null || currentUser.batchId == null) {
        throw Exception('No batch ID found');
      }

      // Fetch all users in batch
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('batch_id', currentUser.batchId!)
          .order('reg_no');
      
      final users = (response as List).map((r) => AppUser.fromMap(r)).toList();
      
      // Fetch permissions map
      final permissionsMap = await _permissionService.fetchBatchPermissions(currentUser.batchId!);

      if (mounted) {
        setState(() {
          _users = users;
          _userPermissions = permissionsMap;
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

  void _showPermissionEditor(AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _PermissionEditorSheet(
        user: user,
        initialPermissions: _userPermissions[user.uid] ?? {},
        permissionService: _permissionService,
        currentUserId: context.read<UserProvider>().currentUser!.uid,
        onSaved: () => _loadData(), // Reload after save
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check permission
    final userProvider = context.watch<UserProvider>();
    if (!userProvider.hasPermission(UserPermission.manageMembers)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Permissions')),
        body: const Center(
          child: Text('You do not have permission to manage members.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Permissions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or roll no...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
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
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    if (_users == null || _users!.isEmpty) {
      return const Center(child: Text('No users found in your batch.'));
    }

    final filteredUsers = _users!.where((u) => 
      u.name.toLowerCase().contains(_searchQuery) || 
      u.regNo.toLowerCase().contains(_searchQuery)
    ).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: filteredUsers.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final perms = _userPermissions[user.uid] ?? {};
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(user.name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (perms.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${perms.length} perms',
                    style: TextStyle(fontSize: 8, color: theme.colorScheme.onTertiaryContainer),
                  ),
                ),
            ],
          ),
          subtitle: Text('${user.regNo} • ${user.roleLabel}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPermissionEditor(user),
        );
      },
    );
  }
}

class _PermissionEditorSheet extends StatefulWidget {
  final AppUser user;
  final Set<UserPermission> initialPermissions;
  final PermissionService permissionService;
  final String currentUserId;
  final VoidCallback onSaved;

  const _PermissionEditorSheet({
    required this.user,
    required this.initialPermissions,
    required this.permissionService,
    required this.currentUserId,
    required this.onSaved,
  });

  @override
  State<_PermissionEditorSheet> createState() => _PermissionEditorSheetState();
}

class _PermissionEditorSheetState extends State<_PermissionEditorSheet> {
  late Set<UserPermission> _selectedPerms;
  late TextEditingController _roleLabelCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPerms = Set.from(widget.initialPermissions);
    _roleLabelCtrl = TextEditingController(text: widget.user.roleLabel);
  }

  @override
  void dispose() {
    _roleLabelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      // Save label
      await widget.permissionService.setRoleLabel(
        setBy: widget.currentUserId,
        targetUserId: widget.user.uid,
        label: _roleLabelCtrl.text.trim(),
      );
      
      // Save perms
      await widget.permissionService.setPermissions(
        setBy: widget.currentUserId,
        targetUserId: widget.user.uid,
        newPermissions: _selectedPerms,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      if (preset == 'Rep') {
        _selectedPerms = Set.from(kPlacementRepPermissions);
        _roleLabelCtrl.text = 'Placement Rep';
      } else if (preset == 'Leader') {
        _selectedPerms = Set.from(kTeamLeaderPermissions);
        _roleLabelCtrl.text = 'Team Leader';
      } else if (preset == 'Student') {
        _selectedPerms.clear();
        _roleLabelCtrl.text = 'Student';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(widget.user.name[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.user.regNo, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                CloseButton(onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Presets
                Text('Quick Presets', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _applyPreset('Student'),
                        child: const Text('Student'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _applyPreset('Leader'),
                        child: const Text('Team Leader'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _applyPreset('Rep'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: const Text('Rep'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Role Label
                TextField(
                  controller: _roleLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Role Label (Cosmetic)',
                    helperText: 'Displayed in UI (e.g. "Coordinator")',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                Text('Access Capabilities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                
                // Flags
                ...UserPermission.values.map((perm) {
                  return CheckboxListTile(
                    title: Text(perm.displayName),
                    subtitle: Text('Flag: ${perm.dbKey}', style: TextStyle(fontSize: 8, color: theme.colorScheme.outline)),
                    value: _selectedPerms.contains(perm),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPerms.add(perm);
                        } else {
                          _selectedPerms.remove(perm);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ],
            ),
          ),
          
          // Footer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Permissions'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
