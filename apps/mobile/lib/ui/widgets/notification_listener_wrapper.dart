import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';

class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;
  const NotificationListenerWrapper({super.key, required this.child});

  @override
  State<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends State<NotificationListenerWrapper> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        NotificationService().notificationStream.listen(_showNotification);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showNotification(AppNotification notification) {
    if (!mounted) return;

    final isBirthday = notification.title.contains('🎂') ||
        notification.tone == NotificationTone.celebratory;
    final isReminder = notification.notificationType == NotificationType.reminder;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: isBirthday
            ? const Color(0xFF6B21A8) // Festive royal purple
            : isReminder
                ? const Color(0xFFC2410C) // Warning amber/coral
                : const Color(0xFF1E1B4B), // Dark navy
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 10),
              child: Text(
                isBirthday ? '🎂' : isReminder ? '🔥' : '📢',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.amberAccent,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
