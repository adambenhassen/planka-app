import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/board_screen.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

class FakeBoardNotifier extends BoardNotifier {
  FakeBoardNotifier(super.boardId);
  @override
  Future<BoardState> build() async => BoardState.fromEnvelope(Envelope.parse(
      jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
          as Map<String, dynamic>));
}

void main() {
  testWidgets('a coloured list shows its colour dot in the header; an '
      'uncoloured one does not', (tester) async {
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
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: BoardScreen(boardId: boardId),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('list-color-dot-1844335857713021962')),
        findsNothing);

    final s = notifier.state.value!;
    final colored = s.lists
        .firstWhere((l) => l.id == '1844335857713021962')
        .copyWith(color: 'berry-red');
    notifier.state = AsyncData(s.copyWith(
        lists: s.lists.map((l) => l.id == colored.id ? colored : l).toList()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('list-color-dot-1844335857713021962')),
        findsOneWidget);
  });
}
