import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file/file.dart' as file;
import 'package:file/file.dart' as fs;
import 'package:file/local.dart' as local;
import 'package:file/memory.dart' as file_memory;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/painting.dart';
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

class _GatedMemoryImage extends MemoryImage {
  const _GatedMemoryImage(super.bytes, this.gate);

  final _ImageKeyGate gate;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) async {
    if (gate.enabled) {
      if (!gate.started.isCompleted) gate.started.complete();
      await gate.release.future;
    }
    return this;
  }
}

class _ImageKeyGate {
  final started = Completer<void>();
  final release = Completer<void>();
  var enabled = false;
}

class _PendingImageStreamCompleter extends ImageStreamCompleter {}

class _RecordingFileService extends FileService {
  String? url;
  Map<String, String>? headers;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    this.url = url;
    this.headers = headers;
    return _TestFileServiceResponse();
  }
}

class _TestFileServiceResponse implements FileServiceResponse {
  @override
  Stream<List<int>> get content => Stream.value('media'.codeUnits);

  @override
  int? get contentLength => 5;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => 'file';
}

class _StatusFileService extends FileService {
  _StatusFileService(this.statusCode);

  final int statusCode;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async => _StatusFileServiceResponse(statusCode);
}

class _StatusFileServiceResponse implements FileServiceResponse {
  _StatusFileServiceResponse(this.statusCode);

  @override
  final int statusCode;

  @override
  Stream<List<int>> get content =>
      throw StateError('Unexpected response body access');

  @override
  int? get contentLength => 0;

  @override
  DateTime get validTill => DateTime.now();

  @override
  String? get eTag => null;

  @override
  String get fileExtension => 'file';
}

class _DelayedStatusFileService extends FileService {
  _DelayedStatusFileService(this.statusCode);

  final int statusCode;
  String? url;
  Map<String, String>? headers;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    this.url = url;
    this.headers = headers;
    started.complete();
    await release.future;
    return _StatusFileServiceResponse(statusCode);
  }
}

class _DelayedFileService extends FileService {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    started.complete();
    await release.future;
    return _DelayedFileServiceResponse();
  }
}

class _DelayedFileServiceResponse implements FileServiceResponse {
  @override
  Stream<List<int>> get content => Stream.value('late'.codeUnits);

  @override
  int? get contentLength => 4;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => 'file';
}

class _RecordingLifecycle extends AccountCacheLifecycle {
  _RecordingLifecycle({super.removalTimeout});

  final generationRejected = Completer<void>();

  @override
  AccountCacheLease acquire(String accountId, {int? generation}) {
    try {
      return super.acquire(accountId, generation: generation);
    } catch (error) {
      if (generation != null) generationRejected.complete();
      rethrow;
    }
  }
}

class _FilePhase {
  final started = Completer<void>();
  final release = Completer<void>();

  Future<void> pause() {
    if (!started.isCompleted) started.complete();
    return release.future;
  }
}

class _FilesystemPhases {
  final open = _FilePhase();
  final write = _FilePhase();
  final stream = _FilePhase();
  final flush = _FilePhase();
  final close = _FilePhase();
  final closeFinished = Completer<void>();
}

class _PhasedFileSystem extends file.ForwardingFileSystem {
  _PhasedFileSystem(this.phases) : super(local.LocalFileSystem());

  final _FilesystemPhases phases;
  var armed = false;

  bool isMediaPath(String path) => path.contains('planka-images-');

  fs.File wrapFile(io.File delegate) => _PhasedFile(this, delegate);

  fs.Directory wrapDirectory(io.Directory delegate) =>
      _PhasedDirectory(this, delegate);

  @override
  fs.File file(dynamic path) => wrapFile(io.File(super.file(path).path));

  @override
  fs.Directory directory(dynamic path) =>
      wrapDirectory(io.Directory(super.directory(path).path));
}

class _PhasedDirectory
    extends fs.ForwardingFileSystemEntity<fs.Directory, io.Directory>
    with fs.ForwardingDirectory<fs.Directory> {
  _PhasedDirectory(this._fileSystem, this._delegate);

  final _PhasedFileSystem _fileSystem;
  final io.Directory _delegate;

  @override
  fs.FileSystem get fileSystem => _fileSystem;

  @override
  io.Directory get delegate => _delegate;

  @override
  _PhasedDirectory wrap(io.Directory delegate) =>
      _fileSystem.wrapDirectory(delegate) as _PhasedDirectory;

  @override
  fs.Directory wrapDirectory(io.Directory delegate) =>
      _fileSystem.wrapDirectory(delegate);

  @override
  fs.File wrapFile(io.File delegate) => _fileSystem.wrapFile(delegate);

  @override
  fs.Link wrapLink(io.Link delegate) => _fileSystem.link(delegate.path);

  @override
  fs.Directory childDirectory(String basename) =>
      _fileSystem.directory(p.join(path, basename));

  @override
  fs.File childFile(String basename) =>
      _fileSystem.file(p.join(path, basename));

  @override
  fs.Link childLink(String basename) =>
      _fileSystem.link(p.join(path, basename));
}

