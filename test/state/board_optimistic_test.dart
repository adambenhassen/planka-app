import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
        as Map<String, dynamic>;

// A card that starts in the fixture's first list, and a different target list.
const _cardId = '1844335858241504267';
const _fromListId = '1844335857713021962';
const _toListId = '1844335855456486408';

/// Serves the untouched board on every GET (the server's source of truth) and
/// optionally rejects the move PATCH so the heal-on-failure path can be driven.
class _FakeApi extends PlankaApi {
  _FakeApi({required this.failMove}) : super('http://x', 'tok');
  final bool failMove;
  int getCalls = 0;
  bool failGets = false;
  bool failDeletes = false;
  Envelope? boardEnvelope;

  /// Holds every GET while open, so events can land mid-rollback.
  Completer<void>? gate;
  Completer<void>? patchGate;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final g = gate;
    if (g != null && !g.isCompleted) await g.future;
    getCalls++;
    if (failGets) throw ApiException(503, 'server unavailable');
    return boardEnvelope ?? Envelope.parse(_fixture());
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    final pending = patchGate;
    if (pending != null) await pending.future;
    if (failMove) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': (body as Map).cast<String, dynamic>()});
  }

  @override
  Future<Envelope> delete(String path) async {
    if (failDeletes) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': <String, dynamic>{}});
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

class _ControlledPatchApi extends _FakeApi {
  _ControlledPatchApi() : super(failMove: false);

  final patchResponses = <Completer<Envelope>>[];

  @override
  Future<Envelope> patch(String path, Object? body) {
    final response = Completer<Envelope>();
    patchResponses.add(response);
    return response.future;
  }
}

class _MutableAccount extends CurrentAccountNotifier {
  Account? account;

  @override
  Account? build() => account;

  void switchTo(Account next) => state = account = next;
}

class _RecordingSocket extends PlankaSocket {
  _RecordingSocket(super.serverUrl, super.token);

  @override
  Stream<SocketEvent> get events => const Stream.empty();

  @override
  Stream<bool> get connected => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> subscribeBoard(String boardId) async {}
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

  test(
      'rejected rename restores its list and keeps listUpdate when rollback GET fails',
      () async {
    final api = _FakeApi(failMove: true)..gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final notifier = container.read(boardProvider(boardId).notifier);
    await container.read(boardProvider(boardId).future);
    final initial = container.read(boardProvider(boardId)).value!;
    final originalName =
        initial.lists.firstWhere((l) => l.id == _fromListId).name;
    final lists = (_fixture()['included']['lists'] as List)
        .cast<Map<String, dynamic>>();
    final bystander = lists.firstWhere((l) => l['id'] != _fromListId);

    final rename = notifier.renameList(_fromListId, 'Optimistic rename');
    await pumpEventQueue();
    expect(
      container.read(boardProvider(boardId)).value!.lists
          .firstWhere((l) => l.id == _fromListId)
          .name,
      'Optimistic rename',
    );
    notifier.applySocketEvent(SocketEvent.parse('listUpdate', {
      'item': {...bystander, 'name': 'Server event remains visible'}
    }));
    api.failGets = true;
    api.gate!.complete();
    await expectLater(rename, throwsA(isA<ApiException>()));

    final state = container.read(boardProvider(boardId)).value!;
    expect(
      state.lists.firstWhere((l) => l.id == _fromListId).name,
      originalName,
      reason: 'a rejected rename is removed after rollback fetch failure',
    );
    expect(
      state.lists.firstWhere((l) => l.id == bystander['id']).name,
      'Server event remains visible',
      reason: 'the concurrent server event is retained',
    );
  });

  test('rejected move restores confirmed state when rollback GET fails',
      () async {
    final (container, notifier, boardId) = await _boot(failMove: true);
    addTearDown(container.dispose);
    final api = container.read(apiProvider) as _FakeApi;
    api.failGets = true;

    await expectLater(
      notifier.moveCard(_cardId, _toListId),
      throwsA(isA<ApiException>()),
    );

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards[_cardId]!.listId, _fromListId,
        reason: 'a failed patch and rollback never leave an unconfirmed move');
  });

  test('moveCard heals back even when an unrelated event lands mid-rollback',
      () async {
    // The server pushes no event for a mutation it refused, so nothing would
    // ever heal the unconfirmed optimistic move if the rollback let a
    // mid-fetch event discard its install — unlike recovery, the rollback
    // must install unconditionally.
    final api = _FakeApi(failMove: true)..gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final notifier = container.read(boardProvider(boardId).notifier);
    await container.read(boardProvider(boardId).future);
    // A bystander list rename: the fixture's third list, touched by neither
    // the move nor the rollback.

    final move = notifier.moveCard(_cardId, _toListId);
    await pumpEventQueue(); // PATCH rejected; the rollback GET now waits
    expect(container.read(boardProvider(boardId)).value!.cards[_cardId]!.listId,
        _toListId); // still optimistic
    final lists = (_fixture()['included']['lists'] as List)
        .cast<Map<String, dynamic>>();
    final bystander = lists
        .firstWhere((l) => l['id'] != _fromListId && l['id'] != _toListId);
    notifier.applySocketEvent(SocketEvent.parse('listUpdate',
        {'item': {...bystander, 'name': 'Renamed mid-rollback'}}));
    api.gate!.complete();
    await expectLater(move, throwsA(isA<ApiException>()));

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards[_cardId]!.listId, _fromListId,
        reason: 'the failed move heals back despite the mid-fetch event');
    // Unlike recovery, the rollback may lose the event itself — installing
    // server truth unconditionally is the older contract here.
  });

  test(
      'rejected move restores card and keeps listUpdate when rollback GET fails',
      () async {
    final api = _FakeApi(failMove: true)..gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final notifier = container.read(boardProvider(boardId).notifier);
    await container.read(boardProvider(boardId).future);
    final initial = container.read(boardProvider(boardId)).value!;
    final originalPosition = initial.cards[_cardId]!.position;
    final lists = (_fixture()['included']['lists'] as List)
        .cast<Map<String, dynamic>>();
    final bystander = lists
        .firstWhere((l) => l['id'] != _fromListId && l['id'] != _toListId);

    final move = notifier.moveCard(_cardId, _toListId);
    await pumpEventQueue();
    expect(
      container.read(boardProvider(boardId)).value!.cards[_cardId]!.listId,
      _toListId,
    );
    notifier.applySocketEvent(SocketEvent.parse('listUpdate', {
      'item': {...bystander, 'name': 'Renamed mid-rollback'}
    }));
    api.failGets = true;
    api.gate!.complete();
    await expectLater(move, throwsA(isA<ApiException>()));

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.cards[_cardId]!.listId, _fromListId,
        reason: 'a rejected move is removed when rollback fetch fails');
    expect(state.cards[_cardId]!.position, originalPosition,
        reason: 'the rejected move position is removed too');
    expect(
      state.lists.firstWhere((list) => list.id == bystander['id']).name,
      'Renamed mid-rollback',
      reason: 'the concurrent server event remains visible',
      );
  });

  test('server cardDelete stays applied when rejected delete rollback GET fails',
      () async {
    final api = _FakeApi(failMove: false)
      ..failDeletes = true
      ..gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final notifier = container.read(boardProvider(boardId).notifier);
    await container.read(boardProvider(boardId).future);

    final deletion = notifier.deleteCard(_cardId);
    await pumpEventQueue(); // DELETE rejected; rollback GET is gated
    notifier.applySocketEvent(SocketEvent.parse('cardDelete', {
      'item': {'id': _cardId}
    }));
    api.failGets = true;
    api.gate!.complete();
    await expectLater(deletion, throwsA(isA<ApiException>()));

    expect(
      container.read(boardProvider(boardId)).value!.cards,
      isNot(contains(_cardId)),
      reason: 'the server deletion must not be resurrected by rollback',
    );
  });

  test(
      'server listDelete keeps its cards absent when rejected delete rollback GET fails',
      () async {
    final api = _FakeApi(failMove: false)
      ..failDeletes = true
      ..gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final notifier = container.read(boardProvider(boardId).notifier);
    await container.read(boardProvider(boardId).future);
    final initial = container.read(boardProvider(boardId)).value!;
    final affectedCardIds = initial.cards.values
        .where((card) => card.listId == _fromListId)
        .map((card) => card.id)
        .toSet();
    final bystander =
        initial.lists.firstWhere((list) => list.id != _fromListId);

    final deletion = notifier.deleteList(_fromListId);
    await pumpEventQueue(); // DELETE rejected; rollback GET is gated
    notifier.applySocketEvent(SocketEvent.parse('listDelete', {
      'item': {'id': _fromListId}
    }));
    notifier.applySocketEvent(SocketEvent.parse('listUpdate', {
      'item': {...bystander.toJson(), 'name': 'Concurrent server rename'}
    }));
    api.failGets = true;
    api.gate!.complete();
    await expectLater(deletion, throwsA(isA<ApiException>()));

    final state = container.read(boardProvider(boardId)).value!;
    expect(state.lists.any((list) => list.id == _fromListId), isFalse);
    for (final cardId in affectedCardIds) {
      expect(
        state.cards.containsKey(cardId),
        isFalse,
        reason: 'cards from the server-deleted list must not be restored',
      );
    }
    expect(
      state.lists.firstWhere((list) => list.id == bystander.id).name,
      'Concurrent server rename',
      reason: 'an unrelated socket update remains visible through rollback',
    );
  });

  for (final firstFailureCompletesFirst in [true, false]) {
    test(
        'overlapping rejected moves leave the original list when the first '
        'failure completes ${firstFailureCompletesFirst ? 'first' : 'last'}',
        () async {
      final api = _ControlledPatchApi();
      final container = ProviderContainer(overrides: [
        apiProvider.overrideWithValue(api),
        boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
      ]);
      addTearDown(container.dispose);
      final boardId = _fixture()['item']['id'] as String;
      final notifier = container.read(boardProvider(boardId).notifier);
      await container.read(boardProvider(boardId).future);
      final thirdListId = (_fixture()['included']['lists'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((list) =>
              list['id'] != _fromListId && list['id'] != _toListId)['id'] as String;

      final first = notifier.moveCard(_cardId, _toListId);
      final second = notifier.moveCard(_cardId, thirdListId);
      await pumpEventQueue();
      expect(api.patchResponses, hasLength(2));
      api.failGets = true;

      final earlier = firstFailureCompletesFirst ? 0 : 1;
      final later = 1 - earlier;
      api.patchResponses[earlier].completeError(ApiException(500, 'rejected'));
      await expectLater(
        earlier == 0 ? first : second,
        throwsA(isA<ApiException>()),
      );
      api.patchResponses[later].completeError(ApiException(500, 'rejected'));
      await expectLater(
        later == 0 ? first : second,
        throwsA(isA<ApiException>()),
      );

      expect(
        container.read(boardProvider(boardId)).value!.cards[_cardId]!.listId,
        _fromListId,
        reason: 'both rejected moves must leave the confirmed original list',
      );
    });
  }

  test('failed write from prior account cannot roll back into the same board on new account',
      () async {
    final accountA = Account(
      serverUrl: 'http://account-a',
      token: 'tok-a',
      userId: 'u1',
      displayName: 'A',
    );
    final accountB = Account(
      serverUrl: 'http://account-b',
      token: 'tok-b',
      userId: 'u1',
      displayName: 'B',
    );
    final apiA = _FakeApi(failMove: true)..patchGate = Completer<void>();
    final apiB = _FakeApi(failMove: false);
    final mutable = _MutableAccount()..account = accountA;
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWith((ref) =>
          ref.watch(currentAccountProvider)?.id == accountA.id ? apiA : apiB),
      currentAccountProvider.overrideWith(() => mutable),
      boardSocketFactoryProvider.overrideWithValue(
          (serverUrl, token) => _RecordingSocket(serverUrl, token)),
    ]);
    addTearDown(container.dispose);
    final boardId = _fixture()['item']['id'] as String;
    final board = boardProvider(boardId);
    await container.read(board.future);
    final accountBFixture = _fixture();
    (accountBFixture['item'] as Map<String, dynamic>)['name'] = 'Account B';
    final bLists = (accountBFixture['included']['lists'] as List)
        .cast<Map<String, dynamic>>();
    bLists.firstWhere((list) => list['id'] == _fromListId)['name'] =
        'Optimistic rename';
    apiB.boardEnvelope = Envelope.parse(accountBFixture);

    final mutation = container
        .read(board.notifier)
        .renameList(_fromListId, 'Optimistic rename');
    await pumpEventQueue();
    mutable.switchTo(accountB);
    await pumpEventQueue();
    await container.read(board.future);
    expect(apiB.getCalls, greaterThan(0));
    expect(container.read(board).value!.board.name, 'Account B');
    expect(
      container.read(board).value!.lists
          .firstWhere((list) => list.id == _fromListId)
          .name,
      'Optimistic rename',
    );

    apiB.failGets = true;
    apiA.patchGate!.complete();
    await expectLater(mutation, throwsA(isA<ApiException>()));

    expect(
      container.read(board).value!.lists
          .firstWhere((list) => list.id == _fromListId)
          .name,
      'Optimistic rename',
      reason: 'account A failure must not merge its baseline into account B',
    );
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
