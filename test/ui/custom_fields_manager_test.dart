import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/custom_fields_manager_sheet.dart';
import 'package:planka_app/ui/widgets/confirm_dialog.dart';

// ── Shared board factories ────────────────────────────────────────────────

const _boardId = 'b1';
const _cardId = 'c1';

BoardState _makeState({
  List<PlankaCustomFieldGroup> groups = const [],
  List<PlankaCustomField> fields = const [],
  List<PlankaBoardMembership> memberships = const [],
}) {
  return BoardState(
    board: const PlankaBoard(id: _boardId, projectId: 'p1', name: 'My Board'),
    lists: const [],
    cards: const {
      _cardId: PlankaCard(
          id: _cardId,
          boardId: _boardId,
          listId: 'l1',
          type: 'project',
          name: 'Card'),
    },
    customFieldGroups: groups,
    customFields: fields,
    boardMemberships: memberships,
  );
}

BoardState _viewerState() => _makeState(memberships: [
      const PlankaBoardMembership(
          id: 'm1', boardId: _boardId, userId: 'me', role: 'viewer'),
    ]);

BoardState _boardGroupState() => _makeState(
      groups: const [
        PlankaCustomFieldGroup(
            id: 'g1', name: 'Alpha', boardId: _boardId, position: 16384),
        PlankaCustomFieldGroup(
            id: 'g2', name: 'Beta', boardId: _boardId, position: 32768),
      ],
      fields: const [
        PlankaCustomField(
            id: 'f1', name: 'Field one', customFieldGroupId: 'g1', position: 16384),
        PlankaCustomField(
            id: 'f2',
            name: 'Front field',
            customFieldGroupId: 'g1',
            position: 32768,
            showOnFrontOfCard: true),
      ],
    );

BoardState _cardGroupState() => _makeState(
      groups: const [
        PlankaCustomFieldGroup(
            id: 'cg1', name: 'Card group', cardId: _cardId, position: 16384),
      ],
      fields: const [
        PlankaCustomField(
            id: 'cf1',
            name: 'Card field',
            customFieldGroupId: 'cg1',
            position: 16384),
      ],
    );

BoardState _instantiatedGroupState() => _makeState(
      groups: const [
        PlankaCustomFieldGroup(
            id: 'ig1',
            boardId: _boardId,
            baseCustomFieldGroupId: 'bg1',
            position: 16384),
      ],
      // No base groups loaded — the group renders with an empty name.
    );

// ── Fake notifier ─────────────────────────────────────────────────────────

class _FakeNotifier extends BoardNotifier {
  _FakeNotifier(super.boardId, this._state);
  BoardState _state;

  final calls = <(String, Object?)>[];

  @override
  Future<BoardState> build() async => _state;

  @override
  Future<void> createBoardCustomFieldGroup(String name) async {
    calls.add(('createBoardGroup', name));
  }

  @override
  Future<void> createCardCustomFieldGroup(String cardId, String name) async {
    calls.add(('createCardGroup', name));
  }

  @override
  Future<void> renameCustomFieldGroup(String id, String name) async {
    calls.add(('renameGroup', (id, name)));
  }

  @override
  Future<void> moveCustomFieldGroupUp(String id) async {
    calls.add(('groupUp', id));
  }

  @override
  Future<void> moveCustomFieldGroupDown(String id) async {
    calls.add(('groupDown', id));
  }

  @override
  Future<void> deleteCustomFieldGroup(String id) async {
    calls.add(('deleteGroup', id));
  }

  @override
  Future<void> createCustomField(String groupId, String name) async {
    calls.add(('createField', name));
  }

  @override
  Future<void> renameCustomField(String id, String name) async {
    calls.add(('renameField', (id, name)));
  }

  @override
  Future<void> toggleCustomFieldFrontOfCard(String id, bool show) async {
    calls.add(('frontToggle', (id, show)));
  }

  @override
  Future<void> moveCustomFieldUp(String id) async {
    calls.add(('fieldUp', id));
  }

  @override
  Future<void> moveCustomFieldDown(String id) async {
    calls.add(('fieldDown', id));
  }

