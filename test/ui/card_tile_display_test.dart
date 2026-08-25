import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
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
  DateTime? dueDate,
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
      dueDate: dueDate,
    );

BoardState state(
  PlankaCard c, {
  PlankaBoard b = const PlankaBoard(id: 'b1', projectId: 'p1', name: 'B'),
  List<PlankaList> lists = const [],
  List<PlankaTaskList> taskLists = const [],
  List<PlankaTask> tasks = const [],
  List<PlankaUser> users = const [],
  List<String> memberIds = const [],
  List<PlankaAttachment> attachments = const [],
}) =>
    BoardState(
      board: b,
      lists: lists,
      cards: {c.id: c},
      taskLists: taskLists,
      tasks: tasks,
      users: users,
      cardMemberships: [
        for (final u in memberIds)
          PlankaCardMembership(id: 'm-$u', cardId: c.id, userId: u),
      ],
      attachments: attachments,
    );

Widget host(PlankaCard c, BoardState s, {double? width}) => ProviderScope(
      overrides: [
        currentAccountProvider.overrideWith(() => _AccNotifier(Account(
            serverUrl: 'http://x',
            token: 'jwt-123',
            userId: 'u1',
            displayName: 'U'))),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: Scaffold(
          body: width == null
              ? CardTile(card: c, state: s)
              : Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: width, child: CardTile(card: c, state: s)),
                ),
        ),
      ),
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
    await tester.pumpWidget(host(card(commentsTotal: 0), state(card())));
    expect(find.text('0'), findsNothing);
    await tester.pumpWidget(host(card(), state(card())));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('creator setting with no creator id adds no empty bottom row',
      (tester) async {
    // A card the server has no creator for must not leave an empty metadata
    // row on the tile when alwaysDisplayCardCreator is set.
    final c = card(creatorUserId: null);
    await tester.pumpWidget(host(
        c, state(c, b: board(alwaysDisplayCardCreator: true))));
    expect(find.byType(Wrap), findsNothing);

    // Control: a resolvable creator does render the row.
    final c2 = card();
    await tester.pumpWidget(host(
        c2,
        state(c2,
            b: board(alwaysDisplayCardCreator: true),
            users: [const PlankaUser(id: 'u1', name: 'Demo')])));
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('expandTaskListsByDefault expands checklists on the tile; '
      'tap collapses', (tester) async {
    final c = card();
    final s = state(
      c,
      b: board(expandTaskListsByDefault: true),
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true)
      ],
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

  testWidgets('fully-loaded metadata does not overflow the 300px column',
      (tester) async {
    // The board column is a fixed 300px; the tile must fit it with every
    // metadata element present at once, not clip the new chips/avatars.
    final c = card(
      creatorUserId: 'u1',
      commentsTotal: 3,
      createdAt: twoHoursAgo,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );
    final s = state(
      c,
      b: board(alwaysDisplayCardCreator: true, displayCardAges: true),
      // The card sits in a closed list so the widest chip of the group — the
      // localized "Closed" word — is part of the combined-width bound.
      lists: const [
        PlankaList(
            id: 'l1',
            boardId: 'b1',
            type: PlankaListType.closed,
            name: 'Closed',
            position: 1),
      ],
      users: const [
        PlankaUser(id: 'u1', name: 'Demo'),
        PlankaUser(id: 'u2', name: 'Ann'),
        PlankaUser(id: 'u3', name: 'Bob'),
        PlankaUser(id: 'u4', name: 'Cy'),
      ],
      memberIds: const ['u2', 'u3', 'u4'],
      attachments: const [
        PlankaAttachment(id: 'a1', cardId: 'c1', type: 'file', name: 'p.png'),
      ],
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true)
      ],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'task 1', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s, width: 300));
    expect(tester.takeException(), isNull);
    // Every element is present and none is clipped away.
    expect(find.text('3'), findsOneWidget); // comments
    expect(find.text('2h'), findsOneWidget); // age
    expect(find.text('D'), findsOneWidget); // creator avatar
    expect(find.text('Closed'), findsOneWidget); // closed-list chip
  });

  testWidgets('inline checklist mirrors the collapsed chip for a linked task',
      (tester) async {
    // A task linked to a closed card counts as completed by the derived
    // rule; the inline expanded row must agree with the collapsed chip and
    // the card sheet, which all use state.isTaskCompleted.
    final c = card();
    final withLinked = BoardState(
      board: board(expandTaskListsByDefault: true),
      lists: const [
        PlankaList(
            id: 'l2',
            boardId: 'b1',
            type: PlankaListType.closed,
            name: 'Closed',
            position: 2),
      ],
      cards: {
        c.id: c,
        'c2': PlankaCard(
            id: 'c2',
            boardId: 'b1',
            listId: 'l2',
            type: 'project',
            name: 'Linked',
            isClosed: true),
      },
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true)
      ],
      tasks: const [
        PlankaTask(
            id: 't1',
            taskListId: 'tl1',
            name: 'linked',
            isCompleted: false,
            linkedCardId: 'c2'),
      ],
    );
    await tester.pumpWidget(host(c, withLinked));
    // Expanded inline row: the linked task renders completed.
    expect(find.text('1/1'), findsOneWidget);
    final style = tester.widget<Text>(find.text('linked')).style;
    expect(style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('showOnFrontOfCard unset keeps the list off the tile',
      (tester) async {
    // Planka only draws a checklist on the card front when the list opts in
    // with showOnFrontOfCard; the board's expansion setting does not change
    // that. The collapsed progress chip is unaffected.
    final c = card();
    final s = state(
      c,
      b: board(expandTaskListsByDefault: true),
      taskLists: const [
        PlankaTaskList(id: 'tl1', cardId: 'c1', name: 'Checklist')
      ],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'task 1', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('task 1'), findsNothing);
    expect(find.byKey(const ValueKey('tile-tasklist-toggle-tl1')), findsNothing);
    // The board expands by default, so there is no collapsed chip either:
    // the list contributes nothing to the tile at all.
    expect(find.text('0/1'), findsNothing);

    // Same with the board's expansion setting off: the list still does not
    // appear, and the chip does not count it.
    await tester.pumpWidget(host(
        c,
        state(
          c,
          taskLists: s.taskLists,
          tasks: s.tasks,
        )));
    expect(find.text('task 1'), findsNothing);
    expect(find.byKey(const ValueKey('tile-tasklist-toggle-tl1')), findsNothing);
    expect(find.text('0/1'), findsNothing);
  });

  testWidgets('showOnFrontOfCard true puts the list on the tile',
      (tester) async {
    final c = card();
    final s = state(
      c,
      b: board(expandTaskListsByDefault: true),
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true)
      ],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'task 1', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('task 1'), findsOneWidget);
  });

  testWidgets('hideCompletedTasks shows only incomplete tasks on the tile',
      (tester) async {
    final c = card();
    final s = state(
      c,
      b: board(expandTaskListsByDefault: true),
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true,
            hideCompletedTasks: true)
      ],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'done', isCompleted: true),
        PlankaTask(
            id: 't2', taskListId: 'tl1', name: 'open', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('open'), findsOneWidget);
    expect(find.text('done'), findsNothing);
    // The progress row counts the whole list, like the web client.
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('collapsed chip counts only front-of-card lists', (tester) async {
    // The web client draws no progress row for a checklist that is not on
    // the card front, so the collapsed chip must not count its tasks either.
    final c = card();
    final s = state(
      c,
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true),
        PlankaTaskList(id: 'tl2', cardId: 'c1', name: 'Hidden'),
      ],
      tasks: const [
        PlankaTask(id: 't1', taskListId: 'tl1', name: 'a', isCompleted: true),
        PlankaTask(id: 't2', taskListId: 'tl1', name: 'b', isCompleted: false),
        PlankaTask(
            id: 't3', taskListId: 'tl2', name: 'c', isCompleted: false),
      ],
    );
    await tester.pumpWidget(host(c, s));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('1/3'), findsNothing);
  });

  testWidgets('checklists stay off the tile without the setting', (tester) async {
    final c = card();
    final s = state(
      c,
      taskLists: const [
        PlankaTaskList(
            id: 'tl1',
            cardId: 'c1',
            name: 'Checklist',
            showOnFrontOfCard: true)
      ],
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
