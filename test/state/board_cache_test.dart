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
import 'package:planka_app/cache_lifecycle.dart';
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

class _MutableAccount extends CurrentAccountNotifier {
  _MutableAccount(this.initial);

  final Account? initial;

  @override
  Account? build() => initial;

  @override
  Future<void> select(Account? account, {bool invalidateState = true}) async {
    if (invalidateState) {
      ref.read(accountStateEpochProvider.notifier).invalidate(
        preserveSameAccountState:
            state?.id != null && state?.id == account?.id,
      );
    }
    state = account;
  }
}

class _FakeApi extends PlankaApi {
  _FakeApi() : super('https://planka.example.com', 'tok');

  Completer<void>? gate;
  Completer<void>? patchGate;
  final patchStarted = Completer<void>();
  final getStarted = Completer<void>();
  final getFailureObserved = Completer<ApiException>();
  var getCalls = 0;
  bool failGets = false;
  int? getFailureStatusCode = 503;
  var boardName = 'Fresh Board';
  String? accountMarker;
  String? cardName;
  String? omitCardId;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    if (!getStarted.isCompleted) getStarted.complete();
    final pending = gate;
    if (pending != null) await pending.future;
    if (failGets) {
      final error = ApiException(getFailureStatusCode, 'server unavailable');
      if (!getFailureObserved.isCompleted) getFailureObserved.complete(error);
      throw error;
    }
    final json = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (json['item'] as Map<String, dynamic>)['name'] = boardName;
    if (accountMarker != null) json['accountMarker'] = accountMarker;
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
  _GatedEnvelopeCache({required super.directory, this.gateOnPutCall = 1});

  final int gateOnPutCall;
  Completer<void>? putGate;
  final gatedPutStarted = Completer<void>();
  final deleteFinished = Completer<void>();
  final conditionalDeleteFinished = Completer<void>();
  final conditionalDeleteStarted = Completer<void>();
  Completer<void>? conditionalDeleteGate;
  var putCalls = 0;
  var deleteCalls = 0;
  var conditionalDeleteCalls = 0;
  bool? conditionalDeleteResult;

  Future<void> _gatePut() async {
    putCalls++;
    final gate = putGate;
    if (putCalls == gateOnPutCall && gate != null) {
      if (!gatedPutStarted.isCompleted) gatedPutStarted.complete();
      await gate.future;
    }
  }

  @override
  Future<void> put(String key, Envelope env) async {
    await _gatePut();
    await super.put(key, env);
  }

