import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/planka_socket.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<PlankaNotification>>(
        NotificationsNotifier.new);

final unreadCountProvider = Provider<int>((ref) =>
    (ref.watch(notificationsProvider).value ?? [])
        .where((n) => !n.isRead)
        .length);

class NotificationsNotifier extends AsyncNotifier<List<PlankaNotification>> {
  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));

  @override
  Future<List<PlankaNotification>> build() async {
    final account = ref.watch(currentAccountProvider);
    if (account == null) return [];
    final socket = PlankaSocket(account.serverUrl, account.token);
    ref.onDispose(socket.dispose);
    socket.events.listen(apply, onError: (Object _) {});
    await socket.connect();
    final env = await _repo.notifications();
    return env.items.map(PlankaNotification.fromJson).toList();
  }

  /// Fold a socket event into the list. Exposed for tests.
  void apply(SocketEvent event) {
    final list = state.value;
    if (list == null) return;
    switch (event.name) {
      case 'notificationCreate':
        final n = PlankaNotification.fromJson(event.data.item);
        state = AsyncData([n, ...list.where((e) => e.id != n.id)]);
      case 'notificationUpdate':
        final n = PlankaNotification.fromJson(event.data.item);
        state = AsyncData([for (final e in list) e.id == n.id ? n : e]);
    }
  }

  Future<void> markRead(String id) async {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final n in list)
        n.id == id ? PlankaNotification.fromJson({...n.toJson(), 'isRead': true}) : n
    ]);
    try {
      await _repo.markNotificationRead(id);
    } catch (_) {
      state = AsyncData(list);
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final n in list)
        PlankaNotification.fromJson({...n.toJson(), 'isRead': true})
    ]);
    try {
      await _repo.readAllNotifications();
    } catch (_) {
      state = AsyncData(list);
      rethrow;
    }
  }
}
