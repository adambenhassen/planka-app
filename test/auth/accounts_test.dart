import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart' as file;
import 'package:file/memory.dart' as file_memory;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
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

void main() {
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
