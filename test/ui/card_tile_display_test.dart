import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_tile.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

class _AccNotifier extends CurrentAccountNotifier {
  _AccNotifier(this.account);
  final Account? account;
  @override
  Account? build() => account;
}

PlankaBoard board({
  bool alwaysDisplayCardCreator = false,
  bool displayCardAges = false,
  bool expandTaskListsByDefault = false,
}) =>
    PlankaBoard(
      id: 'b1',
      projectId: 'p1',
      name: 'B',
      alwaysDisplayCardCreator: alwaysDisplayCardCreator,
      displayCardAges: displayCardAges,
      expandTaskListsByDefault: expandTaskListsByDefault,
    );

PlankaCard card({
  String? creatorUserId = 'u1',
  int? commentsTotal,
  DateTime? createdAt,
}) =>
    PlankaCard(
      id: 'c1',
      boardId: 'b1',
      listId: 'l1',
      type: 'project',
      name: 'Card',
      creatorUserId: creatorUserId,
      commentsTotal: commentsTotal,
      createdAt: createdAt,
    );

BoardState state(
  PlankaCard c, {
  PlankaBoard b = const PlankaBoard(id: 'b1', projectId: 'p1', name: 'B'),
  List<PlankaTaskList> taskLists = const [],
  List<PlankaTask> tasks = const [],
  List<PlankaUser> users = const [],
}) =>
    BoardState(
      board: b,
      lists: const [],
      cards: {c.id: c},
      taskLists: taskLists,
      tasks: tasks,
      users: users,
    );

Widget host(PlankaCard c, BoardState s) => ProviderScope(
      overrides: [
        currentAccountProvider.overrideWith(() => _AccNotifier(Account(
            serverUrl: 'http://x',
            token: 'jwt-123',
            userId: 'u1',
            displayName: 'U'))),
      ],
      child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: CardTile(card: c, state: s))),
    );

void main() {
  final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));

  testWidgets('alwaysDisplayCardCreator shows the creator avatar', (tester) async {
    final c = card();
    final s = state(c,
        b: board(alwaysDisplayCardCreator: true),
        users: [const PlankaUser(id: 'u1', name: 'Demo')]);
    await tester.pumpWidget(host(c, s));
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('creator avatar absent when the setting is off', (tester) async {
    final c = card();
    final s = state(c, users: [const PlankaUser(id: 'u1', name: 'Demo')]);
    await tester.pumpWidget(host(c, s));
    expect(find.text('D'), findsNothing);
  });

  testWidgets('displayCardAges shows a compact age from createdAt',
      (tester) async {
    final c = card(createdAt: twoHoursAgo);
    final s = state(c, b: board(displayCardAges: true));
    await tester.pumpWidget(host(c, s));
    expect(find.text('2h'), findsOneWidget);
  });

  testWidgets('no age chip when the setting is off', (tester) async {
    final c = card(createdAt: twoHoursAgo);
    final s = state(c);
    await tester.pumpWidget(host(c, s));
    expect(find.text('2h'), findsNothing);
  });

  testWidgets('commentsTotal renders as a tile chip when positive',
      (tester) async {
    final c = card(commentsTotal: 3);
    await tester.pumpWidget(host(c, state(c)));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('zero or missing commentsTotal shows no chip', (tester) async {
    await tester.pumpWidget(host(card(), state(card())));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('expandTaskListsByDefault expands checklists on the tile; '
      'tap collapses', (tester) async {
    final c = card();
    final s = state(
      c,
      b: board(expandTaskListsByDefault: true),
      taskLists: const [PlankaTaskList(id: 'tl1', cardId: 'c1', name: 'Checklist')],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'task 1', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('task 1'), findsOneWidget);

    // The progress-row header toggles the list closed.
    await tester.tap(find.byKey(const ValueKey('tile-tasklist-toggle-tl1')));
    await tester.pumpAndSettle();
    expect(find.text('task 1'), findsNothing);
    // The collapsed header still shows the done/total count.
    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets('checklists stay off the tile without the setting', (tester) async {
    final c = card();
    final s = state(
      c,
      taskLists: const [PlankaTaskList(id: 'tl1', cardId: 'c1', name: 'Checklist')],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'task 1', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('task 1'), findsNothing);
    // Today's aggregate summary chip is what remains.
    expect(find.text('0/1'), findsOneWidget);
  });
}