class _PhasedFile extends file.ForwardingFileSystemEntity<file.File, io.File>
    with file.ForwardingFile {
  _PhasedFile(this._fileSystem, this._delegate);

  final _PhasedFileSystem _fileSystem;
  final io.File _delegate;

  @override
  file.FileSystem get fileSystem => _fileSystem;

  @override
  io.File get delegate => _delegate;

  @override
  _PhasedFile wrap(io.File delegate) =>
      _fileSystem.wrapFile(delegate) as _PhasedFile;

  @override
  file.File wrapFile(io.File delegate) => _fileSystem.wrapFile(delegate);

  @override
  file.Directory wrapDirectory(io.Directory delegate) =>
      _fileSystem.wrapDirectory(delegate);

  @override
  file.Link wrapLink(io.Link delegate) => _fileSystem.link(delegate.path);

  @override
  Future<file.File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) async {
    if (_fileSystem.armed && _fileSystem.isMediaPath(path)) {
      await _fileSystem.phases.write.pause();
    }
    return wrap(await delegate.writeAsBytes(bytes, mode: mode, flush: flush));
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
  }) {
    final sink = delegate.openWrite(mode: mode, encoding: encoding);
    if (!_fileSystem.armed || !_fileSystem.isMediaPath(path)) return sink;
    return io.IOSink(
      _PhasedSinkConsumer(sink, _fileSystem.phases),
      encoding: encoding,
    );
  }
}

class _PhasedSinkConsumer implements StreamConsumer<List<int>> {
  _PhasedSinkConsumer(this._delegate, this._phases);

  final io.IOSink _delegate;
  final _FilesystemPhases _phases;
  var _opened = false;

  Future<void> _waitForOpen() async {
    if (_opened) return;
    _opened = true;
    await _phases.open.pause();
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await _waitForOpen();
    await _phases.stream.pause();
    await _phases.flush.pause();
    await _delegate.addStream(stream);
  }

  @override
  Future<void> close() async {
    await _waitForOpen();
    await _phases.close.pause();
    try {
      await _delegate.close();
    } finally {
      if (!_phases.closeFinished.isCompleted) {
        _phases.closeFinished.complete();
      }
    }
  }
}

class _RepositoryFailure {
  var failNextUpdate = false;
  Completer<void>? updateGate;
  Completer<void>? updateStarted;
  final updateGates = <String, Completer<void>>{};
  final updateStartedByKey = <String, Completer<void>>{};
  final updateGatesByKey = <String, List<Completer<void>>>{};
  final updateStartedByCall = <String, Map<int, Completer<void>>>{};
  final updateCounts = <String, int>{};
  final failKeys = <String>{};
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
  Future<dynamic> updateOrInsert(CacheObject cacheObject) async {
    final call = (_failure.updateCounts[cacheObject.key] ?? 0) + 1;
    _failure.updateCounts[cacheObject.key] = call;
    final queuedGates = _failure.updateGatesByKey[cacheObject.key];
    final gate = queuedGates != null && queuedGates.isNotEmpty
        ? queuedGates.removeAt(0)
        : _failure.updateGates[cacheObject.key] ?? _failure.updateGate;
    if (gate != null) {
      _failure.updateStarted?.complete();
      _failure.updateStartedByKey[cacheObject.key]?.complete();
      _failure.updateStartedByCall[cacheObject.key]?[call]?.complete();
      await gate.future;
    }
    if (_failure.failNextUpdate || _failure.failKeys.remove(cacheObject.key)) {
      _failure.failNextUpdate = false;
      throw StateError('metadata write failed');
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
  test('purging an account evicts its tracked decoded image keys', () async {
    final lifecycle = AccountCacheLifecycle();
    final cache = _ControlledMediaCache();
    final evicted = <Object>[];
    final manager = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => cache,
      evictImageKey: (key) async => evicted.add(key),
    );
    const accountId = 'https://media.example#u1';
    final key = Object();

    manager.forAccount(accountId);
    manager.trackImageKey(accountId, key);
    await manager.purgeAccount(accountId);

    expect(evicted, [same(key)]);
  });

  test('leaving an account evicts decoded media without deleting its files',
      () async {
    final lifecycle = AccountCacheLifecycle();
    final cache = _ControlledMediaCache();
    final evicted = <Object>[];
    final manager = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => cache,
      evictImageKey: (key) async => evicted.add(key),
    );
    const accountId = 'https://media.example#switch-user';
    final key = Object();

    manager.forAccount(accountId);
    manager.trackImageKey(accountId, key);
    await manager.evictDecodedAccount(accountId);
    manager.trackImageKey(accountId, Object());
    await pumpEventQueue();

    expect(evicted, hasLength(2));
    expect(() => manager.forAccount(accountId), returnsNormally);
  });

