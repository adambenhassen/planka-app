import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
import '../api/planka_socket.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import '../security_redaction.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<PlankaNotification>>(
        NotificationsNotifier.new);

final notificationsSocketFactoryProvider = Provider<PlankaSocketFactory>(
  (_) => PlankaSocket.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  if (notifications.isLoading || notifications.hasError) return 0;
  return (notifications.value ?? []).where((n) => !n.isRead).length;
});

class NotificationsNotifier extends AsyncNotifier<List<PlankaNotification>> {
  PlankaSocket? _socket;
  StreamSubscription<SocketEvent>? _socketEvents;
  void Function()? _removeAccountEpochListener;

  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));

  void _disposeSocket() {
    _socketEvents?.cancel();
    _socket?.dispose();
    _socketEvents = null;
    _socket = null;
  }

  void _invalidateAccountState() {
    _disposeSocket();
    if (ref.mounted) {
      // A dependency refresh otherwise carries the previous account's
      // notifications as AsyncData while the replacement account loads.
      state = const AsyncData<List<PlankaNotification>>([]);
    }
  }

  @override
  Future<List<PlankaNotification>> build() async {
    state = const AsyncLoading<List<PlankaNotification>>();
    _disposeSocket();
    ref.watch(accountStateEpochProvider);
    if (_removeAccountEpochListener == null) {
      _removeAccountEpochListener = ref
          .read(accountStateEpochProvider.notifier)
          .listen(_invalidateAccountState);
      ref.onDispose(() {
        _removeAccountEpochListener?.call();
        _removeAccountEpochListener = null;
      });
    }
    final account = ref.watch(currentAccountProvider);
    if (account == null ||
        !ref.read(cacheLifecycleProvider).isUsable(account.id)) {
      return [];
    }
    final api = ref.watch(apiProvider);
    final socket = _socket = ref.read(notificationsSocketFactoryProvider)(
      account.serverUrl,
      account.token,
    );
    // Realtime notifications are a live-update convenience over the REST list
    // fetched below; a socket error degrades only that, so we log rather than
    // surface it. ponytail: no degraded-state indicator — add one if stale
    // notification counts become a visible problem.
    _socketEvents = socket.events.listen(applyEvent,
        onError: (Object e) =>
            debugPrint('notifications socket error: ${redactDiagnostic(e)}'));
    ref.onDispose(() {
      _socketEvents?.cancel();
      _socket?.dispose();
    });
    await socket.connect();
    final env = await PlankaRepo(api).notifications();
    final current = ref.read(currentAccountProvider);
    if (current?.id != account.id ||
        current?.serverUrl != account.serverUrl ||
        current?.token != account.token ||
        !ref.read(cacheLifecycleProvider).isUsable(account.id)) {
      return [];
    }
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
