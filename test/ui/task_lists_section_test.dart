import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/ui/card_sections/task_lists.dart';

PlankaUser user(String id, String name) => PlankaUser(id: id, name: name);

PlankaTask task({
  String id = 't1',
  bool completed = false,
  String? linkedCardId,
  String? assigneeUserId,
}) => PlankaTask(
  id: id,
  taskListId: 'tl1',
  name: 'Do it',
  isCompleted: completed,
  linkedCardId: linkedCardId,
  assigneeUserId: assigneeUserId,
);

Widget host(
  List<PlankaTask> tasks, {
  List<PlankaUser> users = const [],
  required bool Function(PlankaTask) isCompleted,
  void Function(String taskId, bool v)? onToggle,
  void Function(String taskId, String? userId)? onSetAssignee,
  String? Function(PlankaTask)? linkedCardNameOf,
  void Function(String cardId)? onOpenLinkedCard,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CardTaskListsSection(
      taskLists: [PlankaTaskList(id: 'tl1', cardId: 'c1', name: 'Checklist')],
      tasks: tasks,
      users: users,
      isTaskCompleted: isCompleted,
      linkedCardNameOf: linkedCardNameOf ?? (_) => null,
      onToggleTask: onToggle ?? (_, _) {},
      onAddTask: (_, _) {},
      onAddTaskList: (_) {},
      onRenameTaskList: (_, _) {},
      onDeleteTaskList: (_) {},
      onRenameTask: (_, _) {},
      onDeleteTask: (_) {},
      onSetAssignee: onSetAssignee ?? (_, _) {},
      onOpenLinkedCard: onOpenLinkedCard ?? (_) {},
    ),
  ),
);

Future<void> openTaskMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('task-menu-t1')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an item with an assignee shows the assignee', (tester) async {
    await tester.pumpWidget(
      host(
        [task(assigneeUserId: 'u1')],
        users: [user('u1', 'Demo')],
        isCompleted: (_) => false,
      ),
    );
    expect(find.text('Demo'), findsOneWidget);
  });

  testWidgets('assigning picks a board member; unassign clears', (
    tester,
  ) async {
    String? assigned;
    await tester.pumpWidget(
      host(
        [task()],
        users: [user('u1', 'Demo')],
        isCompleted: (_) => false,
        onSetAssignee: (taskId, userId) => assigned = userId,
      ),
    );

    await openTaskMenu(tester);
    await tester.tap(find.text('Assign member…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    expect(assigned, 'u1');

    assigned = 'sentinel';
    await tester.pumpWidget(
      host(
        [task(assigneeUserId: 'u1')],
        users: [user('u1', 'Demo')],
        isCompleted: (_) => false,
        onSetAssignee: (taskId, userId) => assigned = userId,
      ),
    );
    await openTaskMenu(tester);
    await tester.tap(find.text('Unassign'));
    await tester.pumpAndSettle();
    expect(assigned, isNull);
  });

  testWidgets('a linked item shows the card name and tapping opens it', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      host(
        [task(linkedCardId: 'c9')],
        isCompleted: (_) => false,
        linkedCardNameOf: (_) => 'Linked card',
        onOpenLinkedCard: (cardId) => opened = cardId,
      ),
    );

    expect(find.text('Linked card'), findsOneWidget);
    await tester.tap(find.text('Do it'));
    await tester.pumpAndSettle();
    expect(opened, 'c9');
  });

  testWidgets('a linked item renders completion from the resolver and its '
      'checkbox does not toggle', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      host(
        [task(linkedCardId: 'c9', completed: true)],
        isCompleted: (_) => true,
        linkedCardNameOf: (_) => 'Linked card',
        onToggle: (_, _) => toggled = true,
      ),
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
    expect(checkbox.onChanged, isNull);

    await tester.tap(find.byType(CheckboxListTile).first);
    expect(toggled, isFalse);
  });

  testWidgets("a linked item's menu offers only delete, not rename or assign", (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        [task(linkedCardId: 'c9')],
        users: [user('u1', 'Demo')],
        isCompleted: (_) => false,
        linkedCardNameOf: (_) => 'Linked card',
      ),
    );

    await openTaskMenu(tester);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Assign member…'), findsNothing);
  });

  testWidgets('a plain item keeps toggling through the checkbox', (
    tester,
  ) async {
    (String, bool)? toggle;
    await tester.pumpWidget(
      host(
        [task()],
        isCompleted: (_) => false,
        onToggle: (taskId, v) => toggle = (taskId, v),
      ),
    );

    await tester.tap(find.byType(CheckboxListTile).first);
    expect(toggle, ('t1', true));
  });
}
