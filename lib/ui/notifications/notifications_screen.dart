import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart' as model;
import '../../core/theme/app_dimens.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false)
          .getNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifService = Provider.of<NotificationService>(context);

    // Filter Logic
    final allNotifications = notifService.notifications;
    final unreadNotifications = allNotifications
        .where((n) => n.isRead == false || n.isRead == null)
        .toList();
    final importantNotifications = allNotifications.where((n) {
      return n.type == model.NotificationType.alert ||
          n.type == model.NotificationType.announcement ||
          n.type == model.NotificationType.attendance;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (unreadNotifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () async {
                  await notifService.markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All marked as read'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.done_all_rounded,
                    size: 18, color: colorScheme.primary),
                label: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            height: 45,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              padding: const EdgeInsets.all(4),
              tabs: [
                const Tab(text: 'All'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Unread'),
                      if (unreadNotifications.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadNotifications.length > 9
                                ? '9+'
                                : unreadNotifications.length.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Important'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: notifService.getNotifications,
        color: colorScheme.primary,
        child: notifService.isLoading && allNotifications.isEmpty
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : allNotifications.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: _EmptyState()),
                      ),
                    ],
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _NotificationList(notifications: allNotifications),
                      _NotificationList(notifications: unreadNotifications),
                      _NotificationList(notifications: importantNotifications),
                    ],
                  ),
      ),
    );
  }
}


class _NotificationList extends StatelessWidget {
  final List<model.AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyListState();
    }

    // Group by date
    final grouped = <String, List<model.AppNotification>>{};
    for (final notif in notifications) {
      final dateKey = DateFormat('yyyy-MM-dd').format(notif.generatedAt);
      grouped.putIfAbsent(dateKey, () => []).add(notif);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateNotifications = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                top: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                _formatDateHeader(date),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...dateNotifications.map(
                (notif) => _NotificationCard(notification: notif)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final model.AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifService =
        Provider.of<NotificationService>(context, listen: false);

    final isUnread = notification.isRead != true;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: GoogleFonts.inter(
                  color: colorScheme.onError, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline, color: colorScheme.onError),
          ],
        ),
      ),
      onDismissed: (_) async {
        await notifService.deleteNotification(notification.id); // Ensure delete exists
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        elevation: isUnread ? 2 : 0,
        color: isUnread ? colorScheme.surface : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isUnread
              ? BorderSide.none
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1), width: 1),
        ),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () async {
            if (isUnread) {
              await notifService.markAsRead(notification.id);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.notificationType, colorScheme)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      _getTypeIcon(notification.notificationType),
                      color: _getTypeColor(notification.notificationType, colorScheme),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isUnread
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.generatedAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(model.NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case model.NotificationType.alert:
        return colorScheme.error;
      case model.NotificationType.motivation:
        return Colors.purpleAccent;
      case model.NotificationType.reminder:
        return Colors.blue;
      case model.NotificationType.announcement:
        return Colors.orange;
      case model.NotificationType.leetcode:
        return const Color(0xFFFFA116);
      case model.NotificationType.birthday:
        return Colors.pinkAccent;
      case model.NotificationType.attendance:
        return Colors.teal;
    }
  }

  FaIconData _getTypeIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.alert:
        return FontAwesomeIcons.bell;
      case model.NotificationType.motivation:
        return FontAwesomeIcons.fire;
      case model.NotificationType.reminder:
        return FontAwesomeIcons.clock;
      case model.NotificationType.announcement:
        return FontAwesomeIcons.bullhorn;
      case model.NotificationType.leetcode:
        return FontAwesomeIcons.code;
      case model.NotificationType.birthday:
        return FontAwesomeIcons.cakeCandles;
      case model.NotificationType.attendance:
        return FontAwesomeIcons.clipboardUser;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.bellSlash,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up! Check back later.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing here',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
