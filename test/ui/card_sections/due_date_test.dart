import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/ui/card_sections/due_date.dart';

void main() {
  PlankaCard card({DateTime? due, bool? completed}) => PlankaCard(
        id: 'c1',
        boardId: 'b1',
        listId: 'l1',
        type: 'project',
        name: 'Card',
        dueDate: due,
        isDueCompleted: completed,
      );

  Widget host(
    PlankaCard c, {
    required ValueChanged<DateTime?> onChanged,
    required ValueChanged<bool> onCompletedToggle,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: CardDueDateSection(
            card: c,
            onChanged: onChanged,
            onCompletedToggle: onCompletedToggle,
          ),
        ),
      );

  testWidgets('with a due date: shows the formatted label, toggles completion, '
      'and clears the date', (tester) async {
    final due = DateTime(2026, 3, 4, 9, 30);
    DateTime? changedTo;
    var changedCalled = false;
    bool? completedTo;

    await tester.pumpWidget(host(
      card(due: due),
      onChanged: (v) {
        changedCalled = true;
        changedTo = v;
      },
      onCompletedToggle: (v) => completedTo = v,
    ));

    // Formatted label rendered, not the empty-state prompt.
    expect(find.text(DateFormat.yMMMd().add_Hm().format(due)), findsOneWidget);
    expect(find.text('Set due date'), findsNothing);

    // Completion checkbox fires onCompletedToggle(true).
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(completedTo, isTrue);

    // Remove button clears the date via onChanged(null).
    await tester.tap(find.byTooltip('Remove due date'));
    await tester.pump();
    expect(changedCalled, isTrue);
    expect(changedTo, isNull);
  });

  testWidgets('without a due date: prompts to set one, no checkbox or remove '
      'button', (tester) async {
    await tester.pumpWidget(host(
      card(),
      onChanged: (_) {},
      onCompletedToggle: (_) {},
    ));

    expect(find.text('Set due date'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byTooltip('Remove due date'), findsNothing);
  });
}
