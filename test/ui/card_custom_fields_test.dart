import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sections/custom_fields.dart';
import 'package:planka_app/ui/card_sheet.dart';
import 'package:planka_app/ui/card_tile.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

BoardState _customFieldBoard() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')))
        .withBaseCustomFields(
            Envelope.parse(_json('project_show_custom_fields')));

BoardState _plainBoard() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show')));

String _cardIdOf(String fixture) =>
    ((_json(fixture)['included'] as Map)['cards'] as List).first['id'] as String;

/// A minimal board carrying one front-of-card field named `Front` holding
/// [content], for exercising the chip's labelling on its own.
BoardState _chipBoard(String content) {
  const card = PlankaCard(
      id: 'c1', boardId: 'b1', listId: 'l1', type: 'project', name: 'Card');
  return BoardState(
    board: const PlankaBoard(id: 'b1', projectId: 'p1', name: 'B'),
    lists: const [],
    cards: const {'c1': card},
    customFieldGroups: const [
      PlankaCustomFieldGroup(id: 'g1', name: 'G', boardId: 'b1'),
    ],
    customFields: const [
      PlankaCustomField(
          id: 'f1',
          name: 'Front',
          customFieldGroupId: 'g1',
          showOnFrontOfCard: true),
    ],
    customFieldValues: [
      PlankaCustomFieldValue(
          id: 'v1',
          cardId: 'c1',
          customFieldGroupId: 'g1',
          customFieldId: 'f1',
          content: content),
    ],
  );
}

class _AccNotifier extends CurrentAccountNotifier {
  _AccNotifier(this.account);
  final Account? account;
  @override
  Account? build() => account;
}

class _FixedBoardNotifier extends BoardNotifier {
  _FixedBoardNotifier(super.boardId, this.state_);
  final BoardState state_;
  @override
  Future<BoardState> build() async => state_;
}

void main() {
  Widget sheet(BoardState s, String cardId) => ProviderScope(
        overrides: [
          boardProvider.overrideWith2(
              (arg) => _FixedBoardNotifier(arg, s)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CardSheet(boardId: s.board.id, cardId: cardId),
          ),
        ),
      );

  Widget tile(BoardState s, String cardId) => ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier(Account(
              serverUrl: 'http://x',
              token: 'jwt-123',
              userId: 'u1',
              displayName: 'U'))),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CardTile(card: s.cards[cardId]!, state: s)),
        ),
      );

  Future<void> pumpTall(WidgetTester tester, Widget w) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();
  }

  testWidgets('card sheet shows each group, its fields and their values',
      (tester) async {
    final s = _customFieldBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    // Board group BG → field F → value hello, the ticket's end-to-end case.
    expect(find.text('BG'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('a card-level group renders alongside the board-level ones',
      (tester) async {
    final s = _customFieldBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    expect(find.text('CG'), findsOneWidget);
    expect(find.text('card level'), findsOneWidget);
  });

  testWidgets('a group instantiated from a base group renders its name and '
      'fields', (tester) async {
    final s = _customFieldBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('BF'), findsOneWidget);
    expect(find.text('based'), findsOneWidget);
  });

  testWidgets('a field with no value shows its name and a blank value',
      (tester) async {
    final s = _customFieldBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    // The web client renders an unset value as U+00A0: the name is shown, the
    // value line is blank — no placeholder text and no dash.
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text(' '), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('groups render in the server position order', (tester) async {
    final s = _customFieldBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    double y(String label) => tester.getTopLeft(find.text(label)).dy;
    // Board groups first (Base at 16384, then BG at 32768), card group last.
    expect(y('Base'), lessThan(y('BG')));
    expect(y('BG'), lessThan(y('CG')));
    // Fields keep their own position order inside a group.
    expect(y('F'), lessThan(y('Front')));
    expect(y('Front'), lessThan(y('Empty')));
  });

  testWidgets('card sheet skips a group the project read left unresolved',
      (tester) async {
    // The board envelope alone — the project read that would name the
    // instantiated group and supply its fields never landed.
    final s =
        BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')));
    await pumpTall(tester, sheet(s, _cardIdOf('board_show_custom_fields')));

    // No untitled empty block; the groups that did resolve still render.
    expect(find.byType(CardCustomFieldsSection), findsNWidgets(2));
    expect(find.text('BG'), findsOneWidget);
    expect(find.text('CG'), findsOneWidget);
  });

  testWidgets('card sheet for a board with no custom fields adds nothing',
      (tester) async {
    final s = _plainBoard();
    await pumpTall(tester, sheet(s, _cardIdOf('board_show')));

    expect(find.byType(CardCustomFieldsSection), findsNothing);
  });

  testWidgets('tile shows a flagged field that holds a value', (tester) async {
    final s = _customFieldBoard();
    await tester.pumpWidget(tile(s, _cardIdOf('board_show_custom_fields')));
    await tester.pumpAndSettle();

    expect(find.text('on front'), findsOneWidget);
  });

  testWidgets('tile omits values of fields that are not flagged',
      (tester) async {
    final s = _customFieldBoard();
    await tester.pumpWidget(tile(s, _cardIdOf('board_show_custom_fields')));
    await tester.pumpAndSettle();

    // F, CF and BF all hold values but none is showOnFrontOfCard.
    expect(find.text('hello'), findsNothing);
    expect(find.text('card level'), findsNothing);
    expect(find.text('based'), findsNothing);
  });

  testWidgets('tile omits a flagged field with no value set', (tester) async {
    final s = _customFieldBoard();
    await tester.pumpWidget(tile(s, _cardIdOf('board_show_custom_fields')));
    await tester.pumpAndSettle();

    expect(find.text('Empty'), findsNothing);
  });

  // The web client prefixes the field name only when the value starts with a
  // number, which on its own would say nothing about what it measures.
  for (final (content, expected) in const [
    ('on front', 'on front'),
    ('42', 'Front: 42'),
    ('42 units', 'Front: 42 units'),
    ('-1.5e3', 'Front: -1.5e3'),
    ('.5', 'Front: .5'),
    ('v2', 'v2'),
  ]) {
    testWidgets('tile chip for "$content" reads "$expected"', (tester) async {
      final s = _chipBoard(content);
      await tester.pumpWidget(tile(s, 'c1'));
      await tester.pumpAndSettle();

      expect(find.text(expected), findsOneWidget);
    });
  }
}
