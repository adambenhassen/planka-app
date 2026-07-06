import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../api/models.dart';
import '../state/notifications_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
        'commentCard' => Icons.chat_bubble_outline,
        'moveCard' => Icons.swap_horiz,
        'addMemberToCard' => Icons.person_add_alt,
        'mentionInComment' => Icons.alternate_email,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No notifications'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) =>
                    _NotificationTile(n: list[i], icon: _icon(list[i].type)),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n, required this.icon});
  final PlankaNotification n;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = n.data ?? const {};
    final cardName = (data['card'] as Map?)?['name'] as String? ?? '';
    final boardId = (data['card'] as Map?)?['boardId'] as String?;
    return ListTile(
      leading: Icon(icon,
          color: n.isRead ? null : Theme.of(context).colorScheme.primary),
      title: Text(cardName.isEmpty ? n.type : cardName,
          style: n.isRead
              ? null
              : const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: n.createdAt == null
          ? null
          : Text(_relative(n.createdAt!.toLocal())),
      onTap: () {
        ref.read(notificationsProvider.notifier).markRead(n.id);
        if (boardId != null) context.push('/boards/$boardId');
      },
    );
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(t);
  }
}
