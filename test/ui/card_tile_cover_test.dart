import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_tile.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

class _AccNotifier extends CurrentAccountNotifier {
  _AccNotifier(this.account);
  final Account? account;
  @override
  Account? build() => account;
}

void main() {
  const board = PlankaBoard(id: 'b1', projectId: 'p1', name: 'B');
  PlankaCard card({String? cover}) => PlankaCard(
      id: 'c1',
      boardId: 'b1',
      listId: 'l1',
      type: 'project',
      name: 'Card',
      coverAttachmentId: cover);
  BoardState stateWith(PlankaCard c,
          {List<PlankaAttachment> atts = const []}) =>
      BoardState(
          board: board, lists: const [], cards: {c.id: c}, attachments: atts);

  Widget host(PlankaCard c, BoardState s) => ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier(Account(
              serverUrl: 'http://x',
              token: 'jwt-123',
              userId: 'u1',
              displayName: 'U'))),
        ],
        child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: CardTile(card: c, state: s))),
      );

  testWidgets('renders cover thumbnail with cookie auth', (tester) async {
    final c = card(cover: 'att1');
    final att = PlankaAttachment(id: 'att1', cardId: 'c1', type: 'file', name: 'p.png', data: {
      'thumbnailUrls': {
        'outside360': 'http://x/360.png',
        'outside720': 'http://x/720.png'
      }
    });
    await tester.pumpWidget(host(c, stateWith(c, atts: [att])));

    final img =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(img.imageUrl, 'http://x/720.png');
    expect(img.httpHeaders, {'Cookie': 'accessToken=jwt-123'});
  });

  testWidgets('no cover attachment → no image', (tester) async {
    final c = card();
    await tester.pumpWidget(host(c, stateWith(c)));
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('Card'), findsOneWidget);
  });

  testWidgets('cover id but non-image attachment → no image', (tester) async {
    final c = card(cover: 'att1');
    final att = PlankaAttachment(
        id: 'att1',
        cardId: 'c1',
        type: 'file',
        name: 'f.txt',
        data: {'thumbnailUrls': null});
    await tester.pumpWidget(host(c, stateWith(c, atts: [att])));
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
