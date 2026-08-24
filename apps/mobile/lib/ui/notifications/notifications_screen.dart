import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<NotificationService>().getNotifications();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.motivation:
        return LucideIcons.flame;
      case NotificationType.reminder:
        return LucideIcons.calendarClock;
      case NotificationType.alert:
        return LucideIcons.bellRing;
      case NotificationType.announcement:
        return LucideIcons.megaphone;
      case NotificationType.leetcode:
        return LucideIcons.code;
      case NotificationType.birthday:
        return LucideIcons.gift;
      case NotificationType.attendance:
        return LucideIcons.users;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    if (that == today) return DateFormat('h:mm a').format(local);
    if (that == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<NotificationService>(
                  builder: (context, service, _) {
                    final unread = service.notifications.where((n) => n.isRead != true).length;
                    if (unread == 0) return const SizedBox.shrink();
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentCoral,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Stay updated, stay ahead.',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<NotificationService>(
            builder: (context, service, _) {
              final hasUnread = service.notifications.any((n) => n.isRead != true);
              return TextButton(
                onPressed: hasUnread ? () => service.markAllAsRead() : null,
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasUnread ? AppTheme.accentCoral : theme.disabledColor,
                  ),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.settings, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, _) {
          if (service.isLoading && service.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral));
          }

          if (_error != null && service.notifications.isEmpty) {
            return _buildErrorState(theme);
          }

          if (service.notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          final buckets = _bucket(service.notifications);

          return RefreshIndicator(
            color: AppTheme.accentCoral,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (buckets['unread']!.isNotEmpty) ...[
                    _buildSectionHeader('UNREAD', theme),
                    ...buckets['unread']!.map((n) => _buildNotificationTile(n, theme, service)),
                  ],
                  if (buckets['today']!.isNotEmpty) ...[
                    _buildSectionHeader('TODAY', theme),
                    ...buckets['today']!.map((n) => _buildNotificationTile(n, theme, service)),
                  ],
                  if (buckets['week']!.isNotEmpty) ...[
                    _buildSectionHeader('THIS WEEK', theme),
                    ...buckets['week']!.map((n) => _buildNotificationTile(n, theme, service)),
                  ],
                  if (buckets['earlier']!.isNotEmpty) ...[
                    _buildSectionHeader('EARLIER', theme),
                    ...buckets['earlier']!.map((n) => _buildNotificationTile(n, theme, service)),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bell, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Text(
                          'Manage notification preferences >',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Buckets notifications into Unread / Today / This Week / Earlier.
  /// A read notification never appears in "Unread" even if it's from today —
  /// it falls through to whichever time bucket matches its date instead.
  Map<String, List<AppNotification>> _bucket(List<AppNotification> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final unread = <AppNotification>[];
    final todayList = <AppNotification>[];
    final week = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in all) {
      if (n.isRead != true) {
        unread.add(n);
        continue;
      }
      final local = n.generatedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day == today) {
        todayList.add(n);
      } else if (day.isAfter(weekAgo)) {
        week.add(n);
      } else {
        earlier.add(n);
      }
    }

    return {'unread': unread, 'today': todayList, 'week': week, 'earlier': earlier};
  }

  Widget _buildEmptyState(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bellOff, size: 32, color: AppTheme.accentCoral),
                  ),
                  const SizedBox(height: 16),
                  Text("You're all caught up", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text(
                    'New announcements, reminders and streak updates will show up here.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.wifiOff, size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text('Could not load notifications', style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text(_error ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(LucideIcons.refreshCw, size: 14),
                    label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accentCoral),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification n, ThemeData theme, NotificationService service) {
    final isUnread = n.isRead != true;
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => service.deleteNotification(n.id),
      background: Container(
        color: AppTheme.accentCoral,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Dismiss',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: isUnread ? () => service.markAsRead(n.id) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          color: isUnread ? const Color(0xFFFAF9F6) : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Icon(_iconFor(n.type), size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(n.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isUnread ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
