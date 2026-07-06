import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/state/notifications_state.dart';

class SeededNotifier extends NotificationsNotifier {
  SeededNotifier(this.seed);
  final List<PlankaNotification> seed;
  final marked = <String>[];
  bool markedAll = false;

  @override
  Future<List<PlankaNotification>> build() async => seed;

  @override
  Future<void> markRead(String id) async {
    marked.add(id);
    return super.markRead(id);
  }
}

PlankaNotification n(String id, {bool isRead = false}) =>
    PlankaNotification(id: id, userId: 'u1', type: 'commentCard', isRead: isRead);

void main() {
  test('unreadCount, notificationCreate increments, markRead flips', () async {
    final container = ProviderContainer(overrides: [
      notificationsProvider
          .overrideWith(() => SeededNotifier([n('1'), n('2', isRead: true)])),
    ]);
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);
    expect(container.read(unreadCountProvider), 1);

    final notifier =
        container.read(notificationsProvider.notifier) as SeededNotifier;
    notifier.apply(SocketEvent.parse('notificationCreate', {
      'item': {'id': '3', 'userId': 'u1', 'type': 'commentCard', 'isRead': false}
    }));
    expect(container.read(unreadCountProvider), 2);

    notifier.apply(SocketEvent.parse('notificationUpdate', {
      'item': {'id': '3', 'userId': 'u1', 'type': 'commentCard', 'isRead': true}
    }));
    expect(container.read(unreadCountProvider), 1);
  });
}