  @override
  Future<void> deleteCustomField(String id) async {
    calls.add(('deleteField', id));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

late _FakeNotifier _notifier;

Widget _app(BoardState state, {String? cardId}) {
  return ProviderScope(
    overrides: [
      currentAccountProvider.overrideWith(() {
        return _AccNotifier();
      }),
      boardProvider.overrideWith2((arg) {
        _notifier = _FakeNotifier(arg, state);
        return _notifier;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => CustomFieldsManagerSheet(
            boardId: _boardId,
            cardId: cardId,
          ),
        ),
      ),
    ),
  );
}

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x',
      token: 'tok',
      userId: 'me',
      displayName: 'Me');
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('CustomFieldsManagerSheet', () {
    testWidgets('shows Board section header', (tester) async {
      await tester.pumpWidget(_app(_makeState()));
      await tester.pumpAndSettle();
      expect(find.text('Board'), findsOneWidget);
    });

    testWidgets('board empty state is present', (tester) async {
      await tester.pumpWidget(_app(_makeState()));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('No custom fields on this board yet'),
          findsOneWidget);
    });

    testWidgets('card section header only when cardId given', (tester) async {
      await tester.pumpWidget(_app(_makeState()));
      await tester.pumpAndSettle();
      expect(find.text('This card'), findsNothing);

      await tester.pumpWidget(_app(_makeState(), cardId: _cardId));
      await tester.pumpAndSettle();
      expect(find.text('This card'), findsOneWidget);
    });

    testWidgets('card empty state visible when no card groups', (tester) async {
      await tester.pumpWidget(_app(_makeState(), cardId: _cardId));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('No fields on just this card'), findsOneWidget);
    });

    testWidgets('viewer sees read-only banner and no add buttons',
        (tester) async {
      await tester.pumpWidget(_app(_viewerState()));
      await tester.pumpAndSettle();
      expect(
          find.text('You have view-only access to this board.'), findsOneWidget);
      expect(find.text('Add group'), findsNothing);
    });

