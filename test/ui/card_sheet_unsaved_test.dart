import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sheet.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

const _cardId = '1844338625718780953';
const _groupId = '1844338640356901915';
const _fieldId = '1844338649919915036';
const _valueId = '1844338691242198047';

BoardState _board() {
  final board = BoardState.fromEnvelope(
    Envelope.parse(
      jsonDecode(
            File(
              'test/fixtures/board_show_custom_fields.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    ),
  );
  return board.withBaseCustomFields(
    Envelope.parse(
      jsonDecode(
            File(
              'test/fixtures/project_show_custom_fields.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    ),
  );
}

class _RecordingNotifier extends BoardNotifier {
  _RecordingNotifier(super.boardId, this.initial);

  final BoardState initial;
  final calls = <(String, Object?)>[];

  @override
  Future<BoardState> build() async => initial;

  @override
  Future<List<PlankaComment>> fetchComments(String cardId) async => const [];

  @override
  Future<void> renameCard(String cardId, String name) async =>
      calls.add(('renameCard', name));

  @override
  Future<void> setDescription(String cardId, String description) async =>
      calls.add(('setDescription', description));

  @override
  Future<void> setCustomFieldValue(
    String cardId, {
    required String groupId,
    required String fieldId,
    required String content,
  }) async => calls.add(('setCustomFieldValue', (groupId, fieldId, content)));

  @override
  Future<void> createComment(String cardId, String text) async =>
      calls.add(('createComment', text));

  @override
  Future<void> archiveCard(String cardId) async => calls.add(('archive', null));

  @override
  Future<void> moveCardToTrash(String cardId) async =>
      calls.add(('trash', null));

  @override
  Future<void> deleteCard(String cardId) async => calls.add(('delete', null));
}

void main() {
  late _RecordingNotifier notifier;

  Widget app() {
    final board = _board();
    return ProviderScope(
      overrides: [
        boardProvider.overrideWith2(
          (arg) => notifier = _RecordingNotifier(arg, board),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => FilledButton(
                key: const Key('open-card'),
                onPressed: () =>
                    showCardSheet(context, board.board.id, _cardId),
                child: const Text('Open card'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('open-card')));
    await tester.pumpAndSettle();
  }

  Future<void> tapBarrier(WidgetTester tester) async {
    await tester.tapAt(const Offset(12, 40));
    await tester.pumpAndSettle();
  }

  Future<void> expectDiscardDialog(WidgetTester tester) async {
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    expect(
      find.text('Text you entered will be lost if you leave this card.'),
      findsOneWidget,
    );
    expect(find.text('Keep editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  }

  testWidgets('title text is protected from barrier dismissal', (tester) async {
    await openSheet(tester);

    final title = find.byType(TextFormField).first;
    await tester.enterText(title, 'Changed title');
    await tapBarrier(tester);

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('description text is protected from barrier dismissal', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Add a description…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('desc-$_cardId')),
      'Changed description',
    );
    await tapBarrier(tester);

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('tapping outside the description commits it', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add a description…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('desc-$_cardId')),
      'Changed description',
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Stopwatch')),
    );
    await gesture.up();

    expect(notifier.calls, [('setDescription', 'Changed description')]);
  });

  testWidgets('a scrim tap spanning a frame still prompts', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add a description…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('desc-$_cardId')),
      'Changed description',
    );
    final gesture = await tester.startGesture(const Offset(12, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('custom field text is protected from barrier dismissal', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.enterText(
      find.byKey(ValueKey('custom-field-$_fieldId')),
      'Changed value',
    );
    await tapBarrier(tester);

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('discard closes the sheet without submitting typed text', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');
    await tapBarrier(tester);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-card')), findsOneWidget);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('keep editing preserves text and blur submits once', (
    tester,
  ) async {
    await openSheet(tester);
    final title = find.byType(TextFormField).first;
    await tester.enterText(title, 'Changed title');
    await tapBarrier(tester);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.text('Changed title'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(notifier.calls, [('renameCard', 'Changed title')]);

    await tapBarrier(tester);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byKey(const Key('open-card')), findsOneWidget);
  });

  testWidgets('keep editing restores the sheet after a dirty drag', (
    tester,
  ) async {
    await openSheet(tester);
    final sheet = find.byType(CardSheet);
    final initialHeight = tester.getSize(sheet).height;
    final scrollPosition = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final initialScrollOffset = scrollPosition.pixels;
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.dragFrom(const Offset(400, 220), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await expectDiscardDialog(tester);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(tester.getSize(sheet).height, closeTo(initialHeight, 0.1));
    expect(scrollPosition.pixels, closeTo(initialScrollOffset, 0.1));
    expect(find.text('Changed title'), findsOneWidget);
  });

  testWidgets('submitting the description keeps dismissal free of duplicates', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Add a description…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ValueKey('desc-$_cardId')),
      'Changed description',
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(notifier.calls, [('setDescription', 'Changed description')]);

    await tapBarrier(tester);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(find.byKey(const Key('open-card')), findsOneWidget);
    expect(notifier.calls, [('setDescription', 'Changed description')]);
  });

  testWidgets('focused but unchanged title closes without warning or request', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    await tapBarrier(tester);

    expect(find.byKey(const Key('open-card')), findsOneWidget);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('dirty title survives a remote card update', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Local title');

    notifier.applySocketEvent(
      SocketEvent.parse('cardUpdate', {
        'item': {'id': _cardId, 'name': 'Remote title'},
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local title'), findsOneWidget);
    expect(find.text('Remote title'), findsNothing);
    expect(notifier.calls, isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(notifier.calls, [('renameCard', 'Local title')]);
  });

  testWidgets('dirty custom field survives a remote board update', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(
      find.byKey(ValueKey('custom-field-$_fieldId')),
      'Local value',
    );

    notifier.applySocketEvent(
      SocketEvent.parse('customFieldValueUpdate', {
        'item': {
          'id': _valueId,
          'cardId': _cardId,
          'customFieldGroupId': _groupId,
          'customFieldId': _fieldId,
          'content': 'Remote value',
        },
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local value'), findsOneWidget);
    expect(find.text('Remote value'), findsNothing);
    expect(notifier.calls, isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(notifier.calls, [
      ('setCustomFieldValue', (_groupId, _fieldId, 'Local value')),
    ]);
  });

  testWidgets(
    'inline comment text is protected until it is sent or discarded',
    (tester) async {
      await openSheet(tester);
      final comment = find.byType(TextField).last;
      await tester.enterText(comment, 'Unsaved comment');
      await tapBarrier(tester);

      await expectDiscardDialog(tester);
      expect(notifier.calls, isEmpty);
    },
  );

  testWidgets('archive action also asks before closing a dirty sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.tap(find.byTooltip('Archive card'));
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('drag dismissal also asks before closing a dirty sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.dragFrom(const Offset(400, 220), const Offset(0, 1000));
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('a clean drag still dismisses the sheet immediately', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.dragFrom(const Offset(400, 220), const Offset(0, 1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-card')), findsOneWidget);
    expect(find.text('Discard unsaved changes?'), findsNothing);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('a direct navigator pop also asks before closing', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    Navigator.of(tester.element(find.byKey(const Key('open-card')))).pop();
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('system back also asks before closing', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('trash action asks before closing a dirty sheet', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.tap(find.byTooltip('Move to trash'));
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('move action asks before closing a dirty sheet', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.tap(find.byTooltip('Move…'));
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(notifier.calls, isEmpty);
  });

  testWidgets('discarding before archive continues the archive action', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.tap(find.byTooltip('Archive card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-card')), findsOneWidget);
    expect(notifier.calls, [('archive', null)]);
  });

  testWidgets('delete asks about unsaved text before its delete confirmation', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');

    await tester.tap(find.byTooltip('Delete card'));
    await tester.pumpAndSettle();

    await expectDiscardDialog(tester);
    expect(find.text('Delete card?'), findsNothing);
    expect(notifier.calls, isEmpty);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Delete card?'), findsOneWidget);
    expect(notifier.calls, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(notifier.calls, [('delete', null)]);
  });
}
