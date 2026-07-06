import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../api/models.dart';
import '../state/notifications_state.dart';
import 'error_handling.dart';
import 'widgets/async_retry.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(PlankaNotificationType type) => switch (type) {
        PlankaNotificationType.commentCard => Icons.chat_bubble_outline,
        PlankaNotificationType.moveCard => Icons.swap_horiz,
        PlankaNotificationType.addMemberToCard => Icons.person_add_alt,
        PlankaNotificationType.mentionInComment => Icons.alternate_email,
        PlankaNotificationType.unknown => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => guardMutation(
              context,
              ref.read(notificationsProvider.notifier).markAllRead(),
            ),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: asyncRetry(
        notifications,
        () => ref.invalidate(notificationsProvider),
        (list) => list.isEmpty
            ? const Center(child: Text('No notifications'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) =>
                    _NotificationTile(
                        notification: list[i], icon: _icon(list[i].type)),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification, required this.icon});
  final PlankaNotification notification;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = notification.data ?? const {};
    final cardName = (data['card'] as Map?)?['name'] as String? ?? '';
    final boardId = (data['card'] as Map?)?['boardId'] as String?;
    return ListTile(
      leading: Icon(icon,
          color:
              notification.isRead ? null : Theme.of(context).colorScheme.primary),
      title: Text(cardName.isEmpty ? notification.type.name : cardName,
          style: notification.isRead
              ? null
              : const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: notification.createdAt == null
          ? null
          : Text(_formatRelativeTime(notification.createdAt!.toLocal())),
      onTap: () {
        guardMutation(context,
            ref.read(notificationsProvider.notifier).markRead(notification.id));
        if (boardId != null) context.push('/boards/$boardId');
      },
    );
  }

  String _formatRelativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(t);
  }
}
