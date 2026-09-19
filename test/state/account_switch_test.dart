import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart' as file;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/envelope_cache.dart';
import 'package:planka_app/state/notifications_state.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/state/user_socket.dart';

/// Returns projects tagged by server, so each account yields a distinct list.
class _FakeApi extends PlankaApi {
  _FakeApi(super.serverUrl, super.token);

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'items': [
          {'id': 'p@$serverUrl', 'name': 'Project @ $serverUrl'}
        ]
      });
}

class _BoardApi extends PlankaApi {
  _BoardApi(super.serverUrl, super.token, {this.gate});

  final Completer<void>? gate;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final pending = gate;
    if (pending != null) await pending.future;
    if (path == '/notifications') {
      return Envelope.parse({
        'items': [
          {
            'id': 'n@$serverUrl',
            'userId': 'u1',
            'type': 'commentCard',
            'isRead': false,
          }
        ]
      });
    }
    final fixture = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final item = (fixture['item'] as Map).cast<String, dynamic>();
    item['name'] = serverUrl;
    return Envelope.parse(fixture);
  }
}

class _RecordingSocket extends PlankaSocket {
  _RecordingSocket(super.serverUrl, super.token);

  var disposed = false;

  @override
  Stream<SocketEvent> get events => const Stream.empty();

  @override
  Stream<bool> get connected => const Stream.empty();

  @override
  bool get isConnected => !disposed;

  @override
  Future<void> connect() async {}

  @override
  Future<void> subscribeBoard(String boardId) async {}

  @override
  void dispose() => disposed = true;
}

