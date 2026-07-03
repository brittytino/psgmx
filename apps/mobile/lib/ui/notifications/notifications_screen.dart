import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock data to handle dismissal state
  final List<Map<String, dynamic>> _unreadNotifications = [
    {
      'id': '1',
      'title': 'New Announcement',
      'body': 'Placement drive by Zoho starting from 25 May.',
      'time': '10:30 AM',
      'icon': LucideIcons.bellRing,
      'isUnread': true,
    },
    {
      'id': '2',
      'title': 'Exam Reminder',
      'body': 'DBMS Internal Assessment is tomorrow.',
      'time': '9:15 AM',
      'icon': LucideIcons.calendarClock,
      'isUnread': true,
    },
    {
      'id': '3',
      'title': 'Keep the Streak!',
      'body': 'You\'re on a 7-day learning streak. Keep it going!',
      'time': '8:00 AM',
      'icon': LucideIcons.flame,
      'isUnread': true,
    },
  ];

  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'id': '4',
      'title': 'New Opportunity',
      'body': 'Capgemini has posted a new job for SDE Intern.',
      'time': '7:45 AM',
      'icon': LucideIcons.briefcase,
      'isUnread': true,
    },
    {
      'id': '5',
      'title': 'Weekly Progress Report',
      'body': 'Your weekly report is ready. Check your progress now.',
      'time': '7:30 AM',
      'icon': LucideIcons.barChart2,
      'isUnread': true,
    },
    {
      'id': '6',
      'title': 'Mentor Message',
      'body': 'Spark has a new suggestion for your preparation.',
      'time': '6:20 AM',
      'icon': LucideIcons.messageSquare,
      'isUnread': true,
    },
  ];

  final List<Map<String, dynamic>> _thisWeekNotifications = [
    {
      'id': '7',
      'title': 'Goal Reminder',
      'body': 'You set a goal to solve 30 problems this week.',
      'time': 'Yesterday',
      'icon': LucideIcons.target,
      'isUnread': true,
    },
    {
      'id': '8',
      'title': 'Leaderboard Update',
      'body': 'You moved up 3 ranks on Readiness Rankings!',
      'time': 'Yesterday',
      'icon': LucideIcons.trophy,
      'isUnread': true,
    },
    {
      'id': '9',
      'title': 'Quiz Reminder',
      'body': 'DAA Quiz is live. Attempt it before it expires!',
      'time': 'May 17',
      'icon': LucideIcons.fileText,
      'isUnread': false,
    },
  ];

  final List<Map<String, dynamic>> _earlierNotifications = [
    {
      'id': '10',
      'title': 'Reward Unlocked',
      'body': 'You earned a badge for solving 100 problems!',
      'time': 'May 15',
      'icon': LucideIcons.gift,
      'isUnread': false,
    },
    {
      'id': '11',
      'title': 'System Update',
      'body': 'Scheduled maintenance on 19 May, 11 PM - 1 AM.',
      'time': 'May 14',
      'icon': LucideIcons.megaphone,
      'isUnread': false,
    },
    {
      'id': '12',
      'title': 'Session Reminder',
      'body': 'Aptitude practice session starts at 5:00 PM today.',
      'time': 'May 13',
      'icon': LucideIcons.users,
      'isUnread': false,
    },
  ];

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
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentCoral,
                    shape: BoxShape.circle,
                  ),
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.settings, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_unreadNotifications.isNotEmpty) ...[
              _buildSectionHeader('UNREAD', theme),
              ..._unreadNotifications.map((n) => _buildNotificationTile(n, theme)),
            ],
            
            if (_todayNotifications.isNotEmpty) ...[
              _buildSectionHeader('TODAY', theme),
              ..._todayNotifications.map((n) => _buildNotificationTile(n, theme)),
            ],
            
            if (_thisWeekNotifications.isNotEmpty) ...[
              _buildSectionHeader('THIS WEEK', theme),
              ..._thisWeekNotifications.map((n) => _buildNotificationTile(n, theme)),
            ],
            
            if (_earlierNotifications.isNotEmpty) ...[
              _buildSectionHeader('EARLIER', theme),
              ..._earlierNotifications.map((n) => _buildNotificationTile(n, theme)),
            ],
            
            const SizedBox(height: 24),
            Row(
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
            const SizedBox(height: 48),
          ],
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

  Widget _buildNotificationTile(Map<String, dynamic> notification, ThemeData theme) {
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          notification['isUnread'] = false;
        });
      },
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
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Mark as read',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        color: notification['isUnread'] ? const Color(0xFFFAF9F6) : Colors.transparent, // Very light warm background for unread
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
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
                child: Icon(notification['icon'], size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'],
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification['body'],
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
            
            // Time & Status Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  notification['time'],
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
                    color: notification['isUnread'] ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
