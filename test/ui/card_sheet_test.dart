import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sheet.dart';

class FakeBoardNotifier extends BoardNotifier {
  FakeBoardNotifier(super.arg);
  final calls = <(String, Object?)>[];

  @override
  Future<BoardState> build() async => BoardState.fromEnvelope(Envelope.parse(
      jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
          as Map<String, dynamic>));

  @override
  Future<void> toggleTask(String taskId, bool isCompleted) async =>
      calls.add(('toggleTask', (taskId, isCompleted)));

  @override
  Future<void> addComment(String cardId, String text) async =>
      calls.add(('addComment', text));

  @override
  Future<void> toggleLabel(String cardId, String labelId) async =>
      calls.add(('toggleLabel', labelId));
}

void main() {
  late FakeBoardNotifier notifier;
  late String boardId;
  late String cardId;

  Widget app() {
    final fixture =
        jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
            as Map<String, dynamic>;
    boardId = (fixture['item'] as Map)['id'] as String;
    cardId =
        (((fixture['included'] as Map)['cards'] as List).first as Map)['id']
            as String;
    return ProviderScope(
      overrides: [
        boardProvider.overrideWith2((arg) {
          notifier = FakeBoardNotifier(arg);
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                CardSheet(boardId: boardId, cardId: cardId),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title; task toggle, comment send, label toggle',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Title rendered in editable field.
    expect(find.widgetWithText(TextFormField, 'Fixture card'), findsOneWidget);

    // Toggle first task checkbox.
    await tester.tap(find.byType(CheckboxListTile).first);
    expect(notifier.calls.where((c) => c.$1 == 'toggleTask'), hasLength(1));

    // Toggle a label chip.
    await tester.tap(find.byType(FilterChip).first);
    expect(notifier.calls.where((c) => c.$1 == 'toggleLabel'), hasLength(1));

    // Send a comment.
    await tester.enterText(
        find.widgetWithText(TextField, 'Write a comment…'), 'hello test');
    await tester.tap(find.byIcon(Icons.send));
    expect(notifier.calls, contains(('addComment', 'hello test')));
  });
}
