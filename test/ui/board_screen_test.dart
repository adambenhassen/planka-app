import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/board_screen.dart';

class FakeBoardNotifier extends BoardNotifier {
  FakeBoardNotifier(super.boardId);
  final moves = <(String, String)>[];

  @override
  Future<BoardState> build() async => BoardState.fromEnvelope(Envelope.parse(
      jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
          as Map<String, dynamic>));

  @override
  Future<void> moveCard(String cardId, String toListId,
      {String? beforeCardId, String? afterCardId}) async {
    moves.add((cardId, toListId));
  }
}

void main() {
  testWidgets('renders columns and cards; drag calls moveCard',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late FakeBoardNotifier notifier;
    final boardId =
        (jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
            as Map<String, dynamic>)['item']['id'] as String;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        boardProvider.overrideWith2((arg) {
          notifier = FakeBoardNotifier(arg);
          return notifier;
        }),
      ],
      child: MaterialApp(home: BoardScreen(boardId: boardId)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('To Do'), findsOneWidget);
    expect(find.text('Fixture card'), findsWidgets);
    expect(find.text('Add card'), findsWidgets);
    expect(find.text('Add list'), findsOneWidget);

    // Create a second list target via the notifier's state? Instead drag the
    // card onto the drop zone at the top of its own list is rejected
    // (onWillAccept). Add a second list through applyEvent is overkill here:
    // assert the drag machinery calls moveCard by dragging onto the bottom
    // drop target of the same list (before=card itself → rejected) — so use
    // the top target of the same list with a second card.
    final tile = find.text('Fixture card').first;
    final gesture =
        await tester.startGesture(tester.getCenter(tile));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Single-card list: both neighbors are the card itself → rejected, no call.
    expect(notifier.moves, isEmpty);

    // Now add a second card via the state and drag card1 below card2.
    final s = notifier.state.value!;
    final listId = s.columns.first.id;
    final c1 = s.cardsOf(listId).first;
    notifier.state = AsyncData(s.copyWith(cards: {
      ...s.cards,
      'c2': c1.copyWith(id: 'c2', name: 'Second card', position: 99999),
    }));
    await tester.pumpAndSettle();
    expect(find.text('Second card'), findsOneWidget);

    final g2 = await tester.startGesture(
        tester.getCenter(find.text('Fixture card').first));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await g2.moveTo(
        tester.getCenter(find.byKey(ValueKey('drop-$listId-c2-null'))));
    await tester.pump();
    await g2.up();
    await tester.pumpAndSettle();

    expect(notifier.moves, [(c1.id, listId)]);
  });
}
