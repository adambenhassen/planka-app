import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_tile.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

BoardState stateWith(
  PlankaCard card, {
  PlankaListType listType = PlankaListType.active,
}) => BoardState(
  board: PlankaBoard(id: 'b1', projectId: 'p1', name: 'B'),
  lists: [
    PlankaList(id: card.listId, boardId: 'b1', type: listType, name: 'L'),
  ],
  cards: {card.id: card},
);

Widget host(PlankaCard card, BoardState state) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CardTile(card: card, state: state),
    ),
  ),
);

void main() {
  testWidgets('a closed card shows the closed chip', (tester) async {
    final card = PlankaCard(
      id: 'c1',
      boardId: 'b1',
      listId: 'l1',
      type: 'project',
      name: 'X',
      isClosed: true,
    );
    await tester.pumpWidget(host(card, stateWith(card)));
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('an open card shows none', (tester) async {
    final card = PlankaCard(
      id: 'c1',
      boardId: 'b1',
      listId: 'l1',
      type: 'project',
      name: 'X',
      isClosed: false,
    );
    await tester.pumpWidget(host(card, stateWith(card)));
    expect(find.text('Closed'), findsNothing);
  });
}
