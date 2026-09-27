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
import 'package:planka_app/state/envelope_cache.dart';
import 'package:planka_app/state/user_socket.dart';

const _boardId = '1844338624586318868';
const _cardId = '1844335858241504267';

final _account = Account(
  serverUrl: 'https://planka.example.com',
  token: 'tok',
  userId: 'u1',
  displayName: 'Test',
);

class _FixedAccount extends CurrentAccountNotifier {
  @override
  Account build() => _account;
}

class _FakeApi extends PlankaApi {
  _FakeApi() : super('https://planka.example.com', 'tok');

  Completer<void>? gate;
  Completer<void>? patchGate;
  final patchStarted = Completer<void>();
  final getStarted = Completer<void>();
  final secondGetStarted = Completer<void>();
  var getCalls = 0;
  bool failGets = false;
  var boardName = 'Fresh Board';
  String? cardName;
  String? omitCardId;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    if (!getStarted.isCompleted) getStarted.complete();
    if (getCalls == 2 && !secondGetStarted.isCompleted) {
      secondGetStarted.complete();
    }
    final pending = gate;
    if (pending != null) await pending.future;
    if (failGets) throw ApiException(503, 'server unavailable');
    final json = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (json['item'] as Map<String, dynamic>)['name'] = boardName;
    final cards = ((json['included'] as Map<String, dynamic>)['cards'] as List)
        .cast<Map<String, dynamic>>();
    if (omitCardId != null) {
      cards.removeWhere((card) => card['id'] == omitCardId);
    }
    if (cardName != null) {
      cards.firstWhere((card) => card['id'] == _cardId)['name'] = cardName;
    }
    return Envelope.parse(json);
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    if (!patchStarted.isCompleted) patchStarted.complete();
    final pending = patchGate;
    if (pending != null) await pending.future;
    return Envelope.parse({'item': (body as Map).cast<String, dynamic>()});
  }
}

class _CountingEnvelopeCache extends EnvelopeCache {
  _CountingEnvelopeCache({required super.directory});

  var putCalls = 0;

  @override
  Future<void> put(String key, Envelope env) {
    putCalls++;
    return super.put(key, env);
  }
}

class _GatedEnvelopeCache extends EnvelopeCache {
  _GatedEnvelopeCache({required super.directory});

  Completer<void>? putGate;
  final gatedPutStarted = Completer<void>();
  var putCalls = 0;

  @override
  Future<void> put(String key, Envelope env) async {
    putCalls++;
    final gate = putGate;
    if (putCalls == 1 && gate != null) {
      gatedPutStarted.complete();
      await gate.future;
    }
    await super.put(key, env);
  }
}

class _NoopSocket extends PlankaSocket {
  _NoopSocket(super.serverUrl, super.token);

  @override
  Future<void> connect() async {}

  @override
  Future<void> subscribeBoard(String boardId) async {}
}

class _LoadingNotifier extends BoardNotifier {
  _LoadingNotifier(super.boardId);

  @override
  Future<BoardState> build() => load();
}

class _FailingPutEnvelopeCache extends EnvelopeCache {
  _FailingPutEnvelopeCache({required Directory directory})
    : super(directory: directory);

  @override
  Future<void> put(String key, Envelope env) =>
      Future<void>.error(StateError('cache write failed'));
}

