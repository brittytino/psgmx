import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/premium_card.dart';
import '../../../core/theme/app_dimens.dart';

class AnnouncementsList extends StatelessWidget {
  const AnnouncementsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnnouncementProvider, UserProvider>(
      builder: (context, provider, userProvider, child) {
        if (provider.isLoading && provider.announcements.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.announcements.isEmpty) {
          return const SizedBox.shrink();
        }

        // Check if user can manage announcements
        final canManage =
            userProvider.isPlacementRep || userProvider.isCoordinator;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    'Announcements',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const Spacer(),
                  if (canManage)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      tooltip: 'Add Announcement',
                      onPressed: () => _showCreateDialog(context),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.announcements.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = provider.announcements[index];
                return PremiumCard(
                  hasBorder: true,
                  color: item.isPriority
                      ? Colors.red.withValues(alpha: 0.05)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isPriority)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.campaign,
                                  color: Colors.red, size: 20),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: item.isPriority ? Colors.red : null,
                                  ),
                            ),
                          ),
                          Text(
                            _formatDate(item.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _confirmDelete(
                                  context, provider, item.id, item.title),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 180/255),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      // Show expiry if set
                      if (item.expiryDate != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Expires: ${_formatFullDate(item.expiryDate!)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AnnouncementProvider provider,
      String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteAnnouncement(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Announcement deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isPriority = false;
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Priority'),
                  subtitle: const Text('Show as urgent'),
                  value: isPriority,
                  onChanged: (v) => setState(() => isPriority = v),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    expiryDate != null
                        ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                        : 'No expiry (permanent)',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => expiryDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => expiryDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    messageController.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await context.read<AnnouncementProvider>().createAnnouncement(
                        title: titleController.text,
                        message: messageController.text,
                        isPriority: isPriority,
                        expiry: expiryDate,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Announcement created'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
