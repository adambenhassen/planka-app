import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart' as file;
import 'package:file/memory.dart' as file_memory;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/auth/account_removal.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/cache_lifecycle.dart';
import 'package:planka_app/cache_purge.dart';
import 'package:planka_app/state/envelope_cache.dart';

class FakeStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class _FailingStorage extends FakeStorage {
  var failNextWrite = false;

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('durable account save failed');
    }
    await super.write(key, value);
  }
}

class _PauseAfterRemovalLifecycle extends AccountCacheLifecycle {
  final reachedBarrier = Completer<void>();
  final releaseBarrier = Completer<void>();

  @override
  Future<void> beginRemoval(String accountId) async {
    await super.beginRemoval(accountId);
    reachedBarrier.complete();
    await releaseBarrier.future;
  }
}

class _DelayedStorage extends FakeStorage {
  @override
  Future<String?> read(String key) =>
      Future<String?>.delayed(Duration.zero, () => data[key]);

  @override
  Future<void> write(String key, String value) =>
      Future<void>.delayed(Duration.zero, () => data[key] = value);
}

class _ConcurrentAccountStorage extends FakeStorage {
  var coordinateAccountWrites = false;
  var accountWriteCount = 0;
  final firstWriteStarted = Completer<void>();
  final secondWriteStarted = Completer<void>();
  final allowFirstWrite = Completer<void>();
  final allowSecondWrite = Completer<void>();

  @override
  Future<void> write(String key, String value) async {
    if (!coordinateAccountWrites || key != 'accounts') {
      await super.write(key, value);
      return;
    }
    accountWriteCount++;
    if (accountWriteCount == 1) {
      firstWriteStarted.complete();
      await allowFirstWrite.future;
    } else if (accountWriteCount == 2) {
      secondWriteStarted.complete();
      await allowSecondWrite.future;
    }
    await super.write(key, value);
  }
}

class _RecordingEnvelopeCache extends EnvelopeCache {
  _RecordingEnvelopeCache({bool shouldFail = false, int? failuresRemaining})
    : failuresRemaining = failuresRemaining ?? (shouldFail ? 1 : 0);

  int failuresRemaining;
  final purgedAccountIds = <String>[];

  @override
  Future<void> purgeAccount(String accountId) async {
    purgedAccountIds.add(accountId);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('secret-access-token');
    }
  }
}

class _FailOnceEnvelopeCache extends EnvelopeCache {
  _FailOnceEnvelopeCache({
    required Directory directory,
    required super.lifecycle,
  }) : super(directory: directory);

  var failNextPurge = true;

  @override
  Future<void> purgeAccount(String accountId) async {
    if (failNextPurge) {
      failNextPurge = false;
      throw StateError('metadata purge failed');
    }
    await super.purgeAccount(accountId);
  }
}

class _MemoryMediaCache implements BaseCacheManager {
  final _files = file_memory.MemoryFileSystem();

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
  }) async {
    final result = _files.file('/${key ?? url}');
    await result.parent.create(recursive: true);
    await result.writeAsBytes(fileBytes);
    return result;
  }

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async => putFile(
    url,
    Uint8List.fromList(await source.expand((chunk) => chunk).toList()),
    key: key,
    eTag: eTag,
    maxAge: maxAge,
    fileExtension: fileExtension,
  );

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

class _RecordingImageCache extends AccountImageCacheManager {
  _RecordingImageCache({this.failuresRemaining = 0, super.lifecycle})
    : super(createManager: (_) => _MemoryMediaCache());

  int failuresRemaining;
  final purgedAccountIds = <String>[];

  @override
  Future<void> purgeAccount(String accountId) async {
    purgedAccountIds.add(accountId);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('secret-access-token');
    }
  }
}

class _LogoutApi extends PlankaApi {
  _LogoutApi(super.serverUrl, super.token);

  @override
  Future<void> logout() async {}
}