void main() {
  test('renders cached board before the refresh and reconciles it', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_first');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    await EnvelopeCache(directory: dir).put(
      '${_account.id}-board-$_boardId',
      Envelope.parse(cachedJson),
    );

    final api = _FakeApi()..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final cachedPublished = Completer<BoardState>();
    final freshPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'Cached Board' &&
          !cachedPublished.isCompleted) {
        cachedPublished.complete(value!);
      }
      if (value?.board.name == 'Fresh Board' &&
          !freshPublished.isCompleted) {
        freshPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);

    final cachedState = await cachedPublished.future;
    await api.getStarted.future;
    expect(cachedState.board.name, 'Cached Board');
    expect(cachedState.isStale, isFalse);

    api.boardName = 'Fresh Board';
    api.gate!.complete();
    final freshState = await freshPublished.future;
    expect(freshState.isStale, isFalse);
  });

  test('failed refresh marks the cached board stale', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_offline');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    await EnvelopeCache(directory: dir).put(
      '${_account.id}-board-$_boardId',
      Envelope.parse(cachedJson),
    );

    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()..failGets = true),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final stalePublished = Completer<BoardState>();
    final subscription = container.listen(
      boardProvider(_boardId),
      (previous, next) {
        final value = next.value;
        if (value?.isStale == true && !stalePublished.isCompleted) {
          stalePublished.complete(value!);
        }
      },
    );
    addTearDown(subscription.close);
    container.read(boardProvider(_boardId));

    final stale = await stalePublished.future;
    expect(stale.board.name, 'Cached Board');
    expect(stale.isStale, isTrue);
  });

  test('successful board fetch is shown when its cache write fails', () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_write_failure',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    await EnvelopeCache(directory: dir).put(
      '${_account.id}-board-$_boardId',
      Envelope.parse(cachedJson),
    );

    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(
          _FailingPutEnvelopeCache(directory: dir),
        ),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final freshPublished = Completer<BoardState>();
    final subscription = container.listen(
      boardProvider(_boardId),
      (previous, next) {
        final value = next.value;
        if (value?.board.name == 'Fresh Board' &&
            !freshPublished.isCompleted) {
          freshPublished.complete(value!);
        }
      },
    );
    addTearDown(subscription.close);
    container.read(boardProvider(_boardId));

    final loaded = await freshPublished.future;
    expect(loaded.board.name, 'Fresh Board');
    expect(loaded.isStale, isFalse);
  });

  test('confirmed card edits survive a cold offline reopen', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_edit');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = EnvelopeCache(directory: dir);
    final api = _FakeApi()..patchGate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    final provider = boardProvider(_boardId);
    await container.read(provider.future);
    final originalName = container.read(provider).value!.cards[_cardId]!.name;

    final edit = container.read(provider.notifier).renameCard(
          _cardId,
          'Saved edit',
        );
    await api.patchStarted.future;
    final persistedWhilePending = await cache.get(
      '${_account.id}-board-$_boardId',
    );
    expect(
      BoardState.fromEnvelope(persistedWhilePending!).cards[_cardId]!.name,
      originalName,
      reason: 'an optimistic value must not reach disk before confirmation',
    );

    api.patchGate!.complete();
    await edit;
    container.dispose();

    final offlineContainer = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()..failGets = true),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(offlineContainer.dispose);
    final reopened = await offlineContainer.read(
      boardProvider(_boardId).future,
    );
    expect(reopened!.cards[_cardId]!.name, 'Saved edit');
  });

  test('socket-delivered card changes survive a cold offline reopen', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_socket');
    addTearDown(() => dir.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    final provider = boardProvider(_boardId);
    await container.read(provider.future);
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Socket update'},
          }),
        );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    container.dispose();

    final offlineContainer = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()..failGets = true),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(offlineContainer.dispose);
    final reopened = await offlineContainer.read(
      boardProvider(_boardId).future,
    );
    expect(reopened!.cards[_cardId]!.name, 'Socket update');
  });

  test('a burst of socket changes is coalesced into one cache write', () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_burst');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = _CountingEnvelopeCache(directory: dir);
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    final provider = boardProvider(_boardId);
    await container.read(provider.future);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final writesBeforeBurst = cache.putCalls;

    final notifier = container.read(provider.notifier);
    for (var index = 0; index < 12; index++) {
      notifier.applySocketEvent(
        SocketEvent.parse('cardUpdate', {
          'item': {'id': _cardId, 'name': 'Update $index'},
        }),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(cache.putCalls - writesBeforeBurst, 1);
  });

  test('a same-account rebuild flushes a confirmed change before reload',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_rebuild');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = EnvelopeCache(directory: dir);
    final api = _FakeApi();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    notifier.applySocketEvent(
      SocketEvent.parse('cardUpdate', {
        'item': {'id': _cardId, 'name': 'Confirmed realtime change'},
      }),
    );

    api
      ..gate = Completer<void>()
      ..cardName = 'Confirmed realtime change';
    container.read(accountStateEpochProvider.notifier).invalidate();
    container.read(provider);
    await api.secondGetStarted.future;

    final persistedDuringReload = await cache.get(
      '${_account.id}-board-$_boardId',
    );
    expect(
      BoardState.fromEnvelope(persistedDuringReload!).cards[_cardId]!.name,
      'Confirmed realtime change',
      reason: 'a same-account rebuild must flush the debounced snapshot first',
    );

    api.gate!.complete();
    await container.read(provider.future);
  });

  test('a pending snapshot write cannot replace a newer full board fetch',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_fetch_order');
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = '${_account.id}-board-$_boardId';
    final oldJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    await EnvelopeCache(directory: dir).put(key, Envelope.parse(oldJson));

    final cache = _GatedEnvelopeCache(directory: dir)
      ..putGate = Completer<void>();
    final api = _FakeApi()
      ..gate = Completer<void>()
      ..boardName = 'New server board'
      ..omitCardId = _cardId;
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final freshPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'New server board' &&
          !freshPublished.isCompleted) {
        freshPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);
    await api.getStarted.future;
    await cache.gatedPutStarted.future;

    api.gate!.complete();
    await pumpEventQueue();
    expect(
      cache.putCalls,
      1,
      reason: 'a full fetch must wait for the older snapshot write to finish',
    );
    cache.putGate!.complete();
    final loaded = await freshPublished.future;
    expect(loaded.board.name, 'New server board');

    final persisted = await cache.get(key);
    expect(persisted!.item['name'], 'New server board');
    expect(
      BoardState.fromEnvelope(persisted).cards.containsKey(_cardId),
      isFalse,
      reason: 'rows deleted by the server must stay absent after fetch install',
    );
  });
}
