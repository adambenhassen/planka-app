import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart' as file;
import 'package:file/memory.dart' as file_memory;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/cache_lifecycle.dart';

class _ControlledMediaCache implements BaseCacheManager {
  _ControlledMediaCache({this.writeGate, this.failureMessage});

  final Completer<void>? writeGate;
  final String? failureMessage;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    final cache = AccountImageCacheManager(
      createManager: (_) => backend,
    );
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

    expect(
      backend.entries.values.single,
      isNot(containsAll(token.codeUnits)),
    );
    expect(
      utf8.decode(backend.entries.values.single),
      isNot(contains(token)),
    );
  });
}
