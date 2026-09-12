import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file/file.dart' as file;
import 'package:file/memory.dart' as file_memory;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/cache_lifecycle.dart';
import 'package:planka_app/cache_purge.dart';

class _ControlledMediaCache implements BaseCacheManager {
  _ControlledMediaCache({
    this.writeGate,
    this.failureMessage,
    this.responseStream,
  });

  final Completer<void>? writeGate;
  final String? failureMessage;
  final Stream<FileResponse>? responseStream;
  final entries = <String, Uint8List>{};
  final memory = file_memory.MemoryFileSystem();
  var writes = 0;
  var emptyCalls = 0;
  var disposeCalls = 0;

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
  }) => responseStream ?? const Stream.empty();

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
  }) async {
    final bytes = entries[key];
    if (bytes == null) return null;
    final result = memory.file('/$key')..writeAsBytesSync(bytes);
    return FileInfo(
      result,
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 1)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) => getFileFromCache(key);

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final gate = writeGate;
    if (gate != null) await gate.future;
    final failure = failureMessage;
    if (failure != null) throw StateError(failure);
    final cacheKey = key ?? url;
    writes++;
    entries[cacheKey] = Uint8List.fromList(fileBytes);
    final result = memory.file('/$cacheKey');
    result.writeAsBytesSync(fileBytes);
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
  }) async {
    final bytes = await source.fold<List<int>>([], (all, chunk) {
      all.addAll(chunk);
      return all;
    });
    return putFile(
      url,
      Uint8List.fromList(bytes),
      key: key,
      eTag: eTag,
      maxAge: maxAge,
      fileExtension: fileExtension,
    );
  }

  @override
  Future<void> removeFile(String key) async => entries.remove(key);

  @override
  Future<void> emptyCache() async {
    emptyCalls++;
    entries.clear();
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class _RepositoryFailure {
  var failNextUpdate = false;
}

class _FailingCacheInfoRepository extends CacheInfoRepository {
  _FailingCacheInfoRepository(this._delegate, this._failure);

  final CacheInfoRepository _delegate;
  final _RepositoryFailure _failure;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  Future<bool> open() => _delegate.open();

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject) {
    if (_failure.failNextUpdate) {
      _failure.failNextUpdate = false;
      return Future<dynamic>.error(StateError('metadata write failed'));
    }
    return _delegate.updateOrInsert(cacheObject);
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) => _delegate.insert(cacheObject, setTouchedToNow: setTouchedToNow);

  @override
  Future<CacheObject?> get(String key) => _delegate.get(key);

  @override
  Future<int> delete(int id) => _delegate.delete(id);

  @override
  Future<int> deleteAll(Iterable<int> ids) => _delegate.deleteAll(ids);

  @override
  Future<int> update(CacheObject cacheObject, {bool setTouchedToNow = true}) =>
      _delegate.update(cacheObject, setTouchedToNow: setTouchedToNow);

  @override
  Future<List<CacheObject>> getAllObjects() => _delegate.getAllObjects();

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) =>
      _delegate.getObjectsOverCapacity(capacity);

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) =>
      _delegate.getOldObjects(maxAge);

  @override
  Future<bool> close() => _delegate.close();

  @override
  Future<void> deleteDataFile() => _delegate.deleteDataFile();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final productionRoot = Directory.systemTemp.createTempSync(
    'media_production',
  );
  tearDownAll(() => productionRoot.delete(recursive: true));

  const accountA = 'https://planka.example#user';
  const accountB = 'https://planka.example#user2';
  const imageUrl = 'https://planka.example/media/shared.png';

  test(
    'same media URL is stored separately and survives another purge',
    () async {
      final directory = await Directory.systemTemp.createTemp('media_cache');
      addTearDown(() => directory.delete(recursive: true));
      final cache = AccountImageCacheManager(directory: directory);
      final managerA = cache.forAccount(accountA);
      final managerB = cache.forAccount(accountB);
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);

      expect(managerA, isNot(same(managerB)));
      expect(keyA, isNot(keyB));
      expect(keyA, isNot(contains('access-token')));

      await managerA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      await managerB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );
      expect(
        await managerA.getFileFromCache(keyA, ignoreMemCache: true),
        isNotNull,
      );
      expect(
        await managerB.getFileFromCache(keyB, ignoreMemCache: true),
        isNotNull,
      );
      await cache.dispose();

      final purge = AccountImageCacheManager(directory: directory);
      await purge.purgeAccount(accountA);

      final reconstructed = AccountImageCacheManager(directory: directory);
      final reconstructedA = reconstructed.forAccount(accountA);
      final reconstructedB = reconstructed.forAccount(accountB);
      expect(await reconstructedA.getFileFromCache(keyA), isNull);
      expect(
        await (await reconstructedB.getFileFromCache(
          keyB,
        ))!.file.readAsString(),
        'B',
      );

      await reconstructed.dispose();
    },
  );

  test(
    'purge closes old media handles and leaves another account unchanged',
    () async {
      const accountA = 'https://planka.example#user';
      const accountB = 'https://planka.example#user2';
      const imageUrl = 'https://planka.example/media/shared.png';
      final lifecycle = AccountCacheLifecycle();
      final gate = Completer<void>();
      final cacheA = _ControlledMediaCache(writeGate: gate);
      final cacheB = _ControlledMediaCache();
      final cache = AccountImageCacheManager(
        lifecycle: lifecycle,
        createManager: (accountId) => accountId == accountA ? cacheA : cacheB,
      );
      final handleA = cache.forAccount(accountA);
      final handleB = cache.forAccount(accountB);
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);

      await handleB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );
      final pending = handleA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      final purge = cache.purgeAccount(accountA);

      expect(
        () => cache.forAccount(accountA),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        handleA.getFileFromCache(keyA),
        throwsA(isA<AccountCacheClosedException>()),
      );

      gate.complete();
      await expectLater(pending, throwsA(isA<AccountCacheClosedException>()));
      await purge;

      expect(cacheA.entries, isEmpty);
      expect(
        (await handleB.getFileFromCache(keyB))!.file.readAsString(),
        completion('B'),
      );
    },
  );

  test('media failures are redacted at the cache boundary', () async {
    const account = 'https://planka.example#user';
    const token = 'secret-access-token';
    final cache = AccountImageCacheManager(
      createManager: (_) => _ControlledMediaCache(failureMessage: token),
    );
    final handle = cache.forAccount(account);

    Object? error;
    try {
      await handle.putFile(
        'https://planka.example/media/image.png?token=$token',
        Uint8List.fromList('A'.codeUnits),
        key: plankaImageCacheKey(
          account,
          'https://planka.example/media/image.png',
        ),
      );
      fail('expected media cache failure');
    } catch (e) {
      error = e;
    }

    expect('$error', isNot(contains(token)));
  });

  test(
    'token canaries do not enter media cache metadata or payloads',
    () async {
      const account = 'https://planka.example#canary';
      const token = 'media-secret-token-canary';
      const url = 'https://planka.example/media/image.png?token=$token';
      final directory = await Directory.systemTemp.createTemp('media_canary');
      addTearDown(() => directory.delete(recursive: true));
      final cache = AccountImageCacheManager(directory: directory);
      final manager = cache.forAccount(account, token: token);
      final key = plankaImageCacheKey(account, url);

      await manager.putFile(
        url,
        Uint8List.fromList(token.codeUnits),
        key: key,
        eTag: token,
        fileExtension: token,
      );
      await manager.getFileFromCache(key, ignoreMemCache: true);

      final encoded = base64Url.encode(utf8.encode(token));
      await for (final entry in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is! File) continue;
        final contents = await entry.readAsBytes();
        final text = utf8.decode(contents, allowMalformed: true);
        expect(text, isNot(contains(token)));
        expect(text, isNot(contains(encoded)));
        expect(entry.path, isNot(contains(token)));
        expect(entry.path, isNot(contains(encoded)));
      }
      await cache.dispose();
    },
  );

  test('stream writes redact credentials split across chunks', () async {
    const account = 'https://planka.example#stream-canary';
    const token = 'stream-secret-token-canary';
    final backend = _ControlledMediaCache();
    final cache = AccountImageCacheManager(createManager: (_) => backend);
    final manager = cache.forAccount(account, token: token);
    final split = token.length ~/ 2;

    await manager.putFileStream(
      'https://planka.example/media/stream.png',
      Stream.fromIterable([
        token.substring(0, split).codeUnits,
        token.substring(split).codeUnits,
      ]),
      key: plankaImageCacheKey(
        account,
        'https://planka.example/media/stream.png',
      ),
    );

    expect(backend.entries.values.single, isNot(containsAll(token.codeUnits)));
    expect(utf8.decode(backend.entries.values.single), isNot(contains(token)));
  });

  test('removal cancels a never-ending media response', () async {
    const account = 'https://planka.example#never-ending';
    final source = StreamController<FileResponse>();
    var cancelled = false;
    source.onCancel = () {
      cancelled = true;
    };
    final backend = _ControlledMediaCache(responseStream: source.stream);
    final cache = AccountImageCacheManager(
      lifecycle: AccountCacheLifecycle(),
      createManager: (_) => backend,
    );
    final handle = cache.forAccount(account);
    final subscription = handle
        .getFileStream('https://planka.example/media/hanging.png')
        .listen((_) {});
    addTearDown(() async {
      await subscription.cancel();
      await source.close();
    });

    final removal = cache.purgeAccount(account);
    await removal.timeout(const Duration(milliseconds: 250));

    expect(cancelled, isTrue);
  });

  test(
    'removal reports bounded media cancellation failure and can retry',
    () async {
      const account = 'https://planka.example#bounded-cancel';
      final source = StreamController<FileResponse>();
      final cancellation = Completer<void>();
      source.onCancel = () => cancellation.future;
      final cache = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
        createManager: (_) =>
            _ControlledMediaCache(responseStream: source.stream),
      );
      final handle = cache.forAccount(account);
      final subscription = handle
          .getFileStream('https://planka.example/media/bounded.png')
          .listen((_) {}, onError: (_) {});
      addTearDown(() async {
        if (!cancellation.isCompleted) cancellation.complete();
        await subscription.cancel();
        await source.close();
      });

      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      expect(
        () => cache.forAccount(account),
        throwsA(isA<AccountCacheClosedException>()),
      );

      cancellation.complete();
      await subscription.cancel();
      await cache.purgeAccount(account);
    },
  );

  test('production media storage purge finds an unindexed orphan', () async {
    const account = 'https://production.example#orphan-canary';
    final namespace = 'planka-images-${sha256.convert(utf8.encode(account))}';
    final directory = Directory(p.join(productionRoot.path, namespace));
    final orphan = File(p.join(directory.path, 'orphan.file'));
    await orphan.create(recursive: true);
    await orphan.writeAsString('orphan');
    await Directory(
      p.join(productionRoot.path, 'metadata'),
    ).create(recursive: true);
    addTearDown(() => directory.delete(recursive: true));
    CacheInfoRepository createRepository(String namespace) =>
        JsonCacheInfoRepository.withFile(
          File(p.join(productionRoot.path, 'metadata', '$namespace.json')),
        );

    final cache = AccountImageCacheManager(
      temporaryDirectory: () async => productionRoot,
      createRepository: createRepository,
    );
    await cache.purgeAccount(account);
    expect(await orphan.exists(), isFalse);

    final cold = AccountImageCacheManager(
      temporaryDirectory: () async => productionRoot,
      createRepository: createRepository,
    );
    final handle = cold.forAccount(account);
    expect(
      await handle.getFileFromCache(
        plankaImageCacheKey(account, 'https://production.example/media/orphan'),
        ignoreMemCache: true,
      ),
      isNull,
    );
    await cold.dispose();
  });

  test(
    'production media storage retries after a metadata failure and removes the orphan',
    () async {
      const account = 'https://production.example#metadata-failure';
      const imageUrl = 'https://production.example/media/orphan.png';
      final root = await Directory.systemTemp.createTemp('media_metadata');
      addTearDown(() => root.delete(recursive: true));
      final metadata = Directory(p.join(root.path, 'metadata'));
      await metadata.create(recursive: true);
      final failure = _RepositoryFailure()..failNextUpdate = true;
      CacheInfoRepository createRepository(String namespace) =>
          _FailingCacheInfoRepository(
            JsonCacheInfoRepository.withFile(
              File(p.join(metadata.path, '$namespace.json')),
            ),
            failure,
          );
      final cache = AccountImageCacheManager(
        temporaryDirectory: () async => root,
        createRepository: createRepository,
      );
      final handle = cache.forAccount(account);
      final key = plankaImageCacheKey(account, imageUrl);

      await expectLater(
        handle.putFile(
          imageUrl,
          Uint8List.fromList('orphan'.codeUnits),
          key: key,
        ),
        throwsA(isA<CacheOperationException>()),
      );
      final namespace = 'planka-images-${sha256.convert(utf8.encode(account))}';
      final files = Directory(p.join(root.path, namespace))
          .list(recursive: true, followLinks: false)
          .where((entry) => entry is File);
      expect(await files.toList(), isNotEmpty);

      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      expect(
        await Directory(p.join(root.path, namespace))
            .list(recursive: true, followLinks: false)
            .where((entry) => entry is File)
            .toList(),
        isEmpty,
      );

      await cache.purgeAccount(account);
      final cold = AccountImageCacheManager(
        temporaryDirectory: () async => root,
        createRepository: createRepository,
      );
      expect(
        await cold
            .forAccount(account)
            .getFileFromCache(key, ignoreMemCache: true),
        isNull,
      );
      await cold.dispose();
    },
  );
}