void main() {
  test('account removal clears the selected account after local cleanup',
      () async {
    final accountA = Account(
      serverUrl: 'https://selected-removal.example',
      token: 'selected-removal-a-token',
      userId: 'a',
      displayName: 'A',
    );
    final accountB = Account(
      serverUrl: 'https://selected-removal.example',
      token: 'selected-removal-b-token',
      userId: 'b',
      displayName: 'B',
    );
    final storage = FakeStorage();
    final store = AccountStore(storage);
    await store.save([accountA, accountB]);
    final lifecycle = AccountCacheLifecycle();
    final images = _RecordingImageCache(lifecycle: lifecycle);
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        envelopeCacheProvider.overrideWithValue(_RecordingEnvelopeCache()),
        imageCacheProvider.overrideWithValue(images),
        cacheLifecycleProvider.overrideWithValue(lifecycle),
        accountApiFactoryProvider.overrideWithValue(
          (account) => _LogoutApi(account.serverUrl, account.token),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(images.dispose);

    await container.read(accountsProvider.future);
    await container.read(currentAccountProvider.notifier).select(accountA);
    final epochBefore = container.read(accountStateEpochProvider);

    final result = await container.read(accountRemovalProvider).remove(accountA);

    expect(result.status, AccountRemovalStatus.removed);
    expect(container.read(currentAccountProvider), isNull);
    expect(container.read(accountStateEpochProvider), epochBefore + 1);
    expect(
      container.read(accountsProvider).value?.map((account) => account.id),
      [accountB.id],
    );
    expect(images.purgedAccountIds, [accountA.id]);
  });

  test('a 401 logs out the selected account and evicts decoded media',
      () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((request) {
      request.response.statusCode = 401;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"message":"server secret"}');
      request.response.close();
    });
    addTearDown(() => server.close());

    final account = Account(
      serverUrl: 'http://127.0.0.1:${server.port}',
      token: 'expired-token',
      userId: 'u1',
      displayName: 'Expired',
    );
    final storage = FakeStorage();
    final store = AccountStore(storage);
    await store.save([account]);
    final lifecycle = AccountCacheLifecycle();
    final evicted = <Object>[];
    final images = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => _MemoryMediaCache(),
      evictImageKey: (key) async => evicted.add(key),
    );
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(store),
      imageCacheProvider.overrideWithValue(images),
    ]);
    addTearDown(container.dispose);
    addTearDown(images.dispose);

    await container.read(currentAccountProvider.notifier).select(account);
    final imageKey = Object();
    images.forAccount(account.id);
    images.trackImageKey(account.id, imageKey);
    final epoch = container.read(accountStateEpochProvider);

    await expectLater(
      container.read(apiProvider).get('/protected'),
      throwsA(isA<ApiException>()),
    );
    await pumpEventQueue();

    expect(container.read(currentAccountProvider), isNull);
    expect(container.read(authExpiredProvider)?.id, account.id);
    expect(container.read(accountStateEpochProvider), epoch + 1);
    expect(evicted, [same(imageKey)]);
  });

  test('Account json round-trip', () {
    final a = Account(
      serverUrl: 'https://p.example.com',
      token: 'jwt',
      userId: 'u1',
      displayName: 'Demo',
    );
    expect(a.id, 'https://p.example.com#u1');
    final b = Account.fromJson(
      jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
    );
    expect(b.id, a.id);
    expect(b.token, 'jwt');
    expect(b.displayName, 'Demo');
  });

  test('AccountStore save/load', () async {
    final store = AccountStore(FakeStorage());
    final a = Account(
      serverUrl: 'https://x',
      token: 't',
      userId: 'u',
      displayName: 'D',
    );
    await store.save([a]);
    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, a.id);
  });

  test('AccountStore load empty', () async {
    expect(await AccountStore(FakeStorage()).load(), isEmpty);
  });

  test('failed removal-intent persistence leaves the account open', () async {
    final storage = _FailingStorage();
    final store = AccountStore(storage);
    final account = Account(
      serverUrl: 'https://intent-failure.example',
      token: 'intent-failure-token',
      userId: 'u1',
      displayName: 'Intent failure',
    );
    await store.save([account]);
    final lifecycle = AccountCacheLifecycle();
    final envelopes = _RecordingEnvelopeCache();
    final images = _RecordingImageCache(lifecycle: lifecycle);
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        envelopeCacheProvider.overrideWithValue(envelopes),
        imageCacheProvider.overrideWithValue(images),
        cacheLifecycleProvider.overrideWithValue(lifecycle),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(images.dispose);

    await container.read(accountsProvider.future);
    storage.failNextWrite = true;
    await expectLater(
      container.read(accountsProvider.notifier).remove(account.id),
      throwsA(isA<CachePurgeException>()),
    );

    expect(envelopes.purgedAccountIds, isEmpty);
    expect(images.purgedAccountIds, isEmpty);
    expect((await store.load()).single.id, account.id);
    expect(await store.loadRemovalFailures(), isEmpty);
    expect(images.forAccount(account.id), isNotNull);
  });

  test(
    'durable removal intent closes a reconstructed lifecycle before purge',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final accountA = Account(
        serverUrl: 'https://intent-restart.example',
        token: 'intent-restart-a-token',
        userId: 'a',
        displayName: 'A',
      );
      final accountB = Account(
        serverUrl: 'https://intent-restart.example',
        token: 'intent-restart-b-token',
        userId: 'b',
        displayName: 'B',
      );
      await store.save([accountA, accountB]);

      final lifecycle = _PauseAfterRemovalLifecycle();
      final firstEnvelopes = _RecordingEnvelopeCache(shouldFail: true);
      final firstImages = _RecordingImageCache(lifecycle: lifecycle);
      final firstContainer = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(firstEnvelopes),
          imageCacheProvider.overrideWithValue(firstImages),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(firstContainer.dispose);
      addTearDown(firstImages.dispose);
      await firstContainer.read(accountsProvider.future);

      final removal = firstContainer
          .read(accountsProvider.notifier)
          .remove(accountA.id);
      await lifecycle.reachedBarrier.future;
      expect(await store.loadRemovalFailures(), contains(accountA.id));

      final reconstructedLifecycle = AccountCacheLifecycle();
      final reconstructedImages = _RecordingImageCache(
        lifecycle: reconstructedLifecycle,
      );
      final reconstructedContainer = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(_RecordingEnvelopeCache()),
          imageCacheProvider.overrideWithValue(reconstructedImages),
          cacheLifecycleProvider.overrideWithValue(reconstructedLifecycle),
        ],
      );
      addTearDown(reconstructedContainer.dispose);
      addTearDown(reconstructedImages.dispose);
      await reconstructedContainer.read(accountsProvider.future);
      expect(
        () => reconstructedImages.forAccount(accountA.id),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(reconstructedImages.forAccount(accountB.id), isNotNull);

      lifecycle.releaseBarrier.complete();
      await expectLater(removal, throwsA(isA<CachePurgeException>()));
    },
  );

  test(
    'concurrent removal-intent updates retain both account tombstones',
    () async {
      final storage = _DelayedStorage();
      final store = AccountStore(storage);

      final first = store.markRemovalFailed('https://concurrent.example#a');
      final second = store.markRemovalFailed('https://concurrent.example#b');
      await Future.wait([first, second]);

      expect(await store.loadRemovalFailures(), {
        'https://concurrent.example#a',
        'https://concurrent.example#b',
      });
    },
  );

  test('concurrent failed removals retain both accounts closed', () async {
    final storage = _DelayedStorage();
    final store = AccountStore(storage);
    final accountA = Account(
      serverUrl: 'https://concurrent-removal.example',
      token: 'concurrent-removal-a-token',
      userId: 'a',
      displayName: 'A',
    );
    final accountB = Account(
      serverUrl: 'https://concurrent-removal.example',
      token: 'concurrent-removal-b-token',
      userId: 'b',
      displayName: 'B',
    );
    await store.save([accountA, accountB]);
    final lifecycle = AccountCacheLifecycle();
    final envelopes = _RecordingEnvelopeCache(failuresRemaining: 2);
    final images = _RecordingImageCache(
      failuresRemaining: 2,
      lifecycle: lifecycle,
    );
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        envelopeCacheProvider.overrideWithValue(envelopes),
        imageCacheProvider.overrideWithValue(images),
        cacheLifecycleProvider.overrideWithValue(lifecycle),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(images.dispose);
    await container.read(accountsProvider.future);

    Future<void> expectFailure(Future<void> removal) async {
      await expectLater(removal, throwsA(isA<CachePurgeException>()));
    }

    final notifier = container.read(accountsProvider.notifier);
    await Future.wait([
      expectFailure(notifier.remove(accountA.id)),
      expectFailure(notifier.remove(accountB.id)),
    ]);

    expect(await store.loadRemovalFailures(), {accountA.id, accountB.id});
    expect((await store.load()).map((account) => account.id), {
      accountA.id,
      accountB.id,
    });
    expect(envelopes.purgedAccountIds, containsAll([accountA.id, accountB.id]));
    expect(images.purgedAccountIds, containsAll([accountA.id, accountB.id]));
    expect(
      () => images.forAccount(accountA.id),
      throwsA(isA<AccountCacheClosedException>()),
    );
    expect(
      () => images.forAccount(accountB.id),
      throwsA(isA<AccountCacheClosedException>()),
    );
  });

  test(
    'concurrent successful removals cannot resurrect either account',
    () async {
      final storage = _ConcurrentAccountStorage();
      final store = AccountStore(storage);
      final accountA = Account(
        serverUrl: 'https://concurrent-success.example',
        token: 'concurrent-success-a-token',
        userId: 'a',
        displayName: 'A',
      );
      final accountB = Account(
        serverUrl: 'https://concurrent-success.example',
        token: 'concurrent-success-b-token',
        userId: 'b',
        displayName: 'B',
      );
      await store.save([accountA, accountB]);
      storage.coordinateAccountWrites = true;

      final lifecycle = AccountCacheLifecycle();
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(_RecordingEnvelopeCache()),
          imageCacheProvider.overrideWithValue(
            _RecordingImageCache(lifecycle: lifecycle),
          ),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountsProvider.future);
      final notifier = container.read(accountsProvider.notifier);
      final first = notifier.remove(accountA.id);
      await storage.firstWriteStarted.future;
      final second = notifier.remove(accountB.id);

      var writesRaced = true;
      try {
        await storage.secondWriteStarted.future.timeout(
          const Duration(milliseconds: 100),
        );
      } on TimeoutException {
        writesRaced = false;
      }

      if (writesRaced) {
        // Without serialized account mutations, both removals save snapshots
        // based on [accountA, accountB]. Let the second write land first so the
        // first stale snapshot deterministically resurrects one account.
        storage.allowSecondWrite.complete();
        storage.allowFirstWrite.complete();
      } else {
        // A serialized implementation has only the first snapshot in flight.
        // Release it, then let the second removal observe the updated list.
        storage.allowFirstWrite.complete();
        await first;
        await storage.secondWriteStarted.future;
        storage.allowSecondWrite.complete();
      }

      await Future.wait([first, second]);
      expect(await store.load(), isEmpty);
    },
  );

  for (final record in ['missing', 'corrupt']) {
    test(
      '$record account records still restore durable removal closure before registration',
      () async {
        const accountId = 'https://missing-record.example#user';
        final storage = FakeStorage();
        storage.data['accountRemovalFailures'] = jsonEncode([accountId]);
        if (record == 'corrupt') storage.data['accounts'] = '{not-json';
        final store = AccountStore(storage);
        final lifecycle = AccountCacheLifecycle();
        final container = ProviderContainer(
          overrides: [
            accountStoreProvider.overrideWithValue(store),
            cacheLifecycleProvider.overrideWithValue(lifecycle),
          ],
        );
        final images = AccountImageCacheManager(
          lifecycle: lifecycle,
          createManager: (_) => _MemoryMediaCache(),
        );
        addTearDown(container.dispose);
        addTearDown(images.dispose);

        expect(await container.read(accountsProvider.future), isEmpty);
        expect(
          () => images.forAccount(accountId),
          throwsA(isA<AccountCacheClosedException>()),
        );
      },
    );
  }

  test('removing an account purges both caches before deleting it', () async {
    final storage = FakeStorage();
    final store = AccountStore(storage);
    final account = Account(
      serverUrl: 'https://p.example.com',
      token: 'secret-access-token',
      userId: 'u1',
      displayName: 'Demo',
    );
    await store.save([account]);
    final envelopes = _RecordingEnvelopeCache();
    final images = _RecordingImageCache();
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        envelopeCacheProvider.overrideWithValue(envelopes),
        imageCacheProvider.overrideWithValue(images),
      ],
    );
    addTearDown(container.dispose);

    await container.read(accountsProvider.future);
    await container.read(accountsProvider.notifier).remove(account.id);

    expect(envelopes.purgedAccountIds, [account.id]);
    expect(images.purgedAccountIds, [account.id]);
    expect(await store.load(), isEmpty);
  });

  test(
    'removal reports purge failure without leaking the token or deleting the account',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://p.example.com',
        token: 'secret-access-token',
        userId: 'u1',
        displayName: 'Demo',
      );
      await store.save([account]);
      final envelopes = _RecordingEnvelopeCache(shouldFail: true);
      final images = _RecordingImageCache();
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(envelopes),
          imageCacheProvider.overrideWithValue(images),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountsProvider.future);
      Object? error;
      try {
        await container.read(accountsProvider.notifier).remove(account.id);
        fail('expected account removal to fail');
      } catch (e) {
        error = e;
      }

      expect(error, isA<CachePurgeException>());
      expect('$error', isNot(contains(account.token)));
      expect(
        (error as CachePurgeException).cause,
        isNot(contains(account.token)),
      );
      expect(envelopes.purgedAccountIds, [account.id]);
      expect(images.purgedAccountIds, [account.id]);
      expect((await store.load()).single.id, account.id);
    },
  );

  test(
    'independent purge failures retain the account and retry idempotently',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://retry.example',
        token: 'retry-secret-token',
        userId: 'u1',
        displayName: 'Retry',
      );
      await store.save([account]);
      final envelopes = _RecordingEnvelopeCache(failuresRemaining: 1);
      final images = _RecordingImageCache(failuresRemaining: 1);
      final lifecycle = AccountCacheLifecycle();
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(envelopes),
          imageCacheProvider.overrideWithValue(images),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountsProvider.future);
      await expectLater(
        container.read(accountsProvider.notifier).remove(account.id),
        throwsA(isA<CachePurgeException>()),
      );
      expect(envelopes.purgedAccountIds, [account.id]);
      expect(images.purgedAccountIds, [account.id]);
      expect((await store.load()).single.id, account.id);

      await container.read(accountsProvider.notifier).remove(account.id);
      expect(envelopes.purgedAccountIds, [account.id, account.id]);
      expect(images.purgedAccountIds, [account.id, account.id]);
      expect(await store.load(), isEmpty);
    },
  );

  test(
    'pre-removal handles stay closed after successful reauthentication',
    () async {
      final storage = _FailingStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://reauth.example',
        token: 'reauth-old-token',
        userId: 'u1',
        displayName: 'Reauth',
      );
      await store.save([account]);
      final lifecycle = AccountCacheLifecycle();
      final images = _RecordingImageCache(lifecycle: lifecycle);
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(_RecordingEnvelopeCache()),
          imageCacheProvider.overrideWithValue(images),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(container.dispose);

      final oldHandle = images.forAccount(account.id);
      await container.read(accountsProvider.future);
      await container.read(accountsProvider.notifier).remove(account.id);
      await container
          .read(accountsProvider.notifier)
          .upsert(account.copyWith(token: 'reauth-new-token'));

      await expectLater(
        oldHandle.putFile(
          'https://reauth.example/media/old.png',
          Uint8List.fromList('old'.codeUnits),
          key: 'old-handle',
        ),
        throwsA(isA<AccountCacheClosedException>()),
      );
    },
  );

  test(
    'pre-removal handles stay closed when durable reauthentication save fails',
    () async {
      final storage = _FailingStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://failed-reauth.example',
        token: 'failed-reauth-old-token',
        userId: 'u1',
        displayName: 'Failed reauth',
      );
      await store.save([account]);
      final lifecycle = AccountCacheLifecycle();
      final images = _RecordingImageCache(lifecycle: lifecycle);
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(_RecordingEnvelopeCache()),
          imageCacheProvider.overrideWithValue(images),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(container.dispose);

      final oldHandle = images.forAccount(account.id);
      await container.read(accountsProvider.future);
      await container.read(accountsProvider.notifier).remove(account.id);
      storage.failNextWrite = true;
      await expectLater(
        container
            .read(accountsProvider.notifier)
            .upsert(account.copyWith(token: 'failed-reauth-new-token')),
        throwsA(isA<StateError>()),
      );

      await expectLater(
        oldHandle.putFile(
          'https://failed-reauth.example/media/old.png',
          Uint8List.fromList('old'.codeUnits),
          key: 'old-handle',
        ),
        throwsA(isA<AccountCacheClosedException>()),
      );
    },
  );

  test(
    'failed removal stays closed across reconstruction until a real retry purges storage',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final accountA = Account(
        serverUrl: 'https://durable-removal.example',
        token: 'durable-a-token',
        userId: 'a',
        displayName: 'A',
      );
      final accountB = Account(
        serverUrl: 'https://durable-removal.example',
        token: 'durable-b-token',
        userId: 'b',
        displayName: 'B',
      );
      await store.save([accountA, accountB]);

      final root = await Directory.systemTemp.createTemp('durable_removal');
      addTearDown(() => root.delete(recursive: true));
      final seedLifecycle = AccountCacheLifecycle();
      final seedEnvelopes = EnvelopeCache(
        directory: root,
        lifecycle: seedLifecycle,
      );
      final envelopeKeyA = '${accountA.id}-projects';
      final envelopeKeyB = '${accountB.id}-projects';
      await seedEnvelopes.put(
        envelopeKeyA,
        Envelope.parse({
          'item': {'id': 'a', 'value': 'A'},
        }),
      );
      await seedEnvelopes.put(
        envelopeKeyB,
        Envelope.parse({
          'item': {'id': 'b', 'value': 'B'},
        }),
      );
      final legacyA =
          File(
              '${root.path}/envelope_cache/${base64Url.encode(utf8.encode(envelopeKeyA))}.json',
            )
            ..createSync(recursive: true)
            ..writeAsStringSync(
              jsonEncode({
                'item': {'id': 'a', 'value': 'legacy-A'},
              }),
            );

      final imageUrl = 'https://durable-removal.example/media/shared.png';
      final imageKeyA = plankaImageCacheKey(accountA.id, imageUrl);
      final imageKeyB = plankaImageCacheKey(accountB.id, imageUrl);
      final seedImages = AccountImageCacheManager(
        directory: root,
        lifecycle: seedLifecycle,
      );
      await seedImages
          .forAccount(accountA.id)
          .putFile(imageUrl, Uint8List.fromList('A'.codeUnits), key: imageKeyA);
      await seedImages
          .forAccount(accountB.id)
          .putFile(imageUrl, Uint8List.fromList('B'.codeUnits), key: imageKeyB);
      await seedImages.dispose();

      final firstLifecycle = AccountCacheLifecycle();
      final firstEnvelopes = _FailOnceEnvelopeCache(
        directory: root,
        lifecycle: firstLifecycle,
      );
      final firstImages = AccountImageCacheManager(
        directory: root,
        lifecycle: firstLifecycle,
      );
      final firstContainer = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(firstEnvelopes),
          imageCacheProvider.overrideWithValue(firstImages),
          cacheLifecycleProvider.overrideWithValue(firstLifecycle),
        ],
      );
      await firstContainer.read(accountsProvider.future);
      await expectLater(
        firstContainer.read(accountsProvider.notifier).remove(accountA.id),
        throwsA(isA<CachePurgeException>()),
      );
      expect(
        (await store.load()).map((account) => account.id),
        contains(accountA.id),
      );
      expect(await store.loadRemovalFailures(), contains(accountA.id));
      expect(
        () => firstImages.forAccount(accountA.id),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        (await firstImages
                .forAccount(accountB.id)
                .getFileFromCache(imageKeyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        completion('B'),
      );
      await firstImages.dispose();
      firstContainer.dispose();

      final secondLifecycle = AccountCacheLifecycle();
      final secondEnvelopes = EnvelopeCache(
        directory: root,
        lifecycle: secondLifecycle,
      );
      final secondImages = AccountImageCacheManager(
        directory: root,
        lifecycle: secondLifecycle,
      );
      final secondContainer = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(secondEnvelopes),
          imageCacheProvider.overrideWithValue(secondImages),
          cacheLifecycleProvider.overrideWithValue(secondLifecycle),
        ],
      );
      await secondContainer.read(accountsProvider.future);
      expect(await store.loadRemovalFailures(), contains(accountA.id));
      await expectLater(
        secondContainer
            .read(accountsProvider.notifier)
            .upsert(accountA.copyWith(token: 'reauth-after-failure-token')),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(await store.loadRemovalFailures(), contains(accountA.id));
      expect(
        secondEnvelopes.get(envelopeKeyA),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        secondEnvelopes.put(
          envelopeKeyA,
          Envelope.parse({
            'item': {'id': 'a', 'value': 'new'},
          }),
        ),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        () => secondImages.forAccount(accountA.id),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect((await secondEnvelopes.get(envelopeKeyB))!.raw, {
        'item': {'id': 'b', 'value': 'B'},
      });
      expect(
        (await secondImages
                .forAccount(accountB.id)
                .getFileFromCache(imageKeyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        completion('B'),
      );

      await secondContainer.read(accountsProvider.notifier).remove(accountA.id);
      expect(await store.load(), hasLength(1));
      expect((await store.load()).single.id, accountB.id);
      expect(await store.loadRemovalFailures(), isEmpty);
      expect(
        secondEnvelopes.get(envelopeKeyA),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        () => secondImages.forAccount(accountA.id),
        throwsA(isA<AccountCacheClosedException>()),
      );

      final coldEnvelopes = EnvelopeCache(directory: root);
      expect(await coldEnvelopes.get(envelopeKeyA), isNull);
      expect((await coldEnvelopes.get(envelopeKeyB))!.raw, {
        'item': {'id': 'b', 'value': 'B'},
      });
      final coldImages = AccountImageCacheManager(directory: root);
      expect(
        await coldImages
            .forAccount(accountA.id)
            .getFileFromCache(imageKeyA, ignoreMemCache: true),
        isNull,
      );
      expect(
        (await coldImages
                .forAccount(accountB.id)
                .getFileFromCache(imageKeyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        completion('B'),
      );
      await coldImages.dispose();
      await secondImages.dispose();
      secondContainer.dispose();
      expect(await legacyA.exists(), isFalse);
    },
  );

  test('FileKeyValueStore read/write/delete round-trip', () async {
    final dir = await Directory.systemTemp.createTemp('planka_fkv');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = FileKeyValueStore(Directory('${dir.path}/store'));
    expect(await store.read('accounts'), isNull);
    await store.write('accounts', '[{"x":1}]');
    expect(await store.read('accounts'), '[{"x":1}]');
    await store.delete('accounts');
    expect(await store.read('accounts'), isNull);
  });

  test('login returns jwt and sets header', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"item":"jwt-abc"}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', null);
    expect(await api.login('demo@demo.demo', 'demo'), 'jwt-abc');
    await server.close();
  });

  test('non-2xx throws ApiException with statusCode', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"code":"E_UNAUTHORIZED","message":"nope"}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', 'bad');
    await expectLater(
      api.get('/users/me'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
    await server.close();
  });

  test('bearer header sent when token set', () async {
    String? seenAuth;
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      seenAuth = req.headers.value('authorization');
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"item":{"id":"1"}}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', 'tok');
    await api.get('/users/me');
    expect(seenAuth, 'Bearer tok');
    await server.close();
  });
}
