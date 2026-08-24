import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
        as Map<String, dynamic>;

SocketEvent ev(String name, Map<String, dynamic> payload) =>
    SocketEvent.parse(name, payload);

/// The raw board row the fixture carries, for socket payloads that echo it.
Map<String, dynamic> rawBoardItem() =>
    ((jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
            as Map<String, dynamic>)['item'] as Map)
        .cast<String, dynamic>();

BoardState seed() =>
    BoardState.fromEnvelope(Envelope.parse(_fixture()));

/// Records create-card bodies so the type the notifier sends is observable.
class _RecordingApi extends PlankaApi {
  _RecordingApi() : super('http://x', 'tok');
  Map<String, dynamic>? lastCardBody;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse(_fixture());

  @override
  Future<Envelope> post(String path, Object? body) async {
    final map = (body as Map?)?.cast<String, dynamic>() ?? {};
    if (path.endsWith('/cards')) lastCardBody = map;
    return Envelope.parse({
      'item': {
        'id': 'srv-card',
        'boardId': 'b1',
        'listId': map['listId'] ?? 'l1',
        'type': map['type'] ?? 'project',
        'name': map['name'] ?? '',
        'position': map['position'] ?? 100,
      }
    });
  }
}

class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() async =>
      BoardState.fromEnvelope(Envelope.parse(_fixture()));
}

void main() {
  test('parses every per-board display setting', () {
    final b = seed().board;
    expect(b.defaultView, 'kanban');
    expect(b.defaultCardType, 'project');
    expect(b.limitCardTypesToDefaultOne, false);
    expect(b.alwaysDisplayCardCreator, false);
    expect(b.displayCardAges, false);
    expect(b.expandTaskListsByDefault, false);
  });

  test('parses list colour and card creator/age/comment fields', () {
    final s = seed();
    final card = s.cards.values.single;
    expect(card.creatorUserId, isNotEmpty);
    expect(card.listChangedAt, isNotNull);
    expect(card.commentsTotal, 1);
    final colored = s.lists.first.copyWith(color: 'berry-red');
    expect(colored.color, 'berry-red');
  });

  test('boardUpdate folds new display settings in', () {
    final s = seed();
    final next = applyEvent(
        s,
        ev('boardUpdate', {
          // The server broadcasts full board rows on boardUpdate.
          'item': {
            ...rawBoardItem(),
            'displayCardAges': true,
            'alwaysDisplayCardCreator': true,
          }
        }));
    expect(next.board.displayCardAges, true);
    expect(next.board.alwaysDisplayCardCreator, true);
    // Untouched fields survive a partial payload.
    expect(next.board.name, s.board.name);
  });

  test('createCard sends the board defaultCardType', () async {
    final raw = _fixture();
    raw['item']['defaultCardType'] = 'story';
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(_RecordingApi()),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = (raw['item']['id'] as String);
    await container.read(boardProvider(boardId).future);
    final notifier = container.read(boardProvider(boardId).notifier);
    notifier.state = AsyncData(BoardState.fromEnvelope(Envelope.parse(raw)));
    await notifier.createCard('1844335857713021962', 'New');
    final api = container.read(apiProvider) as _RecordingApi;
    expect(api.lastCardBody?['type'], 'story');
  });
}
