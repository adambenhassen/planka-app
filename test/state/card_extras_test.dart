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

/// Serves the untouched board on GET; echoes PATCH bodies; answers
/// board-membership POSTs with a real row plus the new user included.
class _FakeApi extends PlankaApi {
  _FakeApi({this.fail = false}) : super('http://x', 'tok');
  final bool fail;
  int getCalls = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse(_fixture());
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    if (fail) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': (body as Map).cast<String, dynamic>()});
  }

  @override
  Future<Envelope> delete(String path) async {
    if (fail) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> post(String path, Object? body) async {
    if (fail) throw ApiException(500, 'rejected');
    // POST /cards/<id>/duplicate → a copy of the fixture card at the new position.
    if (path.endsWith('/duplicate')) {
      final cardId = path.split('/')[2];
      final original = (( _fixture()['included']
              as Map)['cards'] as List)
          .cast<Map>()
          .firstWhere((c) => c['id'] == cardId);
      return Envelope.parse({
        'item': {
          ...original.cast<String, dynamic>(),
          'id': 'copy-$cardId',
          'position': (body as Map)['position'],
        },
      });
    }
    final userId = (body as Map)['userId'] as String;
    return Envelope.parse({
      'item': {
        'id': 'bm-new',
        'boardId': _fixture()['item']['id'],
        'userId': userId,
        'role': 'editor',
      },
      'included': {
        'users': [
          {'id': userId, 'name': 'New Member'}
        ],
      },
    });
  }
}

class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() async =>
      BoardState.fromEnvelope(Envelope.parse(_fixture()));
}

Future<(ProviderContainer, BoardNotifier, String, _FakeApi)> boot(
    {bool fail = false}) async {
  final api = _FakeApi(fail: fail);
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(api),
    boardProvider.overrideWith2(_SocketlessNotifier.new),
  ]);
  final boardId = _fixture()['item']['id'] as String;
  await container.read(boardProvider(boardId).future);
  return (container, container.read(boardProvider(boardId).notifier), boardId, api);
}

void main() {
  test('setSubscribed toggles the card watch flag optimistically', () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);
    final cardId =
        container.read(boardProvider(boardId)).value!.cards.values.first.id;

    await notifier.setSubscribed(cardId, true);

    final s = container.read(boardProvider(boardId)).value!;
    expect(s.cards[cardId]!.isSubscribed, isTrue);
  });

  test('setSubscribed failure heals state by refetching', () async {
    final (container, notifier, boardId, api) = await boot(fail: true);
    addTearDown(container.dispose);
    final card =
        container.read(boardProvider(boardId)).value!.cards.values.first;
    final original = card.isSubscribed;
    final getsBefore = api.getCalls;

    await expectLater(notifier.setSubscribed(card.id, original != true),
        throwsA(isA<ApiException>()));

    expect(api.getCalls, getsBefore + 1);
    final s = container.read(boardProvider(boardId)).value!;
    expect(s.cards[card.id]!.isSubscribed, original);
  });

  test('setStopwatch starts and clearStopwatch removes it', () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);
    final cardId =
        container.read(boardProvider(boardId)).value!.cards.values.first.id;

    final startedAt = DateTime.utc(2026, 1, 1, 12);
    await notifier.setStopwatch(cardId, startedAt: startedAt, total: 60);
    var card = container.read(boardProvider(boardId)).value!.cards[cardId]!;
    expect(card.stopwatch!.total, 60);
    expect(card.stopwatch!.startedAt, startedAt);

    await notifier.clearStopwatch(cardId);
    card = container.read(boardProvider(boardId)).value!.cards[cardId]!;
    expect(card.stopwatch, isNull);
  });

  test('setCover sets and clears the cover attachment', () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);
    final cardId =
        container.read(boardProvider(boardId)).value!.cards.values.first.id;

    await notifier.setCover(cardId, 'att1');
    expect(
        container.read(boardProvider(boardId)).value!.cards[cardId]!
            .coverAttachmentId,
        'att1');

    await notifier.setCover(cardId, null);
    expect(
        container.read(boardProvider(boardId)).value!.cards[cardId]!
            .coverAttachmentId,
        isNull);
  });

  test('duplicateCard folds the server copy in after the original', () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);
    final original =
        container.read(boardProvider(boardId)).value!.cards.values.first;

    await notifier.duplicateCard(original.id);

    final s = container.read(boardProvider(boardId)).value!;
    final copy = s.cards['copy-${original.id}']!;
    expect(copy.name, original.name);
    expect(copy.listId, original.listId);
    expect(copy.position, greaterThan(original.position ?? 0));
  });

  test('addBoardMember folds the membership and its user into state',
      () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);

    await notifier.addBoardMember('u-new');

    final s = container.read(boardProvider(boardId)).value!;
    expect(s.boardMemberships.any((m) => m.userId == 'u-new'), isTrue);
    expect(s.users.any((u) => u.id == 'u-new'), isTrue);
  });

  test('removeBoardMember drops the membership optimistically', () async {
    final (container, notifier, boardId, _) = await boot();
    addTearDown(container.dispose);
    final s0 = container.read(boardProvider(boardId)).value!;
    // The fixture board has at least one membership.
    final membership = s0.boardMemberships.first;

    await notifier.removeBoardMember(membership.id);

    final s1 = container.read(boardProvider(boardId)).value!;
    expect(s1.boardMemberships.any((m) => m.id == membership.id), isFalse);
  });
}
