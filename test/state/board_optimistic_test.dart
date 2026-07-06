import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
        as Map<String, dynamic>;

// A card that starts in the fixture's first list, and a different target list.
const _cardId = '1812851462108087322';
const _fromListId = '1812851461772543001';
const _toListId = '1812851461504107543';

/// Serves the untouched board on every GET (the server's source of truth) and
/// optionally rejects the move PATCH so the heal-on-failure path can be driven.
class _FakeApi extends PlankaApi {
  _FakeApi({required this.failMove}) : super('http://x', 'tok');
  final bool failMove;
  int getCalls = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse(_fixture());
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    if (failMove) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': (body as Map).cast<String, dynamic>()});
  }

  @override
  Future<Envelope> post(String path, Object? body) async => Envelope.parse({
        'item': {
          'id': 'srv-card',
          'boardId': 'b1',
          'listId': _fromListId,
          'type': 'project',
          'name': 'Created',
          'position': 100,
        }
      });
}

/// Real BoardNotifier logic (moveCard/_optimistic/_refetch), but seeded from the
/// fixture without opening a live socket.
class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() async =>
      BoardState.fromEnvelope(Envelope.parse(_fixture()));
}

Future<(ProviderContainer, BoardNotifier, String)> _boot(
    {required bool failMove}) async {
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(_FakeApi(failMove: failMove)),
    boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
  ]);
  final boardId = _fixture()['item']['id'] as String;
  await container.read(boardProvider(boardId).future);
  return (container, container.read(boardProvider(boardId).notifier), boardId);
}

void main() {
  test('moveCard optimistically applies and persists when the server accepts',
      () async {
    final (container, notifier, boardId) = await _boot(failMove: false);
    addTearDown(container.dispose);

    await notifier.moveCard(_cardId, _toListId);

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards[_cardId]!.listId, _toListId,
        reason: 'optimistic move sticks on success');
  });

  test('moveCard heals back to server truth and rethrows on ApiException',
      () async {
    final (container, notifier, boardId) = await _boot(failMove: true);
    addTearDown(container.dispose);
    final api = container.read(apiProvider) as _FakeApi;
    final getsBefore = api.getCalls;

    await expectLater(
      notifier.moveCard(_cardId, _toListId),
      throwsA(isA<ApiException>()),
    );

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards[_cardId]!.listId, _fromListId,
        reason: 'failed move is healed back to the server-truth list');
    expect(api.getCalls, greaterThan(getsBefore),
        reason: 'failure triggers a refetch');
  });

  test('createCard folds the server-created card into state (_createInto)',
      () async {
    final (container, notifier, boardId) = await _boot(failMove: false);
    addTearDown(container.dispose);

    await notifier.createCard(_fromListId, 'Created');

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards['srv-card']?.name, 'Created',
        reason: 'the parsed server row is upserted into state');
    expect(state.cardsOf(_fromListId).map((c) => c.id), contains('srv-card'));
  });
}
