import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sheet.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _cardId = '1844338625718780953';
const _groupId = '1844338640356901915'; // board group BG
const _fieldId = '1844338649919915036'; // BG → F, holding "hello"
const _emptyFieldId = '1844338684858467358'; // BG → Empty, holding none
const _valueId = '1844338691242198047'; // the row holding "hello"

BoardState _board() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')))
        .withBaseCustomFields(
            Envelope.parse(_json('project_show_custom_fields')));

/// The real sheet over a notifier that records edits instead of sending them,
/// and that can be handed a socket event the way the live one is.
class _RecordingNotifier extends BoardNotifier {
  _RecordingNotifier(super.boardId, this.initial);
  final BoardState initial;

  /// (groupId, fieldId, content) per submitted edit, in order.
  final List<(String, String, String)> edits = [];

  @override
  Future<BoardState> build() async => initial;

  @override
  Future<void> setCustomFieldValue(String cardId,
      {required String groupId,
      required String fieldId,
      required String content}) async {
    edits.add((groupId, fieldId, content));
  }
}

void main() {
  late _RecordingNotifier notifier;

  Widget sheet(BoardState s) => ProviderScope(
        overrides: [
          boardProvider.overrideWith2(
              (arg) => notifier = _RecordingNotifier(arg, s)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CardSheet(boardId: s.board.id, cardId: _cardId)),
        ),
      );

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sheet(_board()));
    await tester.pumpAndSettle();
  }

  Finder fieldOf(String fieldId) => find.byKey(ValueKey('custom-field-$fieldId'));

  TextEditingController controllerOf(WidgetTester tester, String fieldId) =>
      tester
          .widget<EditableText>(find.descendant(
              of: fieldOf(fieldId), matching: find.byType(EditableText)))
          .controller;

  String textOf(WidgetTester tester, String fieldId) =>
      controllerOf(tester, fieldId).text;

  /// Puts the caret in the field without typing into it, the way tapping in
  /// does.
  Future<void> focusField(WidgetTester tester, String fieldId) async {
    await tester.tap(fieldOf(fieldId));
    await tester.pumpAndSettle();
  }

  /// Hands the field over the way pressing enter does.
  Future<void> submit(WidgetTester tester) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> deliver(WidgetTester tester, String name,
      Map<String, dynamic> item) async {
    notifier.applySocketEvent(SocketEvent.parse(name, {'item': item}));
    await tester.pumpAndSettle();
  }

  testWidgets('a field shows the value the card holds', (tester) async {
    await pumpSheet(tester);

    expect(textOf(tester, _fieldId), 'hello');
    // A field nobody has set a value for shows an empty line, not a
    // placeholder — the same thing a cleared field shows.
    expect(textOf(tester, _emptyFieldId), '');
  });

  testWidgets('a typed value is submitted for its (group, field) pair',
      (tester) async {
    await pumpSheet(tester);

    await tester.enterText(fieldOf(_fieldId), 'world');
    await submit(tester);

    expect(notifier.edits, [(_groupId, _fieldId, 'world')]);
  });

  testWidgets('a value typed into a field that had none is submitted',
      (tester) async {
    await pumpSheet(tester);

    await tester.enterText(fieldOf(_emptyFieldId), 'now set');
    await submit(tester);

    expect(notifier.edits, [(_groupId, _emptyFieldId, 'now set')]);
  });

  testWidgets('clearing the text submits a blank value', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(fieldOf(_fieldId), '');
    await submit(tester);

    // Blank is what clears it; the notifier turns that into a delete.
    expect(notifier.edits, [(_groupId, _fieldId, '')]);
  });

  testWidgets('leaving a field untouched submits nothing', (tester) async {
    await pumpSheet(tester);

    await tester.tap(fieldOf(_fieldId));
    await tester.pumpAndSettle();
    await submit(tester);
    // Retyping the value it already holds is not an edit either.
    await tester.enterText(fieldOf(_fieldId), ' hello ');
    await submit(tester);

    expect(notifier.edits, isEmpty);
  });

  testWidgets('a value edited elsewhere replaces the text', (tester) async {
    await pumpSheet(tester);

    await deliver(tester, 'customFieldValueUpdate', {
      'id': _valueId,
      'cardId': _cardId,
      'customFieldGroupId': _groupId,
      'customFieldId': _fieldId,
      'content': 'from the web',
    });

    expect(textOf(tester, _fieldId), 'from the web');
  });

  testWidgets('a value cleared elsewhere empties the field', (tester) async {
    await pumpSheet(tester);

    await deliver(tester, 'customFieldValueDelete', {
      'id': _valueId,
      'cardId': _cardId,
      'customFieldGroupId': _groupId,
      'customFieldId': _fieldId,
      'content': 'hello',
    });

    expect(textOf(tester, _fieldId), '');
  });

  testWidgets('a focused field nobody has typed in takes an edit from '
      'elsewhere', (tester) async {
    await pumpSheet(tester);

    // Tapped into and left alone: holding the caret is not an edit, so the
    // value another client just wrote is the one that belongs here.
    await focusField(tester, _fieldId);
    await deliver(tester, 'customFieldValueUpdate', {
      'id': _valueId,
      'cardId': _cardId,
      'customFieldGroupId': _groupId,
      'customFieldId': _fieldId,
      'content': 'from the web',
    });

    expect(textOf(tester, _fieldId), 'from the web');
    // And leaving it hands nothing back — least of all the value it held
    // before, which nobody typed.
    await submit(tester);
    expect(notifier.edits, isEmpty);
  });

  testWidgets('a focused field nobody has typed in takes a delete from '
      'elsewhere', (tester) async {
    await pumpSheet(tester);

    await focusField(tester, _fieldId);
    await deliver(tester, 'customFieldValueDelete', {
      'id': _valueId,
      'cardId': _cardId,
      'customFieldGroupId': _groupId,
      'customFieldId': _fieldId,
      'content': 'hello',
    });

    expect(textOf(tester, _fieldId), '');
    // Leaving the field must not write the deleted value back.
    await submit(tester);
    expect(notifier.edits, isEmpty);
  });

  testWidgets('an edit in progress is not overwritten by one from elsewhere',
      (tester) async {
    await pumpSheet(tester);

    await tester.enterText(fieldOf(_fieldId), 'half typed');
    // Caret mid-word, where a rebuild that reset the text would move it.
    controllerOf(tester, _fieldId).selection =
        const TextSelection.collapsed(offset: 4);
    await deliver(tester, 'customFieldValueUpdate', {
      'id': _valueId,
      'cardId': _cardId,
      'customFieldGroupId': _groupId,
      'customFieldId': _fieldId,
      'content': 'from the web',
    });

    expect(textOf(tester, _fieldId), 'half typed');
    expect(controllerOf(tester, _fieldId).selection.baseOffset, 4);
    // And submitting still hands over what was typed.
    await submit(tester);
    expect(notifier.edits, [(_groupId, _fieldId, 'half typed')]);
  });

  testWidgets('a field added elsewhere appears in its group', (tester) async {
    await pumpSheet(tester);

    await deliver(tester, 'customFieldCreate', {
      'id': 'f-new',
      'name': 'Added',
      'position': 65536,
      'showOnFrontOfCard': false,
      'customFieldGroupId': _groupId,
      'baseCustomFieldGroupId': null,
    });

    expect(find.text('Added'), findsOneWidget);
    expect(fieldOf('f-new'), findsOneWidget);
  });

  testWidgets('a group renamed elsewhere shows its new name', (tester) async {
    await pumpSheet(tester);

    await deliver(tester, 'customFieldGroupUpdate', {
      'id': _groupId,
      'name': 'Renamed',
    });

    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('BG'), findsNothing);
    // The partial payload a rename can carry must not cost the group its
    // fields.
    expect(fieldOf(_fieldId), findsOneWidget);
  });

  testWidgets('a group deleted elsewhere leaves the card', (tester) async {
    await pumpSheet(tester);

    await deliver(tester, 'customFieldGroupDelete', {'id': _groupId});

    expect(find.text('BG'), findsNothing);
    expect(fieldOf(_fieldId), findsNothing);
    // The card's own group is untouched.
    expect(find.text('CG'), findsOneWidget);
  });

  testWidgets('closing the sheet does not submit the field being edited',
      (tester) async {
    await pumpSheet(tester);

    await tester.enterText(fieldOf(_fieldId), 'abandoned');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(notifier.edits, isEmpty);
  });
}
