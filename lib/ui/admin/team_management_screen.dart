import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/team.dart';
import '../../models/app_user.dart';
import '../../models/user_permission.dart';
import '../../providers/user_provider.dart';
import '../../services/batch_service.dart';
import '../../core/theme/app_dimens.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final BatchService _batchService;
  List<Team>? _teams;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _batchService = BatchService(Supabase.instance.client);
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null || user.batchId == null) throw Exception('No batch ID found');
      
      final teams = await _batchService.fetchTeamsForBatch(user.batchId!);
      
      // Load members for each team
      final teamsWithMembers = <Team>[];
      for (final team in teams) {
        final fullTeam = await _batchService.fetchTeamWithMembers(team.id);
        teamsWithMembers.add(fullTeam);
      }
      
      if (mounted) {
        setState(() {
          _teams = teamsWithMembers;
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

  Future<void> _showAutoDistributeDialog() async {
    final sizeController = TextEditingController(text: '6');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Distribute Teams'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will delete all current teams and re-assign all students '
                'in the batch round-robin. This action cannot be undone.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Team Size',
                  border: OutlineInputBorder(),
                  helperText: 'Usually 5-10 students',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  final size = int.tryParse(val);
                  if (size == null) return 'Must be a number';
                  if (size < 3 || size > 20) return 'Must be between 3 and 20';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, int.parse(sizeController.text));
              }
            },
            child: const Text('Distribute'),
          ),
        ],
      ),
    );

    if (result != null) {
      _performAutoDistribution(result);
    }
  }

  Future<void> _performAutoDistribution(int targetSize) async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>().currentUser;
      await _batchService.autoDistributeTeams(
        batchId: user!.batchId!,
        targetSize: targetSize,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-distribution complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _loadTeams();
    }
  }

  Future<void> _assignLeader(Team team, AppUser member) async {
    try {
      await _batchService.assignTeamLeader(
        teamId: team.id,
        leaderId: member.uid,
      );
      _loadTeams(); // Reload to show updated leader
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign leader: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check permission
    final userProvider = context.watch<UserProvider>();
    if (!userProvider.hasPermission(UserPermission.configureTeams)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Management')),
        body: const Center(
          child: Text('You do not have permission to configure teams.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAutoDistributeDialog,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Auto-Distribute'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading teams: $_error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTeams,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teams == null || _teams!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No teams found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Use Auto-Distribute to create teams\nand assign students automatically.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: 100, // Space for FAB
      ),
      itemCount: _teams!.length,
      itemBuilder: (context, index) {
        final team = _teams![index];
        return _TeamCard(
          team: team,
          onAssignLeader: (member) => _assignLeader(team, member),
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final void Function(AppUser) onAssignLeader;

  const _TeamCard({
    required this.team,
    required this.onAssignLeader,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: Text('${team.memberCount}'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Target Size: ${team.targetSize}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Member List
          if (team.members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: Text('No members in this team')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: team.members.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final member = team.members[index];
                final isLeader = member.uid == team.teamLeaderId;
                
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isLeader 
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12, 
                        color: isLeader ? theme.colorScheme.onTertiary : theme.colorScheme.onSurfaceVariant
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: TextStyle(fontWeight: isLeader ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Text(member.regNo),
                  trailing: isLeader
                    ? Chip(
                        label: const Text('Leader', style: TextStyle(fontSize: 10)),
                        backgroundColor: theme.colorScheme.tertiaryContainer,
                        labelStyle: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'leader') {
                            onAssignLeader(member);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'leader',
                            child: Text('Make Team Leader'),
                          ),
                          // TODO: Implement move to another team if time permits
                        ],
                      ),
                );
              },
            ),
        ],
      ),
    );
  }
}