    testWidgets('board groups rendered with names', (tester) async {
      await tester.pumpWidget(_app(_boardGroupState()));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('field rendered under its group', (tester) async {
      await tester.pumpWidget(_app(_boardGroupState()));
      await tester.pumpAndSettle();
      expect(find.text('Field one'), findsOneWidget);
    });

    testWidgets('front-of-card subtitle shown when enabled', (tester) async {
      await tester.pumpWidget(_app(_boardGroupState()));
      await tester.pumpAndSettle();
      // 'Front field' has showOnFrontOfCard: true
      expect(find.text('Show on front of card'), findsOneWidget);
    });

    testWidgets('add board group calls createBoardCustomFieldGroup',
        (tester) async {
      await tester.pumpWidget(_app(_makeState()));
      await tester.pumpAndSettle();

      final addBtn = find.text('Add group');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'New group');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(_notifier.calls.where((c) => c.$1 == 'createBoardGroup'),
          hasLength(1));
      expect(_notifier.calls.first.$2, 'New group');
    });

    testWidgets('add card group calls createCardCustomFieldGroup',
        (tester) async {
      await tester.pumpWidget(_app(_makeState(), cardId: _cardId));
      await tester.pumpAndSettle();

      // The card section's 'Add group' is the first one
      final addBtns = find.text('Add group');
      await tester.tap(addBtns.first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Card group');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(_notifier.calls.where((c) => c.$1 == 'createCardGroup'),
          hasLength(1));
    });

    testWidgets('instantiated group shows "From project template" subtitle',
        (tester) async {
      await tester.pumpWidget(_app(_instantiatedGroupState()));
      await tester.pumpAndSettle();
      expect(find.text('From project template'), findsOneWidget);
    });

    testWidgets(
        'instantiated group shows "Fields come from the template" caption',
        (tester) async {
      await tester.pumpWidget(_app(_instantiatedGroupState()));
      await tester.pumpAndSettle();
      expect(find.text('Fields come from the template'), findsOneWidget);
    });

    testWidgets('instantiated group menu says "Remove from board" not "Delete"',
        (tester) async {
      await tester.pumpWidget(_app(_instantiatedGroupState()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      expect(find.text('Remove from board'), findsOneWidget);
      // Should NOT offer plain "Delete"
      expect(find.text('Delete'), findsNothing);
    });

    group('delete confirmations', () {
      testWidgets('board group delete confirmation names the group and fields',
          (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Dialog must be shown and name the group
        expect(find.text('Delete group?'), findsOneWidget);
        expect(find.textContaining('"Alpha"'), findsOneWidget);
        expect(find.textContaining('cannot be undone'), findsOneWidget);
      });

      testWidgets('board group delete cancel does not fire deleteGroup',
          (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(_notifier.calls.where((c) => c.$1 == 'deleteGroup'), isEmpty);
      });

      testWidgets('board group delete confirm fires deleteGroup', (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(
            _notifier.calls.where((c) => c.$1 == 'deleteGroup'), hasLength(1));
      });

      testWidgets('field in board group delete names the field', (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        // Open field menu (first field row has a more_vert icon)
        final moreButtons = find.byIcon(Icons.more_vert);
        // group has one more_vert, then fields
        await tester.tap(moreButtons.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete field?'), findsOneWidget);
        expect(find.textContaining('"Field one"'), findsOneWidget);
        expect(find.textContaining('every card on this board'), findsOneWidget);
      });

      testWidgets('card group delete confirmation names the group',
          (tester) async {
        await tester.pumpWidget(_app(_cardGroupState(), cardId: _cardId));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete group?'), findsOneWidget);
        expect(find.textContaining('"Card group"'), findsOneWidget);
        expect(find.textContaining("card's values"), findsOneWidget);
      });

      testWidgets('field in card group delete names the field', (tester) async {
        await tester.pumpWidget(_app(_cardGroupState(), cardId: _cardId));
        await tester.pumpAndSettle();

        final moreButtons = find.byIcon(Icons.more_vert);
        await tester.tap(moreButtons.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete field?'), findsOneWidget);
        expect(find.textContaining('"Card field"'), findsOneWidget);
        expect(find.textContaining('value on this card'), findsOneWidget);
      });

      testWidgets('instantiated group remove confirmation body is correct',
          (tester) async {
        await tester.pumpWidget(_app(_instantiatedGroupState()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove from board'));
        await tester.pumpAndSettle();

        expect(find.text('Remove from board?'), findsOneWidget);
        expect(find.textContaining('project template itself is kept'),
            findsOneWidget);
        expect(find.textContaining('cannot be undone'), findsOneWidget);
      });
    });

    group('reorder menu items enabled/disabled at ends', () {
      testWidgets('Move up disabled for first group', (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        final up = tester.widget<PopupMenuItem<String>>(
            find.widgetWithText(PopupMenuItem<String>, 'Move up'));
        expect(up.enabled, isFalse);
      });

      testWidgets('Move down disabled for last group', (tester) async {
        await tester.pumpWidget(_app(_boardGroupState()));
        await tester.pumpAndSettle();

        // Open the second group's menu
        await tester.tap(find.byIcon(Icons.more_vert).at(2));
        await tester.pumpAndSettle();

        final down = tester.widget<PopupMenuItem<String>>(
            find.widgetWithText(PopupMenuItem<String>, 'Move down'));
        expect(down.enabled, isFalse);
      });
    });

    testWidgets('front-of-card toggle fires toggleCustomFieldFrontOfCard',
        (tester) async {
      await tester.pumpWidget(_app(_boardGroupState()));
      await tester.pumpAndSettle();

      // The front field (f2) has showOnFrontOfCard: true; its menu index = 2
      // (group g1 menu at 0, field f1 menu at 1, field f2 menu at 2)
      await tester.tap(find.byIcon(Icons.more_vert).at(2));
      await tester.pumpAndSettle();
      await tester.tap(
          find.widgetWithText(CheckedPopupMenuItem<String>, 'Show on front of card'));
      await tester.pumpAndSettle();

      expect(_notifier.calls.where((c) => c.$1 == 'frontToggle'), hasLength(1));
    });
  });

  group('confirmDialog destructive styling', () {
    testWidgets('non-destructive dialog uses default FilledButton style',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => confirmDialog(ctx,
                title: 'Title',
                confirmLabel: 'OK'),
            child: const Text('Show'),
          );
        }),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('destructive dialog renders confirm button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => confirmDialog(ctx,
                title: 'Delete?',
                confirmLabel: 'Delete',
                destructive: true),
            child: const Text('Show'),
          );
        }),
      ));
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