class _MemStore implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class _DeterministicCacheManager implements BaseCacheManager {
  @override
  Future<file.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => throw UnimplementedError();

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => const Stream.empty();

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream.empty();

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) => throw UnimplementedError();

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => null;

  @override
  Future<FileInfo?> getFileFromMemory(String key) async => null;

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => throw UnimplementedError();

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => throw UnimplementedError();

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  Account account(String server) => Account(
      serverUrl: server, token: 'tok', userId: 'u1', displayName: 'User');

  test('switching the current account reloads projects for that account',
      () async {
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(_MemStore())),
      apiProvider.overrideWith((ref) {
        final acc = ref.watch(currentAccountProvider)!;
        return _FakeApi(acc.serverUrl, acc.token);
      }),
    ]);
    addTearDown(container.dispose);

    await container
        .read(currentAccountProvider.notifier)
        .select(account('http://a'));
    final first = await container.read(projectsProvider.future);
    expect(first.projects.map((p) => p.name), ['Project @ http://a']);

    await container
        .read(currentAccountProvider.notifier)
        .select(account('http://b'));
    final second = await container.read(projectsProvider.future);
    expect(second.projects.map((p) => p.name), ['Project @ http://b']);
  });

  test('account selection waits for outgoing decoded media eviction',
      () async {
    final accountA = account('http://a');
    final accountB = account('http://b');
    final evictionStarted = Completer<void>();
    final releaseEviction = Completer<void>();
    final store = _MemStore();
    final images = AccountImageCacheManager(
      createManager: (_) => _DeterministicCacheManager(),
      evictImageKey: (_) async {
        if (!evictionStarted.isCompleted) evictionStarted.complete();
        await releaseEviction.future;
      },
    );
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(store)),
      imageCacheProvider.overrideWithValue(images),
    ]);
    addTearDown(container.dispose);
    addTearDown(() async {
      if (!releaseEviction.isCompleted) releaseEviction.complete();
      await images.dispose();
    });

    await container.read(currentAccountProvider.notifier).select(accountA);
    final imageA = Object();
    images.forAccount(accountA.id);
    images.trackImageKey(accountA.id, imageA);

    final selection =
        container.read(currentAccountProvider.notifier).select(accountB);
    await evictionStarted.future;

    expect(container.read(currentAccountProvider), same(accountA));
    expect(await store.read('currentAccountId'), accountA.id);

    releaseEviction.complete();
    await selection;
    expect(container.read(currentAccountProvider), same(accountB));
    expect(await store.read('currentAccountId'), accountB.id);
  });

  test('failed outgoing media eviction leaves selection unchanged', () async {
    final accountA = account('http://a');
    final accountB = account('http://b');
    final store = _MemStore();
    final images = AccountImageCacheManager(
      createManager: (_) => _DeterministicCacheManager(),
      evictImageKey: (_) async => throw StateError('decoded eviction failed'),
    );
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(store)),
      imageCacheProvider.overrideWithValue(images),
    ]);
    addTearDown(container.dispose);
    addTearDown(() async {
      await images.dispose();
    });

    await container.read(currentAccountProvider.notifier).select(accountA);
    images.forAccount(accountA.id);
    images.trackImageKey(accountA.id, Object());

    await expectLater(
      container.read(currentAccountProvider.notifier).select(accountB),
      throwsStateError,
    );
    expect(container.read(currentAccountProvider), same(accountA));
    expect(await store.read('currentAccountId'), accountA.id);
  });

  test('serializes concurrent account transitions before each publish',
      () async {
    final accountA = account('http://a');
    final accountB = account('http://b');
    final accountC = account('http://c');
    final evictionAStarted = Completer<void>();
    final evictionBStarted = Completer<void>();
    final evictionCStarted = Completer<void>();
    final releaseA = Completer<void>();
    final releaseB = Completer<void>();
    final releaseC = Completer<void>();
    final imageA = Object();
    final imageB = Object();
    final imageC = Object();
    final store = _MemStore();
    final images = AccountImageCacheManager(
      createManager: (_) => _DeterministicCacheManager(),
      evictImageKey: (key) async {
        if (identical(key, imageA)) {
          evictionAStarted.complete();
          await releaseA.future;
        } else if (identical(key, imageB)) {
          evictionBStarted.complete();
          await releaseB.future;
        } else if (identical(key, imageC)) {
          evictionCStarted.complete();
          await releaseC.future;
        }
      },
    );
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(store)),
      imageCacheProvider.overrideWithValue(images),
    ]);
    addTearDown(container.dispose);
    addTearDown(() async {
      if (!releaseA.isCompleted) releaseA.complete();
      if (!releaseB.isCompleted) releaseB.complete();
      if (!releaseC.isCompleted) releaseC.complete();
      await images.dispose();
    });

    await container.read(currentAccountProvider.notifier).select(accountA);
    for (final entry in [
      (accountA, imageA),
      (accountB, imageB),
      (accountC, imageC),
    ]) {
      images.forAccount(entry.$1.id);
      images.trackImageKey(entry.$1.id, entry.$2);
    }

    final toB =
        container.read(currentAccountProvider.notifier).select(accountB);
    await evictionAStarted.future;
    final toC =
        container.read(currentAccountProvider.notifier).select(accountC);
    final signedOut = container
        .read(currentAccountProvider.notifier)
        .select(null);
    await pumpEventQueue();

    expect(container.read(currentAccountProvider), same(accountA));
    expect(await store.read('currentAccountId'), accountA.id);
    expect(evictionBStarted.isCompleted, isFalse);
    expect(evictionCStarted.isCompleted, isFalse);

    releaseA.complete();
    await evictionBStarted.future;
    expect(container.read(currentAccountProvider), same(accountB));
    expect(await store.read('currentAccountId'), accountB.id);
    expect(evictionCStarted.isCompleted, isFalse);

    releaseB.complete();
    await evictionCStarted.future;
    expect(container.read(currentAccountProvider), same(accountC));
    expect(await store.read('currentAccountId'), accountC.id);

    releaseC.complete();
    await Future.wait([toB, toC, signedOut]);
    expect(container.read(currentAccountProvider), isNull);
    expect(await store.read('currentAccountId'), isNull);
  });

  test('switching accounts hides same-board state before the new load',
      () async {
    final accountA = account('http://a');
    final accountB = account('http://b');
    final bGate = Completer<void>();
    final sockets = <_RecordingSocket>[];
    final notificationSockets = <_RecordingSocket>[];
    final userSockets = <_RecordingSocket>[];
    final cacheDir = await Directory.systemTemp.createTemp('board_switch');
    final evictedImages = <Object>[];
    final images = AccountImageCacheManager(
      directory: cacheDir,
      createManager: (_) => _DeterministicCacheManager(),
      evictImageKey: (key) async => evictedImages.add(key),
    );
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(_MemStore())),
      apiProvider.overrideWith((ref) {
        final active = ref.watch(currentAccountProvider)!;
        return _BoardApi(
          active.serverUrl,
          active.token,
          gate: active.id == accountB.id ? bGate : null,
        );
      }),
      envelopeCacheProvider.overrideWithValue(
        EnvelopeCache(directory: cacheDir),
      ),
      imageCacheProvider.overrideWithValue(images),
      userEventsProvider.overrideWithValue(const Stream.empty()),
      userConnectedProvider.overrideWithValue(const Stream.empty()),
      userSocketFactoryProvider.overrideWithValue((serverUrl, token) {
        final socket = _RecordingSocket(serverUrl, token);
        userSockets.add(socket);
        return socket;
      }),
      boardSocketFactoryProvider.overrideWithValue((serverUrl, token) {
        final socket = _RecordingSocket(serverUrl, token);
        sockets.add(socket);
        return socket;
      }),
      notificationsSocketFactoryProvider
          .overrideWithValue((serverUrl, token) {
        final socket = _RecordingSocket(serverUrl, token);
        notificationSockets.add(socket);
        return socket;
      }),
    ]);
    addTearDown(container.dispose);
    addTearDown(() async {
      await images.dispose();
      await cacheDir.delete(recursive: true);
    });

    final boardId = 'b1';
    await container.read(currentAccountProvider.notifier).select(accountA);
    final userSocketA = container.read(userSocketProvider);
    expect(userSocketA?.serverUrl, 'http://a');
    final boardSubscription =
        container.listen(boardProvider(boardId), (_, _) {});
    addTearDown(boardSubscription.close);
    await container.read(boardProvider(boardId).future);
    expect(container.read(boardProvider(boardId)).value?.board.name, 'http://a');
    final notificationSubscription =
        container.listen(notificationsProvider, (_, _) {});
    addTearDown(notificationSubscription.close);
    await container.read(notificationsProvider.future);
    expect(container.read(notificationsProvider).value?.single.id,
        'n@http://a');
    final imageA = Object();
    images.forAccount(accountA.id);
    images.trackImageKey(accountA.id, imageA);

    await container.read(currentAccountProvider.notifier).select(accountB);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).isLoading, isTrue);
    expect(container.read(boardProvider(boardId)).value, isNull);
    expect(container.read(notificationsProvider).value, anyOf(isNull, isEmpty));

    final loading = container.read(boardProvider(boardId).future);
    final notificationLoading = container.read(notificationsProvider.future);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).isLoading, isTrue);
    expect(container.read(boardProvider(boardId)).value, isNull);
    expect(container.read(notificationsProvider).value, anyOf(isNull, isEmpty));
    bGate.complete();
    await Future.wait([loading, notificationLoading]);
    expect(container.read(boardProvider(boardId)).value?.board.name, 'http://b');
    expect(container.read(notificationsProvider).value?.single.id,
        'n@http://b');
    expect(sockets, hasLength(2));
    expect(sockets[0].disposed, isTrue);
    expect(sockets[1].serverUrl, 'http://b');
    expect(notificationSockets, hasLength(2));
    expect(notificationSockets[0].disposed, isTrue);
    expect(notificationSockets[1].serverUrl, 'http://b');
    expect(evictedImages, [same(imageA)]);
    final userSocketB = container.read(userSocketProvider);
    expect(userSocketB?.serverUrl, 'http://b');
    expect(userSockets, hasLength(2));
    expect(userSockets[0].disposed, isTrue);

    await container.read(currentAccountProvider.notifier).select(null);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).hasError, isTrue);
    expect(container.read(boardProvider(boardId)).value, isNull);
    expect(sockets[1].disposed, isTrue);
    expect(container.read(notificationsProvider).value, anyOf(isNull, isEmpty));
    expect(notificationSockets[1].disposed, isTrue);
    expect(userSockets[1].disposed, isTrue);
    final imageB = Object();
    images.trackImageKey(accountB.id, imageB);
    // A logout is a transition too: do not leave decoded B media available to
    // a later reauthentication with the same account id.
    await container.read(currentAccountProvider.notifier).select(accountB);
    images.trackImageKey(accountB.id, imageB);
    await container.read(currentAccountProvider.notifier).select(null);
    expect(evictedImages, contains(same(imageB)));
  });

  test('signed-out projects and users rebuild to empty without an API',
      () async {
    final accountA = account('http://a');
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(AccountStore(_MemStore())),
        apiProvider.overrideWith((ref) {
          final active = ref.watch(currentAccountProvider);
          if (active == null) throw StateError('API used while signed out');
          return _FakeApi(active.serverUrl, active.token);
        }),
        userSocketProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await container.read(currentAccountProvider.notifier).select(accountA);
    await container.read(projectsProvider.future);
    await container.read(allUsersProvider.future);

    await container.read(currentAccountProvider.notifier).select(null);
    await container.read(projectsProvider.future);
    await container.read(allUsersProvider.future);

    expect(container.read(projectsProvider).hasError, isFalse);
    expect(container.read(projectsProvider).value?.projects, isEmpty);
    expect(container.read(allUsersProvider).hasError, isFalse);
    expect(container.read(allUsersProvider).value, isEmpty);
  });
}