  test('a failed decoded eviction fails closed and remains retryable',
      () async {
    var attempts = 0;
    final lifecycle = AccountCacheLifecycle();
    final cache = _ControlledMediaCache();
    final manager = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => cache,
      evictImageKey: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('decoded secret');
      },
    );
    const accountId = 'https://media.example#retry';
    manager.forAccount(accountId);
    manager.trackImageKey(accountId, Object());

    await expectLater(
      manager.evictDecodedAccount(accountId),
      throwsStateError,
    );
    expect(attempts, 1);

    await manager.evictDecodedAccount(accountId);
    expect(attempts, 2);
  });

  testWidgets(
    'default decoded eviction awaits and clears Flutter image cache',
    (tester) async {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
      addTearDown(() {
        imageCache.clear();
        imageCache.clearLiveImages();
      });
      final gate = _ImageKeyGate();
      addTearDown(() {
        if (!gate.release.isCompleted) gate.release.complete();
      });
      final provider = _GatedMemoryImage(Uint8List(0), gate);
      imageCache.putIfAbsent(
        provider,
        _PendingImageStreamCompleter.new,
      );
      expect(imageCache.containsKey(provider), isTrue);

      const accountId = 'https://media.example#flutter-cache';
      final manager = AccountImageCacheManager();
      addTearDown(manager.dispose);
      manager.trackImageKey(accountId, provider);
      gate.enabled = true;
      var completed = false;
      final eviction = manager.evictDecodedAccount(accountId).then((_) {
        completed = true;
      });
      await tester.pump();

      expect(gate.started.isCompleted, isTrue);
      expect(completed, isFalse);
      expect(imageCache.containsKey(provider), isTrue);

      gate.release.complete();
      await eviction;

      expect(completed, isTrue);
      expect(imageCache.containsKey(provider), isFalse);
    },
  );

  test('a failed late decoded eviction remains retryable', () async {
    var attempts = 0;
    var failuresRemaining = 1;
    final lifecycle = AccountCacheLifecycle();
    final cache = _ControlledMediaCache();
    final manager = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => cache,
      evictImageKey: (_) async {
        attempts++;
        if (failuresRemaining > 0) {
          failuresRemaining--;
          throw StateError('decoded secret');
        }
      },
    );
    const accountId = 'https://media.example#late-retry';
    manager.forAccount(accountId);
    await manager.evictDecodedAccount(accountId);
    manager.trackImageKey(accountId, Object());
    await pumpEventQueue();
    expect(attempts, 1);

    await manager.evictDecodedAccount(accountId);
    expect(attempts, 2);
  });

  test('a late key is retained when it fails during an eviction pass',
      () async {
    final firstKey = Object();
    final lateKey = Object();
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    var attempts = 0;
    final lifecycle = AccountCacheLifecycle();
    final cache = _ControlledMediaCache();
    final manager = AccountImageCacheManager(
      lifecycle: lifecycle,
      createManager: (_) => cache,
      evictImageKey: (key) async {
        attempts++;
        if (identical(key, firstKey)) {
          firstStarted.complete();
          await releaseFirst.future;
        } else if (identical(key, lateKey)) {
          throw StateError('decoded secret');
        }
      },
    );
    const accountId = 'https://media.example#late-during-pass';
    manager.forAccount(accountId);
    manager.trackImageKey(accountId, firstKey);

    final eviction = manager.evictDecodedAccount(accountId);
    await firstStarted.future;
    manager.trackImageKey(accountId, lateKey);
    await pumpEventQueue();
    releaseFirst.complete();
    await eviction;
    expect(attempts, 2);

    await expectLater(
      manager.evictDecodedAccount(accountId),
      throwsStateError,
    );
    expect(attempts, 3);
  });

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

  test(
    'account media requests preserve query while cache storage stays safe',
    () async {
      const account = 'https://planka.example#query-account';
      const token = 'account-query-token-canary';
      final directory = await Directory.systemTemp.createTemp('media_query');
      final service = _RecordingFileService();
      final cache = AccountImageCacheManager(
        directory: directory,
        fileService: service,
      );
      var disposed = false;
      addTearDown(() async {
        if (!disposed) await cache.dispose();
        await directory.delete(recursive: true);
      });
      final url =
          'https://planka.example/attachments/a1.png?token=$token&size=large';
      final handle = cache.forAccount(account, token: token);

      final result = await handle.getSingleFile(
        url,
        headers: {'Cookie': 'accessToken=$token'},
      );

      expect(await result.readAsString(), 'media');
      expect(service.url, url);
      expect(service.headers, {'Cookie': 'accessToken=$token'});

      final legacyUrl =
          'https://planka.example/covers/c1.png?token=$token&variant=legacy';
      // ignore: deprecated_member_use
      final legacyStream = handle.getFile(
        legacyUrl,
        headers: {'Cookie': 'accessToken=$token'},
      );
      await legacyStream.drain<void>();
      expect(service.url, legacyUrl);
      expect(service.headers, {'Cookie': 'accessToken=$token'});
      await cache.dispose();
      disposed = true;
      await for (final entry in directory.list(recursive: true)) {
        if (entry is! File) continue;
        final contents = await entry.readAsString();
        expect(contents, isNot(contains(token)));
        expect(entry.path, isNot(contains(token)));
      }
    },
  );

  test(
    'no-key media identities distinguish sanitized query variants',
    () async {
      const account = 'https://planka.example#query-identity';
      const token = 'query-identity-token-canary';
      const base = 'https://planka.example/media/variant.png';
      final backend = _ControlledMediaCache();
      final cache = AccountImageCacheManager(createManager: (_) => backend);
      addTearDown(cache.dispose);
      final handle = cache.forAccount(account, token: token);

      await handle.putFile(
        '$base?token=$token&size=small',
        Uint8List.fromList('small'.codeUnits),
      );
      await handle.putFile(
        '$base?token=$token&size=large',
        Uint8List.fromList('large'.codeUnits),
      );

      expect(backend.entries, hasLength(2));
      expect(backend.entries.keys, everyElement(isNot(contains(token))));
      expect(
        backend.entries.values.map(utf8.decode),
        containsAll(<String>['small', 'large']),
      );
    },
  );

  test(
    'delayed pre-removal transport cannot write into a reauthenticated generation',
    () async {
      const account = 'https://planka.example#delayed-reauth';
      const imageUrl = 'https://planka.example/media/delayed.png';
      final root = await Directory.systemTemp.createTemp(
        'media_delayed_reauth',
      );
      addTearDown(() => root.delete(recursive: true));
      final metadata = Directory(p.join(root.path, 'metadata'));
      await metadata.create(recursive: true);
      final service = _DelayedFileService();
      final failure = _RepositoryFailure()..updateStarted = Completer<void>();
      CacheInfoRepository createRepository(String namespace) =>
          _FailingCacheInfoRepository(
            JsonCacheInfoRepository.withFile(
              File(p.join(metadata.path, '$namespace.json')),
            ),
            failure,
          );
      final lifecycle = _RecordingLifecycle(
        removalTimeout: const Duration(milliseconds: 20),
      );
      final cache = AccountImageCacheManager(
        lifecycle: lifecycle,
        temporaryDirectory: () async => root,
        createRepository: createRepository,
        fileService: service,
      );
      addTearDown(cache.dispose);
      final key = plankaImageCacheKey(account, imageUrl);
      final handle = cache.forAccount(account);
      final subscription = handle
          .getFileStream(imageUrl, key: key)
          .listen((_) {}, onError: (_) {});
      addTearDown(subscription.cancel);

      await service.started.future;
      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      service.release.complete();
      await lifecycle.generationRejected.future;
      await cache.purgeAccount(account);

      lifecycle.completeRemoval(account);
      lifecycle.reopen(account);
      final reauthenticated = cache.forAccount(account);

      final namespace = 'planka-images-${sha256.convert(utf8.encode(account))}';
      final namespaceDirectory = Directory(p.join(root.path, namespace));
      if (await namespaceDirectory.exists()) {
        expect(
          await namespaceDirectory
              .list(recursive: true, followLinks: false)
              .where((entry) => entry is File)
              .toList(),
          isEmpty,
        );
      }

      expect(
        await reauthenticated.getFileFromCache(key, ignoreMemCache: true),
        isNull,
      );
      await cache.dispose();
      final cold = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(),
        temporaryDirectory: () async => root,
        createRepository: createRepository,
      );
      addTearDown(cold.dispose);
      expect(
        await cold
            .forAccount(account)
            .getFileFromCache(key, ignoreMemCache: true),
        isNull,
      );
    },
  );

  test(
    'production filesystem holds a pre-admitted write across removal',
    () async {
      const accountA = 'https://planka.example#filesystem-a';
      const accountB = 'https://planka.example#filesystem-b';
      const imageUrl = 'https://planka.example/media/filesystem.png';
      final root = await Directory.systemTemp.createTemp('media_filesystem');
      addTearDown(() => root.delete(recursive: true));
      final phases = _FilesystemPhases();
      final fileSystem = _PhasedFileSystem(phases);
      final cache = AccountImageCacheManager(
        directory: root,
        fileSystem: fileSystem,
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
      );
      addTearDown(cache.dispose);
      final handleA = cache.forAccount(accountA);
      final handleB = cache.forAccount(accountB);
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);
      await handleA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      await handleB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );
      fileSystem.armed = true;

      final file = (await handleA.getFileFromCache(
        keyA,
        ignoreMemCache: true,
      ))!.file;
      final write = file.writeAsBytes('late'.codeUnits);
      await phases.write.started.future;
      final purge = cache.purgeAccount(accountA);

      await expectLater(purge, throwsA(isA<CachePurgeException>()));
      phases.write.release.complete();
      await expectLater(write, throwsA(isA<AccountCacheClosedException>()));

      await cache.purgeAccount(accountA);
      expect(
        await (await handleB.getFileFromCache(
          keyB,
          ignoreMemCache: true,
        ))!.file.readAsString(),
        'B',
      );

      await cache.dispose();
      final cold = AccountImageCacheManager(directory: root);
      addTearDown(cold.dispose);
      expect(
        await cold
            .forAccount(accountA)
            .getFileFromCache(keyA, ignoreMemCache: true),
        isNull,
      );
      expect(
        await (await cold
                .forAccount(accountB)
                .getFileFromCache(keyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        'B',
      );
    },
  );

  test(
    'production filesystem holds a media sink through open stream flush close',
    () async {
      const accountA = 'https://planka.example#filesystem-sink-a';
      const accountB = 'https://planka.example#filesystem-sink-b';
      const imageUrl = 'https://planka.example/media/filesystem-sink.png';
      final root = await Directory.systemTemp.createTemp('media_sink_phases');
      addTearDown(() => root.delete(recursive: true));
      final phases = _FilesystemPhases();
      final fileSystem = _PhasedFileSystem(phases);
      final cache = AccountImageCacheManager(
        directory: root,
        fileSystem: fileSystem,
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
      );
      addTearDown(cache.dispose);
      final handleA = cache.forAccount(accountA);
      final handleB = cache.forAccount(accountB);
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);
      await handleA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      await handleB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );
      fileSystem.armed = true;

      final file = (await handleA.getFileFromCache(
        keyA,
        ignoreMemCache: true,
      ))!.file;
      final sink = file.openWrite();
      final streaming = sink.addStream(
        Stream<List<int>>.value('late'.codeUnits),
      );
      await phases.open.started.future.timeout(const Duration(seconds: 1));

      final purge = cache.purgeAccount(accountA);
      await expectLater(purge, throwsA(isA<CachePurgeException>()));

      phases.open.release.complete();
      await phases.stream.started.future.timeout(const Duration(seconds: 1));
      phases.stream.release.complete();
      await phases.flush.started.future.timeout(const Duration(seconds: 1));
      phases.flush.release.complete();
      await expectLater(streaming, throwsA(isA<AccountCacheClosedException>()));

      await phases.close.started.future.timeout(const Duration(seconds: 1));
      phases.close.release.complete();
      await phases.closeFinished.future.timeout(const Duration(seconds: 1));
      await cache.purgeAccount(accountA);

      expect(
        await (await handleB.getFileFromCache(
          keyB,
          ignoreMemCache: true,
        ))!.file.readAsString(),
        'B',
      );
      await cache.dispose();
      final cold = AccountImageCacheManager(directory: root);
      addTearDown(cold.dispose);
      expect(
        await cold
            .forAccount(accountA)
            .getFileFromCache(keyA, ignoreMemCache: true),
        isNull,
      );
      expect(
        await (await cold
                .forAccount(accountB)
                .getFileFromCache(keyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        'B',
      );
    },
  );

  test(
    'removal bounds a never-ending media response without false success',
    () async {
      const account = 'https://planka.example#never-ending';
      final source = StreamController<FileResponse>();
      final backend = _ControlledMediaCache(responseStream: source.stream);
      final cache = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
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
      await expectLater(
        removal.timeout(const Duration(milliseconds: 250)),
        throwsA(isA<CachePurgeException>()),
      );

      await source.close();
      await cache.purgeAccount(account);
    },
  );

  test(
    'an admitted but never-listened stream does not block removal',
    () async {
      const account = 'https://planka.example#unlistened-stream';
      final backend = _ControlledMediaCache();
      final cache = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
        createManager: (_) => backend,
      );
      final handle = cache.forAccount(account);

      // Admission happens when the handle creates the stream. No consumer
      // attaches, so there is no source subscription to cancel or drain.
      handle.getFileStream('https://planka.example/media/unlistened.png');

      await cache
          .purgeAccount(account)
          .timeout(const Duration(milliseconds: 250));
      expect(backend.emptyCalls, 1);
    },
  );

  test(
    'removal reports bounded media cancellation failure and can retry',
    () async {
      const account = 'https://planka.example#bounded-cancel';
      final source = StreamController<FileResponse>();
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
        await source.close();
        await subscription.cancel();
      });

      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      expect(
        () => cache.forAccount(account),
        throwsA(isA<AccountCacheClosedException>()),
      );

      await source.close();
      await cache.purgeAccount(account);
    },
  );

  test(
    'an immediate retry stays failed until media cancellation settles',
    () async {
      const account = 'https://planka.example#immediate-retry';
      final source = StreamController<FileResponse>();
      var lateCommit = false;
      final cache = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
        createManager: (_) =>
            _ControlledMediaCache(responseStream: source.stream),
      );
      final handle = cache.forAccount(account);
      final subscription = handle
          .getFileStream('https://planka.example/media/late-commit.png')
          .listen((_) {}, onError: (_) {});
      addTearDown(() async {
        await source.close();
        await subscription.cancel();
        await cache.dispose();
      });

      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      expect(lateCommit, isFalse);

      await source.close();
      lateCommit = true;
      expect(lateCommit, isTrue);
      await cache.purgeAccount(account);
    },
  );

  test(
    'a media cancellation error stays unresolved until the source settles',
    () async {
      const account = 'https://planka.example#cancel-error';
      final source = StreamController<FileResponse>();
      final listened = Completer<void>();
      source.onListen = listened.complete;
      final cache = AccountImageCacheManager(
        lifecycle: AccountCacheLifecycle(
          removalTimeout: const Duration(milliseconds: 20),
        ),
        createManager: (_) =>
            _ControlledMediaCache(responseStream: source.stream),
      );
      final handle = cache.forAccount(account);
      final subscription = handle
          .getFileStream('https://planka.example/media/cancel-error.png')
          .listen((_) {}, onError: (_) {});
      addTearDown(() async {
        await source.close();
        await subscription.cancel();
        await cache.dispose();
      });

      await listened.future;
      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );
      await expectLater(
        cache.purgeAccount(account),
        throwsA(isA<CachePurgeException>()),
      );

      await source.close();
      await cache.purgeAccount(account);
    },
  );

  test(
    'concurrent media metadata failures stay with their owning stream',
    () async {
      const account = 'https://planka.example#metadata-owners';
      const imageA = 'https://planka.example/media/metadata-a.png';
      const imageB = 'https://planka.example/media/metadata-b.png';
      final root = await Directory.systemTemp.createTemp(
        'media_metadata_owners',
      );
      addTearDown(() => root.delete(recursive: true));
      final metadata = Directory(p.join(root.path, 'metadata'));
      await metadata.create(recursive: true);
      final failure = _RepositoryFailure();
      final keyA = plankaImageCacheKey(account, imageA);
      final keyB = plankaImageCacheKey(account, imageB);
      final gateA = Completer<void>();
      final startedA = Completer<void>();
      failure
        ..updateGates[keyA] = gateA
        ..updateStartedByKey[keyA] = startedA
        ..failKeys.add(keyA);
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
        fileService: _RecordingFileService(),
      );
      addTearDown(cache.dispose);
      final handle = cache.forAccount(account);
      final firstValues = <FileResponse>[];
      final firstErrors = <Object>[];
      final firstDone = Completer<void>();
      final first = handle
          .getFileStream(imageA, key: keyA)
          .listen(
            firstValues.add,
            onError: (Object error, StackTrace _) => firstErrors.add(error),
            onDone: firstDone.complete,
          );
      addTearDown(first.cancel);
      await startedA.future;

      final secondValues = <FileResponse>[];
      final secondErrors = <Object>[];
      final secondDone = Completer<void>();
      final second = handle
          .getFileStream(imageB, key: keyB)
          .listen(
            secondValues.add,
            onError: (Object error, StackTrace _) => secondErrors.add(error),
            onDone: secondDone.complete,
          );
      addTearDown(second.cancel);

      await secondDone.future.timeout(const Duration(milliseconds: 250));
      expect(secondErrors, isEmpty);
      expect(secondValues.whereType<FileInfo>(), hasLength(1));

      gateA.complete();
      await firstDone.future;
      expect(firstErrors, hasLength(1));
      expect(firstErrors.single, isA<CacheOperationException>());
      expect(firstValues.whereType<FileInfo>(), isEmpty);
    },
  );

  for (final statusCode in [HttpStatus.notModified, HttpStatus.notFound]) {
    test(
      '$statusCode response without a body does not retain an account lease',
      () async {
        final directory = await Directory.systemTemp.createTemp('media_status');
        addTearDown(() => directory.delete(recursive: true));
        final cache = AccountImageCacheManager(
          directory: directory,
          lifecycle: AccountCacheLifecycle(
            removalTimeout: const Duration(milliseconds: 20),
          ),
          fileService: _StatusFileService(statusCode),
        );
        addTearDown(cache.dispose);
        final handle = cache.forAccount(accountA);
        final request = handle.getSingleFile(
          'https://planka.example/media/status-$statusCode.png',
        );
        if (statusCode == HttpStatus.notFound) {
          await expectLater(request, throwsA(isA<CacheOperationException>()));
        } else {
          await request;
        }

        await cache.purgeAccount(accountA);
      },
    );
  }

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

      await cache.purgeAccount(account);
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

  test(
    'metadata failure is a stream error and a later stream retry succeeds',
    () async {
      const account = 'https://production.example#stream-metadata-failure';
      const imageUrl =
          'https://production.example/media/stream-metadata-failure.png';
      final root = await Directory.systemTemp.createTemp(
        'media_stream_metadata',
      );
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
        fileService: _RecordingFileService(),
      );
      addTearDown(cache.dispose);
      final handle = cache.forAccount(account);
      final key = plankaImageCacheKey(account, imageUrl);
      final values = <FileResponse>[];
      final errors = <Object>[];
      final done = Completer<void>();

      final first = handle
          .getFileStream(imageUrl, key: key)
          .listen(
            values.add,
            onError: (Object error, StackTrace _) => errors.add(error),
            onDone: done.complete,
          );
      await done.future;
      await first.cancel();

      expect(errors, hasLength(1));
      expect(errors.single, isA<CacheOperationException>());
      expect(values.whereType<FileInfo>(), isEmpty);

      final retry = await handle.getFileStream(imageUrl, key: key).toList();
      expect(retry.whereType<FileInfo>(), hasLength(1));
      expect(
        await retry.whereType<FileInfo>().single.file.readAsString(),
        'media',
      );
    },
  );

  test(
    'delayed authenticated 304 metadata is drained before media removal',
    () async {
      const imageUrl = 'https://production.example/media/delayed-304.png';
      const token = 'delayed-304-token-canary';
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);

      for (final releaseBeforeRemoval in [false, true]) {
        final root = await Directory.systemTemp.createTemp('media_delayed_304');
        final metadata = Directory(p.join(root.path, 'metadata'));
        await metadata.create(recursive: true);
        final failure = _RepositoryFailure();
        CacheInfoRepository createRepository(String namespace) =>
            _FailingCacheInfoRepository(
              JsonCacheInfoRepository.withFile(
                File(p.join(metadata.path, '$namespace.json')),
              ),
              failure,
            );
        final seed = AccountImageCacheManager(
          temporaryDirectory: () async => root,
          createRepository: createRepository,
        );
        var seedDisposed = false;

        try {
          await seed
              .forAccount(accountA)
              .putFile(
                imageUrl,
                Uint8List.fromList('A'.codeUnits),
                key: keyA,
                maxAge: Duration.zero,
              );
          await seed
              .forAccount(accountB)
              .putFile(imageUrl, Uint8List.fromList('B'.codeUnits), key: keyB);
          await seed.dispose();
          seedDisposed = true;

          final metadataGate = Completer<void>();
          final metadataStarted = Completer<void>();
          final firstTouch = Completer<void>()..complete();
          failure.updateCounts.clear();
          failure.updateGatesByKey[keyA] = [firstTouch, metadataGate];
          failure.updateStartedByCall[keyA] = {2: metadataStarted};
          final service = _DelayedStatusFileService(HttpStatus.notModified);
          final cache = AccountImageCacheManager(
            lifecycle: AccountCacheLifecycle(
              removalTimeout: const Duration(milliseconds: 20),
            ),
            temporaryDirectory: () async => root,
            createRepository: createRepository,
            fileService: service,
          );
          var disposed = false;
          final namespaceA =
              'planka-images-${sha256.convert(utf8.encode(accountA))}';

          Future<void> expectAStorageEmpty() async {
            final namespaceFiles = Directory(p.join(root.path, namespaceA));
            if (await namespaceFiles.exists()) {
              expect(
                await namespaceFiles
                    .list(recursive: true, followLinks: false)
                    .where((entry) => entry is File)
                    .toList(),
                isEmpty,
              );
            }
            final metadataFile =
                File(p.join(metadata.path, '$namespaceA.json'));
            if (await metadataFile.exists()) {
              final repository =
                  JsonCacheInfoRepository.withFile(metadataFile);
              await repository.open();
              try {
                expect(await repository.getAllObjects(), isEmpty);
              } finally {
                await repository.close();
              }
            }
          }

          try {
            final handleA = cache.forAccount(accountA, token: token);
            final delayed304 = handleA.getSingleFile(
              imageUrl,
              key: keyA,
              headers: {'Authorization': 'Bearer $token'},
            );
            final delayed304Outcome = delayed304.then<Object?>(
              (_) => null,
              onError: (Object error, StackTrace _) => error,
            );
            await service.started.future.timeout(
              const Duration(milliseconds: 250),
            );
            expect(service.url, imageUrl);
            expect(service.headers, {'Authorization': 'Bearer $token'});

            Future<void> expectRemovalFailure(Future<void> removal) async {
              await expectLater(removal, throwsA(isA<CachePurgeException>()));
            }

            if (releaseBeforeRemoval) {
              service.release.complete();
              await metadataStarted.future.timeout(
                const Duration(milliseconds: 250),
              );
              final removal = cache.purgeAccount(accountA);
              await expectRemovalFailure(removal);
            } else {
              var removalCompleted = false;
              final removal = cache
                  .purgeAccount(accountA)
                  .whenComplete(() => removalCompleted = true);
              await Future<void>.delayed(Duration.zero);
              expect(removalCompleted, isFalse);
              service.release.complete();
              await removal;
            }

            metadataGate.complete();
            expect(await delayed304Outcome, isA<AccountCacheClosedException>());
            await Future<void>.delayed(const Duration(milliseconds: 50));
            if (!releaseBeforeRemoval) await expectAStorageEmpty();
            await cache.purgeAccount(accountA);

            await cache.dispose();
            disposed = true;
            await expectAStorageEmpty();
            final cold = AccountImageCacheManager(
              temporaryDirectory: () async => root,
              createRepository: createRepository,
            );
            expect(
              await cold
                  .forAccount(accountA)
                  .getFileFromCache(keyA, ignoreMemCache: true),
              isNull,
            );
            expect(
              (await cold
                      .forAccount(accountB)
                      .getFileFromCache(keyB, ignoreMemCache: true))!
                  .file
                  .readAsString(),
              completion('B'),
            );
            await cold.dispose();
          } finally {
            if (!disposed) await cache.dispose();
          }
        } finally {
          if (!seedDisposed) await seed.dispose();
          await root.delete(recursive: true);
        }
      }
    },
  );

  test(
    'a real media metadata commit crossing removal cannot survive cold reconstruction',
    () async {
      const imageUrl = 'https://planka.example/media/race.png';
      final root = await Directory.systemTemp.createTemp('media_commit_race');
      addTearDown(() => root.delete(recursive: true));
      final metadata = Directory(p.join(root.path, 'metadata'));
      await metadata.create(recursive: true);
      final failure = _RepositoryFailure();
      CacheInfoRepository createRepository(String namespace) =>
          _FailingCacheInfoRepository(
            JsonCacheInfoRepository.withFile(
              File(p.join(metadata.path, '$namespace.json')),
            ),
            failure,
          );
      final lifecycle = AccountCacheLifecycle();
      final cache = AccountImageCacheManager(
        lifecycle: lifecycle,
        temporaryDirectory: () async => root,
        createRepository: createRepository,
      );
      addTearDown(cache.dispose);
      const keyA = 'race-key-a';
      const keyB = 'race-key-b';
      final handleB = cache.forAccount(accountB);
      await handleB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );

      final handleA = cache.forAccount(accountA);
      final gate = Completer<void>();
      final started = Completer<void>();
      failure
        ..updateGate = gate
        ..updateStarted = started;
      final pending = handleA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      await started.future;

      final removal = cache.purgeAccount(accountA);
      expect(
        () => cache.forAccount(accountA),
        throwsA(isA<AccountCacheClosedException>()),
      );
      gate.complete();
      failure.updateGate = null;
      await expectLater(pending, throwsA(isA<AccountCacheClosedException>()));
      await removal;

      expect(
        (await handleB.getFileFromCache(
          keyB,
          ignoreMemCache: true,
        ))!.file.readAsString(),
        completion('B'),
      );
      await cache.dispose();
      final cold = AccountImageCacheManager(
        temporaryDirectory: () async => root,
        createRepository: createRepository,
      );
      addTearDown(cold.dispose);
      expect(
        await cold
            .forAccount(accountA)
            .getFileFromCache(keyA, ignoreMemCache: true),
        isNull,
      );
      expect(
        (await cold
                .forAccount(accountB)
                .getFileFromCache(keyB, ignoreMemCache: true))!
            .file
            .readAsString(),
        completion('B'),
      );
    },
  );
}
