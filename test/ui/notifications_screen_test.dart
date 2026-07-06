import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/state/notifications_state.dart';
import 'package:planka_app/ui/notifications_screen.dart';

class _FakeNotifier extends NotificationsNotifier {
  _FakeNotifier(this.seed);
  final List<PlankaNotification> seed;
  final marked = <String>[];

  @override
  Future<List<PlankaNotification>> build() async => seed;

  @override
  Future<void> markRead(String id) async => marked.add(id);
}

PlankaNotification _n(String id, PlankaNotificationType type) =>
    PlankaNotification(id: id, userId: 'u1', type: type, isRead: false);

void main() {
  testWidgets('renders a distinct icon per notification type and marks read '
      'on tap', (tester) async {
    late _FakeNotifier notifier;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationsProvider.overrideWith(() {
          notifier = _FakeNotifier([
            _n('a', PlankaNotificationType.commentCard),
            _n('b', PlankaNotificationType.moveCard),
          ]);
          return notifier;
        }),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ));
    await tester.pumpAndSettle();

    // The enum→icon switch renders the right icon for each type.
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

    // Tapping a tile (no boardId → no navigation) marks it read.
    await tester.tap(find.text('commentCard'));
    await tester.pump();
    expect(notifier.marked, contains('a'));
  });
}
