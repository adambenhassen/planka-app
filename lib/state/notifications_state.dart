import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
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
    socket.events.listen(applyEvent,
        onError: (Object e) => debugPrint('notifications socket error: $e'));
    await socket.connect();
    final env = await _repo.notifications();
    return env.items.map(PlankaNotification.fromJson).toList();
  }

  /// Fold a socket event into the list. Exposed for tests.
  void applyEvent(SocketEvent event) {
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

  /// Applies [next] optimistically, then runs [call]. On failure, refetches
  /// from the server (via [build]) rather than restoring a possibly-stale
  /// snapshot — the board notifier's `_optimistic` uses the same convention.
  Future<void> _optimistic(
      List<PlankaNotification> next, Future<void> Function() call) async {
    state = AsyncData(next);
    try {
      await call();
    } on ApiException {
      ref.invalidateSelf();
      rethrow;
    }
  }

  Future<void> markRead(String id) async {
    final list = state.value;
    if (list == null) return;
    await _optimistic([
      for (final n in list)
        n.id == id
            ? PlankaNotification.fromJson({...n.toJson(), 'isRead': true})
            : n
    ], () => _repo.markNotificationRead(id));
  }

  Future<void> markAllRead() async {
    final list = state.value;
    if (list == null) return;
    await _optimistic([
      for (final n in list)
        PlankaNotification.fromJson({...n.toJson(), 'isRead': true})
    ], () => _repo.markAllNotificationsRead());
  }
}
