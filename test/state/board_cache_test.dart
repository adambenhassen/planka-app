import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/envelope_cache.dart';

const _boardId = '1844338624586318868';

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
  final getStarted = Completer<void>();
  bool failGets = false;
  var boardName = 'Fresh Board';

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    if (!getStarted.isCompleted) getStarted.complete();
    final pending = gate;
    if (pending != null) await pending.future;
    if (failGets) throw ApiException(503, 'server unavailable');
    final json = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    (json['item'] as Map<String, dynamic>)['name'] = boardName;
    return Envelope.parse(json);
  }
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
}
