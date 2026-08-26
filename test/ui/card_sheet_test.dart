import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sheet.dart';

class FakeBoardNotifier extends BoardNotifier {
  FakeBoardNotifier(super.boardId, {this.seed});
  final calls = <(String, Object?)>[];
  final BoardState Function(BoardState)? seed;

  @override
  Future<BoardState> build() async {
    final base = BoardState.fromEnvelope(Envelope.parse(
        jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
            as Map<String, dynamic>));
    return seed?.call(base) ?? base;
  }

  @override
  Future<void> setTaskCompleted(String taskId, bool isCompleted) async =>
      calls.add(('setTaskCompleted', (taskId, isCompleted)));

  @override
  Future<void> createComment(String cardId, String text) async =>
      calls.add(('createComment', text));

  @override
  Future<List<PlankaComment>> fetchComments(String cardId) async {
    calls.add(('fetchComments', cardId));
    return const [];
  }

  @override
  Future<void> toggleLabel(String cardId, String labelId) async =>
      calls.add(('toggleLabel', labelId));
}

void main() {
  late FakeBoardNotifier notifier;
  late String boardId;
  late String cardId;

  Widget app([BoardState Function(BoardState)? seed]) {
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
          notifier = FakeBoardNotifier(arg, seed: seed);
          return notifier;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                CardSheet(boardId: boardId, cardId: cardId),
          ),
        ),
      ),
    );
  }

  testWidgets('assignee picker offers board members only, not card creators',
      (tester) async {
    // The board response's users are a union of members and card creators;
    // seed a user who is in the response but has no board membership.
    final stranger = PlankaUser(id: 'stranger', name: 'Stranger');
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fixture =
        jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
            as Map<String, dynamic>;
    final taskId =
        (((fixture['included'] as Map)['tasks'] as List).first as Map)['id']
            as String;

    await tester.pumpWidget(app(
        (state) => state.copyWith(users: [...state.users, stranger])));
    await tester.pumpAndSettle();

    // Open the item's menu and the picker.
    await tester.tap(find.byKey(Key('task-menu-$taskId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign member…'));
    await tester.pumpAndSettle();

    // Scope to the picker dialog: the members section also renders 'Demo'.
    final dialog = find.byType(SimpleDialog);
    expect(find.descendant(of: dialog, matching: find.text('Demo')),
        findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Stranger')),
        findsNothing);
  });

  testWidgets('renders title; task toggle, comment send, label toggle',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(notifier.calls, contains(('fetchComments', cardId)));

    // Title rendered in editable field.
    expect(find.widgetWithText(TextFormField, 'Fixture card'), findsOneWidget);

    // Toggle first task checkbox.
    await tester.tap(find.byType(CheckboxListTile).first);
    expect(notifier.calls.where((c) => c.$1 == 'setTaskCompleted'), hasLength(1));

    // Toggle a label chip.
    await tester.tap(find.byType(FilterChip).first);
    expect(notifier.calls.where((c) => c.$1 == 'toggleLabel'), hasLength(1));

    // Send a comment.
    await tester.enterText(
        find.widgetWithText(TextField, 'Write a comment…'), 'hello test');
    await tester.tap(find.byIcon(Icons.send));
    expect(notifier.calls, contains(('createComment', 'hello test')));
  });
}