  @override
  Future<bool> putReplacement(String key, Envelope env) async {
    await _gatePut();
    return super.putReplacement(key, env);
  }

  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    try {
      await super.delete(key);
    } finally {
      if (!deleteFinished.isCompleted) deleteFinished.complete();
    }
  }

  @override
  Future<bool> deleteIfUnchanged(
    String key,
    int expectedGeneration,
  ) async {
    conditionalDeleteCalls++;
    final gate = conditionalDeleteGate;
    if (gate != null) {
      if (!conditionalDeleteStarted.isCompleted) {
        conditionalDeleteStarted.complete();
      }
      await gate.future;
    }
    try {
      final result = await super.deleteIfUnchanged(
        key,
        expectedGeneration,
      );
      conditionalDeleteResult = result;
      if (result) {
        deleteCalls++;
        if (!deleteFinished.isCompleted) deleteFinished.complete();
      }
      return result;
    } finally {
      if (!conditionalDeleteFinished.isCompleted) {
        conditionalDeleteFinished.complete();
      }
    }
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

class _RecoveringNotifier extends BoardNotifier {
  _RecoveringNotifier(super.boardId);

  void triggerRecovery() => recoverRealtime();
}

class _FailingPutEnvelopeCache extends EnvelopeCache {
  _FailingPutEnvelopeCache({required Directory directory})
    : super(directory: directory);

  @override
  Future<void> put(String key, Envelope env) =>
      Future<void>.error(StateError('cache write failed'));

  @override
  Future<bool> putReplacement(String key, Envelope env) async => false;
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

  for (final statusCode in <int?>[null, 503]) {
    test('transient board failure $statusCode keeps the cached board', () async {
      final dir = Directory.systemTemp.createTempSync(
        'board_cache_offline_${statusCode ?? 'network'}',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final cache = EnvelopeCache(directory: dir);
      final key = '${_account.id}-board-$_boardId';
      final cachedJson = jsonDecode(
        File('test/fixtures/board_show.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
      await cache.put(key, Envelope.parse(cachedJson));

      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            _FakeApi()
              ..failGets = true
              ..getFailureStatusCode = statusCode,
          ),
          currentAccountProvider.overrideWith(_FixedAccount.new),
          envelopeCacheProvider.overrideWithValue(cache),
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
      expect(await cache.get(key), isNotNull);

      container.dispose();
      final coldContainer = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(_FakeApi()..failGets = true),
          currentAccountProvider.overrideWith(_FixedAccount.new),
          envelopeCacheProvider.overrideWithValue(cache),
          boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
        ],
      );
      addTearDown(coldContainer.dispose);
      final reopened = Completer<BoardState>();
      final coldSubscription = coldContainer.listen(
        boardProvider(_boardId),
        (previous, next) {
          final value = next.value;
          if (value?.isStale == true && !reopened.isCompleted) {
            reopened.complete(value!);
          }
        },
      );
      addTearDown(coldSubscription.close);
      coldContainer.read(boardProvider(_boardId));
      final reopenedState = await reopened.future;
      expect(reopenedState.board.name, 'Cached Board');
      expect(reopenedState.isStale, isTrue);
    });
  }

  for (final statusCode in [403, 404]) {
    test('$statusCode board load deletes only its account snapshot', () async {
      final dir = Directory.systemTemp.createTempSync(
        'board_cache_revoked_$statusCode',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final cache = EnvelopeCache(directory: dir);
      final otherAccount = Account(
        serverUrl: _account.serverUrl,
        token: 'tok-other',
        userId: 'u2',
        displayName: 'Other',
      );
      final targetKey = '${_account.id}-board-$_boardId';
      final otherBoardKey = '${_account.id}-board-$_boardId-other';
      final otherAccountKey = '${otherAccount.id}-board-$_boardId';
      final cachedJson = jsonDecode(
        File('test/fixtures/board_show.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      await cache.put(targetKey, Envelope.parse(cachedJson));
      await cache.put(otherBoardKey, Envelope.parse(cachedJson));
      await cache.put(otherAccountKey, Envelope.parse(cachedJson));

      final container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            _FakeApi()
              ..failGets = true
              ..getFailureStatusCode = statusCode,
          ),
          currentAccountProvider.overrideWith(_FixedAccount.new),
          envelopeCacheProvider.overrideWithValue(cache),
          boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
        ],
      );
      addTearDown(container.dispose);
      final provider = boardProvider(_boardId);
      final loadFailed = Completer<Object?>();
      final subscription = container.listen(provider, (previous, next) {
        if (next.hasError && !loadFailed.isCompleted) {
          loadFailed.complete(next.error);
        }
      });
      addTearDown(subscription.close);
      container.read(provider);
      await expectLater(
        loadFailed.future,
        completion(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            equals(statusCode),
          ),
        ),
      );

      expect(await cache.get(targetKey), isNull);
      expect(await cache.get(otherBoardKey), isNotNull);
      expect(await cache.get(otherAccountKey), isNotNull);

      container.dispose();
      expect(
        await cache.get(targetKey),
        isNull,
        reason: 'disposing the failed load must not restore the revoked board',
      );
      final coldContainer = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(
            _FakeApi()
              ..failGets = true
              ..getFailureStatusCode = null,
          ),
          currentAccountProvider.overrideWith(_FixedAccount.new),
          envelopeCacheProvider.overrideWithValue(cache),
          boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
        ],
      );
      addTearDown(coldContainer.dispose);
      final coldProvider = boardProvider(_boardId);
      final coldLoadSettled = Completer<AsyncValue<BoardState?>>();
      final coldSubscription = coldContainer.listen(
        coldProvider,
        (previous, next) {
          if ((next.hasError || next.value?.isStale == true) &&
              !coldLoadSettled.isCompleted) {
            coldLoadSettled.complete(next);
          }
        },
      );
      addTearDown(coldSubscription.close);
      coldContainer.read(coldProvider);
      final reopened = await coldLoadSettled.future;
      expect(reopened.hasError, isTrue);
      expect(reopened.value, isNull);
      expect(
        reopened.error,
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          isNull,
        ),
      );
    });
  }

  for (final statusCode in [403, 404]) {
    test('$statusCode reconnect denial deletes its board snapshot', () async {
      final dir = Directory.systemTemp.createTempSync(
        'board_cache_reconnect_denied_$statusCode',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final cache = _GatedEnvelopeCache(directory: dir);
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
          boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
        ],
      );
      addTearDown(container.dispose);
      final provider = boardProvider(_boardId);
      final key = '${_account.id}-board-$_boardId';
      await container.read(provider.future);
      expect(await cache.get(key), isNotNull);

      api
        ..failGets = true
        ..getFailureStatusCode = statusCode;
      (container.read(provider.notifier) as _RecoveringNotifier)
          .triggerRecovery();
      await cache.deleteFinished.future.timeout(const Duration(seconds: 2));
      await pumpEventQueue();

      expect(cache.deleteCalls, 1);
      expect(await cache.get(key), isNull);
      expect(container.read(provider).value, isNull);
      container.dispose();
      expect(await cache.get(key), isNull);

      final coldContainer = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(_FakeApi()..failGets = true),
          currentAccountProvider.overrideWith(_FixedAccount.new),
          envelopeCacheProvider.overrideWithValue(cache),
          boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
        ],
      );
      addTearDown(coldContainer.dispose);
      final coldProvider = boardProvider(_boardId);
      final coldLoadSettled = Completer<AsyncValue<BoardState?>>();
      final coldSubscription = coldContainer.listen(
        coldProvider,
        (previous, next) {
          if ((next.hasError || next.value?.isStale == true) &&
              !coldLoadSettled.isCompleted) {
            coldLoadSettled.complete(next);
          }
        },
      );
      addTearDown(coldSubscription.close);
      coldContainer.read(coldProvider);
      final reopened = await coldLoadSettled.future;
      expect(reopened.hasError, isTrue);
      expect(reopened.value, isNull);
    });
  }

  test('an old denied load preserves a refreshed same-account snapshot',
      () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_old_denial',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = _GatedEnvelopeCache(directory: dir);
    final oldApi = _FakeApi()..gate = Completer<void>();
    final refreshedApi = _FakeApi()..boardName = 'Replacement Board';
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith(
          (ref) => ref.watch(currentAccountProvider)?.token == _account.token
              ? oldApi
              : refreshedApi,
        ),
        currentAccountProvider.overrideWith(() => _MutableAccount(_account)),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
        boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final replacementPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'Replacement Board' &&
          !replacementPublished.isCompleted) {
        replacementPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);
    await oldApi.getStarted.future;

    await container.read(currentAccountProvider.notifier).select(
          _account.copyWith(token: 'refreshed-token'),
        );
    container.read(provider);
    await replacementPublished.future;
    final key = '${_account.id}-board-$_boardId';
    expect(
      BoardState.fromEnvelope((await cache.get(key))!).board.name,
      'Replacement Board',
    );

    oldApi
      ..failGets = true
      ..getFailureStatusCode = 403
      ..gate!.complete();
    await oldApi.getFailureObserved.future;
    await pumpEventQueue();

    expect(cache.deleteCalls, 0);
    expect(
      BoardState.fromEnvelope((await cache.get(key))!).board.name,
      'Replacement Board',
    );
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Replacement write'},
          }),
        );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      BoardState.fromEnvelope((await cache.get(key))!).cards[_cardId]!.name,
      'Replacement write',
    );
  });

  for (final statusCode in [403, 404]) {
    test(
      '$statusCode denial after a failed refresh deletes the snapshot',
      () async {
        final dir = Directory.systemTemp.createTempSync(
          'board_cache_late_denial_refresh_failure_$statusCode',
        );
        addTearDown(() => dir.deleteSync(recursive: true));
        final key = '${_account.id}-board-$_boardId';
        final cachedJson = jsonDecode(
          File('test/fixtures/board_show.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        (cachedJson['item'] as Map<String, dynamic>)['name'] =
            'Revoked cached board';
        final cache = _GatedEnvelopeCache(directory: dir);
        await cache.put(key, Envelope.parse(cachedJson));

        final oldApi = _FakeApi()..gate = Completer<void>();
        final refreshedApi = _FakeApi()
          ..failGets = true
          ..getFailureStatusCode = 503;
        final container = ProviderContainer(
          overrides: [
            apiProvider.overrideWith(
              (ref) => ref.watch(currentAccountProvider)?.token ==
                      _account.token
                  ? oldApi
                  : refreshedApi,
            ),
            currentAccountProvider.overrideWith(
              () => _MutableAccount(_account),
            ),
            envelopeCacheProvider.overrideWithValue(cache),
            boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
            userSocketProvider.overrideWithValue(null),
            userEventsProvider.overrideWithValue(const Stream.empty()),
            userConnectedProvider.overrideWithValue(const Stream.empty()),
            boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
          ],
        );
        addTearDown(container.dispose);
        final provider = boardProvider(_boardId);
        final staleRefreshPublished = Completer<BoardState>();
        final subscription = container.listen(provider, (previous, next) {
          final value = next.value;
          if (value?.isStale == true &&
              !staleRefreshPublished.isCompleted) {
            staleRefreshPublished.complete(value!);
          }
        });
        addTearDown(subscription.close);
        container.read(provider);
        await oldApi.getStarted.future;

        await container.read(currentAccountProvider.notifier).select(
              _account.copyWith(token: 'refreshed-token'),
            );
        container.read(provider);
        await refreshedApi.getFailureObserved.future;
        final staleState = await staleRefreshPublished.future;
        expect(staleState.board.name, 'Revoked cached board');

        oldApi
          ..failGets = true
          ..getFailureStatusCode = statusCode
          ..gate!.complete();
        await oldApi.getFailureObserved.future;
        await cache.conditionalDeleteFinished.future.timeout(
          const Duration(seconds: 2),
        );
        await pumpEventQueue();

        expect(cache.conditionalDeleteResult, isTrue);
        expect(await cache.get(key), isNull);
        expect(container.read(provider).value, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await EnvelopeCache(directory: dir).get(key), isNull);
        container.dispose();

        final offlineContainer = ProviderContainer(
          overrides: [
            apiProvider.overrideWithValue(_FakeApi()..failGets = true),
            currentAccountProvider.overrideWith(_FixedAccount.new),
            envelopeCacheProvider.overrideWithValue(
              EnvelopeCache(directory: dir),
            ),
            boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
          ],
        );
        addTearDown(offlineContainer.dispose);
        final offlineProvider = boardProvider(_boardId);
        final offlineLoadSettled = Completer<AsyncValue<BoardState?>>();
        final offlineSubscription = offlineContainer.listen(
          offlineProvider,
          (previous, next) {
            if (next.hasError && !offlineLoadSettled.isCompleted) {
              offlineLoadSettled.complete(next);
            }
          },
        );
        addTearDown(offlineSubscription.close);
        offlineContainer.read(offlineProvider);
        final reopened = await offlineLoadSettled.future;
        expect(reopened.hasError, isTrue);
        expect(reopened.value, isNull);
        expect(await EnvelopeCache(directory: dir).get(key), isNull);
      },
    );
  }

  test('an old denial waits for the same-account replacement load',
      () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_old_denial_waits_for_replacement',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = '${_account.id}-board-$_boardId';
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    final cache = _GatedEnvelopeCache(directory: dir, gateOnPutCall: 2);
    await cache.put(key, Envelope.parse(cachedJson));
    final snapshotWriteGate = Completer<void>();
    final deleteGate = Completer<void>();
    cache
      ..putGate = snapshotWriteGate
      ..conditionalDeleteGate = deleteGate;
    addTearDown(() {
      if (!snapshotWriteGate.isCompleted) snapshotWriteGate.complete();
      if (!deleteGate.isCompleted) deleteGate.complete();
    });

    final oldApi = _FakeApi()..gate = Completer<void>();
    final refreshedApi = _FakeApi()
      ..gate = Completer<void>()
      ..boardName = 'Replacement Board';
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith(
          (ref) => ref.watch(currentAccountProvider)?.token == _account.token
              ? oldApi
              : refreshedApi,
        ),
        currentAccountProvider.overrideWith(() => _MutableAccount(_account)),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
        boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final replacementPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'Replacement Board' &&
          !replacementPublished.isCompleted) {
        replacementPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);
    await oldApi.getStarted.future;
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Pending old update'},
          }),
        );
    await cache.gatedPutStarted.future;

    await container.read(currentAccountProvider.notifier).select(
          _account.copyWith(token: 'refreshed-token'),
        );
    container.read(provider);
    await pumpEventQueue();
    expect(refreshedApi.getCalls, 0);

    oldApi
      ..failGets = true
      ..getFailureStatusCode = 403
      ..gate!.complete();
    await oldApi.getFailureObserved.future;
    await pumpEventQueue();
    snapshotWriteGate.complete();
    await refreshedApi.getStarted.future.timeout(
      const Duration(seconds: 2),
    );
    await pumpEventQueue();
    final deleteStartedBeforeResponse =
        cache.conditionalDeleteStarted.isCompleted;

    refreshedApi.gate!.complete();
    await replacementPublished.future.timeout(const Duration(seconds: 2));
    deleteGate.complete();
    await cache.conditionalDeleteFinished.future.timeout(
      const Duration(seconds: 2),
    );
    await pumpEventQueue();

    expect(deleteStartedBeforeResponse, isFalse);
    expect(cache.conditionalDeleteResult, isFalse);
    expect(cache.deleteCalls, 0);
    expect(
      BoardState.fromEnvelope((await cache.get(key))!).board.name,
      'Replacement Board',
    );
    expect(container.read(provider).value?.board.name, 'Replacement Board');
  });

  test('an old denial cannot delete after the cache write drain', () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_old_denial_drain',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Cached Board';
    final key = '${_account.id}-board-$_boardId';
    await EnvelopeCache(directory: dir).put(key, Envelope.parse(cachedJson));

    final cache = _GatedEnvelopeCache(directory: dir)
      ..putGate = Completer<void>();
    final oldApi = _FakeApi()..gate = Completer<void>();
    final refreshedApi = _FakeApi()..boardName = 'Replacement Board';
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith(
          (ref) => ref.watch(currentAccountProvider)?.token == _account.token
              ? oldApi
              : refreshedApi,
        ),
        currentAccountProvider.overrideWith(() => _MutableAccount(_account)),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
        boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final replacementPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'Replacement Board' &&
          !replacementPublished.isCompleted) {
        replacementPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);
    await oldApi.getStarted.future;
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Pending old update'},
          }),
        );
    await cache.gatedPutStarted.future;

    oldApi
      ..failGets = true
      ..getFailureStatusCode = 403
      ..gate!.complete();
    await oldApi.getFailureObserved.future;
    await pumpEventQueue();
    await container.read(currentAccountProvider.notifier).select(
          _account.copyWith(token: 'refreshed-token'),
        );
    container.read(provider);
    cache.putGate!.complete();
    await replacementPublished.future;
    await pumpEventQueue();

    expect(cache.deleteCalls, 0);
    expect(
      BoardState.fromEnvelope((await cache.get(key))!).board.name,
      'Replacement Board',
    );
  });

  test('a denied account snapshot is removed after switching accounts',
      () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_denial_account_switch',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cachedJson = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (cachedJson['item'] as Map<String, dynamic>)['name'] = 'Revoked A Board';
    final accountAKey = '${_account.id}-board-$_boardId';
    await EnvelopeCache(directory: dir).put(
      accountAKey,
      Envelope.parse(cachedJson),
    );

    final accountB = Account(
      serverUrl: _account.serverUrl,
      token: 'tok-b',
      userId: 'u2',
      displayName: 'Account B',
    );
    final oldApi = _FakeApi()..gate = Completer<void>();
    final accountBApi = _FakeApi()..boardName = 'Account B Board';
    final cache = _GatedEnvelopeCache(directory: dir);
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith(
          (ref) => ref.watch(currentAccountProvider)?.id == _account.id
              ? oldApi
              : accountBApi,
        ),
        currentAccountProvider.overrideWith(() => _MutableAccount(_account)),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
        boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final accountBPublished = Completer<BoardState>();
    final subscription = container.listen(provider, (previous, next) {
      final value = next.value;
      if (value?.board.name == 'Account B Board' &&
          !accountBPublished.isCompleted) {
        accountBPublished.complete(value!);
      }
    });
    addTearDown(subscription.close);
    container.read(provider);
    await oldApi.getStarted.future;

    await container.read(currentAccountProvider.notifier).select(accountB);
    container.read(provider);
    await accountBPublished.future;
    final accountBKey = '${accountB.id}-board-$_boardId';
    expect(await cache.get(accountBKey), isNotNull);

    oldApi
      ..failGets = true
      ..getFailureStatusCode = 403
      ..gate!.complete();
    await oldApi.getFailureObserved.future;
    await cache.conditionalDeleteFinished.future.timeout(
      const Duration(seconds: 2),
    );

    expect(cache.conditionalDeleteCalls, 1);
    expect(cache.conditionalDeleteResult, isTrue);
    expect(await cache.get(accountAKey), isNull);
    expect(await cache.get(accountBKey), isNotNull);
    expect(container.read(provider).value?.board.name, 'Account B Board');

    container.dispose();
    final offlineApi = _FakeApi()
      ..failGets = true
      ..getFailureStatusCode = 503;
    final coldContainer = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(offlineApi),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        boardProvider.overrideWith2((id) => _LoadingNotifier(id)),
      ],
    );
    addTearDown(coldContainer.dispose);
    final coldProvider = boardProvider(_boardId);
    final reopened = Completer<AsyncValue<BoardState?>>();
    final coldSubscription = coldContainer.listen(coldProvider, (_, next) {
      if ((next.hasError || next.value?.isStale == true) &&
          !reopened.isCompleted) {
        reopened.complete(next);
      }
    });
    addTearDown(coldSubscription.close);
    coldContainer.read(coldProvider);
    final reopenedState = await reopened.future;
    expect(reopenedState.hasError, isTrue);
    expect(reopenedState.value, isNull);
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
    var api = _FakeApi();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith((ref) => api),
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

    final nextApi = _FakeApi()
      ..gate = Completer<void>()
      ..cardName = 'Confirmed realtime change';
    api = nextApi;
    container.invalidate(apiProvider);
    container.read(provider);
    await nextApi.getStarted.future;

    final persistedDuringReload = await cache.get(
      '${_account.id}-board-$_boardId',
    );
    expect(
      BoardState.fromEnvelope(persistedDuringReload!).cards[_cardId]!.name,
      'Confirmed realtime change',
      reason: 'a same-account rebuild must flush the debounced snapshot first',
    );

    nextApi.gate!.complete();
    await container.read(provider.future);
  });

  test('a same-account token refresh preserves a debounced socket change offline',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_epoch');
    addTearDown(() => dir.deleteSync(recursive: true));
    final api = _FakeApi();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        currentAccountProvider.overrideWith(
          () => _MutableAccount(_account),
        ),
        envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Epoch socket change'},
          }),
        );
    api.failGets = true;
    await container.read(currentAccountProvider.notifier).select(
          Account(
            serverUrl: _account.serverUrl,
            token: 'refreshed-token',
            userId: _account.userId,
            displayName: _account.displayName,
          ),
        );
    await container.read(provider.future);
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
    expect(reopened!.cards[_cardId]!.name, 'Epoch socket change');
  });

  test('an epoch preserves a socket change received during a full cache write',
      () async {
    final dir = Directory.systemTemp.createTempSync(
      'board_cache_epoch_during_fetch',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = _GatedEnvelopeCache(directory: dir, gateOnPutCall: 2)
      ..putGate = Completer<void>();
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
        boardProvider.overrideWith2((id) => _RecoveringNotifier(id)),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final notifier = container.read(provider.notifier) as _RecoveringNotifier;
    notifier.triggerRecovery();
    await cache.gatedPutStarted.future;
    notifier.applySocketEvent(
      SocketEvent.parse('cardUpdate', {
        'item': {'id': _cardId, 'name': 'Change during full write'},
      }),
    );
    api.failGets = true;
    container
        .read(accountStateEpochProvider.notifier)
        .invalidate(preserveSameAccountState: true);
    cache.putGate!.complete();
    await container.read(provider.future);
    await pumpEventQueue();
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
    expect(reopened!.cards[_cardId]!.name, 'Change during full write');
  });

  test('a pending full write from another account is never used as cache base',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_isolation');
    addTearDown(() => dir.deleteSync(recursive: true));
    final accountB = Account(
      serverUrl: _account.serverUrl,
      token: 'tok-b',
      userId: 'u2',
      displayName: 'Other',
    );
    final cache = _GatedEnvelopeCache(directory: dir)
      ..putGate = Completer<void>();
    final bSeed = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    bSeed['accountMarker'] = 'b-only-marker';
    await EnvelopeCache(directory: dir).put(
      '${accountB.id}-board-$_boardId',
      Envelope.parse(bSeed),
    );

    final apiA = _FakeApi()..accountMarker = 'a-only-marker';
    final apiB = _FakeApi()..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWith(
          (ref) => ref.watch(currentAccountProvider)?.id == _account.id
              ? apiA
              : apiB,
        ),
        currentAccountProvider.overrideWith(
          () => _MutableAccount(_account),
        ),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    container.read(provider);
    await cache.gatedPutStarted.future;

    await container.read(currentAccountProvider.notifier).select(accountB);
    container.read(provider);
    await apiB.getStarted.future;
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'B confirmed change'},
          }),
        );

    apiB.failGets = true;
    await container.read(currentAccountProvider.notifier).select(
          accountB.copyWith(token: 'refreshed-token'),
        );
    cache.putGate!.complete();
    apiB.gate!.complete();
    await container.read(provider.future);
    await pumpEventQueue();

    final cachedA = await cache.get('${_account.id}-board-$_boardId');
    final cachedB = await cache.get('${accountB.id}-board-$_boardId');
    expect(cachedA!.raw['accountMarker'], 'a-only-marker');
    expect(cachedB!.raw['accountMarker'], 'b-only-marker');
    expect(
      BoardState.fromEnvelope(cachedB).cards[_cardId]!.name,
      'B confirmed change',
    );
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

  test('switching accounts and logging out discard pending snapshots',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_switch');
    addTearDown(() => dir.deleteSync(recursive: true));
    final accountB = Account(
      serverUrl: 'https://other.example.com',
      token: 'tok-b',
      userId: 'u2',
      displayName: 'Other',
    );
    final cache = EnvelopeCache(directory: dir);
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()),
        currentAccountProvider.overrideWith(
          () => _MutableAccount(_account),
        ),
        envelopeCacheProvider.overrideWithValue(cache),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Pending before account switch'},
          }),
        );

    await container.read(currentAccountProvider.notifier).select(accountB);
    await container.read(provider.future);
    final cachedA = await cache.get('${_account.id}-board-$_boardId');
    expect(
      BoardState.fromEnvelope(cachedA!).cards[_cardId]!.name,
      'Fixture card',
    );

    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Pending before logout'},
          }),
        );
    await container.read(currentAccountProvider.notifier).select(null);
    await pumpEventQueue();

    final cachedB = await cache.get('${accountB.id}-board-$_boardId');
    expect(
      BoardState.fromEnvelope(cachedB!).cards[_cardId]!.name,
      'Fixture card',
    );
  });

  test('account removal purges the board while its debounce timer is armed',
      () async {
    final dir = Directory.systemTemp.createTempSync('board_cache_remove');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lifecycle = AccountCacheLifecycle();
    final cache = EnvelopeCache(directory: dir, lifecycle: lifecycle);
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(_FakeApi()),
        currentAccountProvider.overrideWith(_FixedAccount.new),
        envelopeCacheProvider.overrideWithValue(cache),
        cacheLifecycleProvider.overrideWithValue(lifecycle),
        boardSocketFactoryProvider.overrideWithValue(_NoopSocket.new),
        userSocketProvider.overrideWithValue(null),
        userEventsProvider.overrideWithValue(const Stream.empty()),
        userConnectedProvider.overrideWithValue(const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final provider = boardProvider(_boardId);
    await container.read(provider.future);
    container.read(provider.notifier).applySocketEvent(
          SocketEvent.parse('cardUpdate', {
            'item': {'id': _cardId, 'name': 'Pending before removal'},
          }),
        );

    await lifecycle.beginRemoval(_account.id);
    container.read(accountStateEpochProvider.notifier).invalidate();
    await cache.purgeAccount(_account.id);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final coldCache = EnvelopeCache(directory: dir);
    expect(
      await coldCache.get('${_account.id}-board-$_boardId'),
      isNull,
    );
  });
}
