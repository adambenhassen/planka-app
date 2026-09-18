import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart' as file;
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../cache_lifecycle.dart';
import '../cache_purge.dart';
import '../security_redaction.dart';
import 'envelope.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.statusCode, String message)
    : message = redactDiagnostic(message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A fresh Planka server requires accepting its Terms of Service before it
/// will issue a token. [login] throws this instead of returning; the caller
/// confirms with the user, calls [PlankaApi.acceptTerms], then retries login.
class TermsRequiredException implements Exception {
  final String pendingToken;
  TermsRequiredException(this.pendingToken) {
    registerSecret(pendingToken);
  }

  @override
  String toString() => 'TermsRequiredException';
}

/// A server with two-factor authentication enabled rejects login with 403
/// {step: verify-totp, pendingToken}. [login] throws this instead of returning;
/// the caller collects a code and calls [PlankaApi.verifyTotp].
///
/// For the ten minutes it lives, the pending token converts into a full access
/// token on six digits, so it is worth what the password is worth: hold it in
/// memory for the length of the step, never persist it, and never render it —
/// hence the constant [toString], since `showApiError` prints '$error' for
/// anything it does not recognise.
class TotpRequiredException implements Exception {
  final String pendingToken;
  TotpRequiredException(this.pendingToken) {
    registerSecret(pendingToken);
  }

  @override
  String toString() => 'TotpRequiredException';
}

/// The server rejected the submitted code (403). The pending token is still
/// valid, so the caller stays on the code step and can try again.
class TotpCodeRejectedException implements Exception {
  @override
  String toString() => 'TotpCodeRejectedException';
}

/// The pending token was invalid, or its ten-minute window closed (401). The
/// caller must start again from credentials. This is *not* session expiry —
/// no session exists yet.
class TotpPendingTokenExpiredException implements Exception {
  @override
  String toString() => 'TotpPendingTokenExpiredException';
}

/// Planka serves attachment and cover images behind session-cookie auth rather
/// than the Bearer header the REST API uses. This helper is the single source
/// of truth for the download-auth scheme, and every consumer goes through it.
///
/// A null result means [imageUrl] is not on the configured server origin and
/// must not be loaded with credentials.
Map<String, String>? imageAuthHeaders(
  String token, {
  required String serverUrl,
  required String imageUrl,
}) {
  registerSecret(token);
  final server = Uri.tryParse(serverUrl);
  final image = Uri.tryParse(imageUrl);
  if (server == null || image == null || !_sameOrigin(server, image)) {
    return null;
  }
  return {'Cookie': 'accessToken=$token'};
}

bool _sameOrigin(Uri server, Uri image) {
  if (!server.hasScheme ||
      server.host.isEmpty ||
      !image.hasScheme ||
      image.host.isEmpty) {
    return false;
  }
  return server.scheme.toLowerCase() == image.scheme.toLowerCase() &&
      server.host.toLowerCase() == image.host.toLowerCase() &&
      _originPort(server) == _originPort(image);
}

int _originPort(Uri uri) {
  if (uri.hasPort) return uri.port;
  return switch (uri.scheme.toLowerCase()) {
    'http' => 80,
    'https' => 443,
    _ => -1,
  };
}

/// Cached media requests carry the session cookie in their headers. Disabling
/// redirects keeps a response from replaying that cookie to another origin.
class _NoRedirectClient extends http.BaseClient {
  _NoRedirectClient() : _client = http.Client();

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.followRedirects = false;
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}

final FileService plankaImageFileService = _RedactingFileService(
  HttpFileService(httpClient: _NoRedirectClient()),
);

// This is an in-process handoff from the account cache handle to its file
// service. It lets the cache manager retain a sanitized URL while the
// authenticated transport still receives the caller's complete URL.
const _originalMediaUrlHeader = 'x-planka-original-url';

/// Keeps the third-party cache manager from persisting credentials returned in
/// a URL, response body, ETag, or content-type-derived filename. The wrapped
/// service still receives the authenticated headers needed for the request.
class _RedactingFileService extends FileService {
  _RedactingFileService(this._delegate) {
    concurrentFetches = _delegate.concurrentFetches;
  }

  final FileService _delegate;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _delegate.get(url, headers: headers);
      return _RedactingFileServiceResponse(response);
    } catch (_) {
      throw CacheOperationException('fileService');
    }
  }
}

class _RedactingFileServiceResponse implements FileServiceResponse {
  _RedactingFileServiceResponse(this._delegate);

  final FileServiceResponse _delegate;

  @override
  Stream<List<int>> get content async* {
    try {
      yield* redactCacheStream(_delegate.content);
    } catch (_) {
      throw CacheOperationException('fileService');
    }
  }

  @override
  int? get contentLength => _delegate.contentLength;

  @override
  int get statusCode => _delegate.statusCode;

  @override
  DateTime get validTill => _delegate.validTill;

  @override
  String? get eTag => null;

  @override
  String get fileExtension => 'file';
}

/// Associates the cache-manager response body with the account lifecycle. The
/// cache manager package owns the subscription that writes the file, so the
/// account lease must cancel the response body directly when removal starts.
class _AccountFileService extends FileService {
  _AccountFileService(this._accountId, this._lifecycle, this._delegate) {
    concurrentFetches = _delegate.concurrentFetches;
  }

  final String _accountId;
  final AccountCacheLifecycle _lifecycle;
  final FileService _delegate;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final generation = _lifecycle.generationFor(_accountId);
    final requestHeaders = <String, String>{...?headers};
    final originalUrl = requestHeaders.remove(_originalMediaUrlHeader) ?? url;
    final response = await _delegate.get(originalUrl, headers: requestHeaders);
    return _AccountFileServiceResponse(
      response,
      _accountId,
      _lifecycle,
      generation,
    );
  }
}

class _AccountFileServiceResponse implements FileServiceResponse {
  _AccountFileServiceResponse(
    this._delegate,
    this._accountId,
    this._lifecycle,
    this._generation,
  );

  final FileServiceResponse _delegate;
  final String _accountId;
  final AccountCacheLifecycle _lifecycle;
  final int _generation;
  Stream<List<int>>? _content;

  @override
  Stream<List<int>> get content => _content ??= _createContent();

  Stream<List<int>> _createContent() {
    final controller = StreamController<List<int>>();
    StreamSubscription<List<int>>? subscription;
    AccountCacheLease? lease;
    final sourceSettled = Completer<void>();
    Future<void>? cancellation;
    var cancelled = false;
    var released = false;

    void release() {
      if (released) return;
      released = true;
      lease?.release();
    }

    void markSourceSettled() {
      if (!sourceSettled.isCompleted) sourceSettled.complete();
    }

    Future<void> finishAfterSource() async {
      try {
        await sourceSettled.future;
      } catch (_) {
        lease?.reportRemovalFailure();
      }
      if (!controller.isClosed) unawaited(controller.close());
      release();
    }

    Future<void> cancelImplementation() async {
      cancelled = true;
      if (subscription == null) {
        if (!controller.isClosed) unawaited(controller.close());
        release();
        return;
      }
      try {
        await sourceSettled.future.timeout(_lifecycle.removalTimeout);
      } on TimeoutException {
        lease?.reportRemovalFailure();
        if (!controller.isClosed) unawaited(controller.close());
        unawaited(finishAfterSource());
        return;
      } catch (_) {
        lease?.reportRemovalFailure();
        if (!controller.isClosed) unawaited(controller.close());
        unawaited(finishAfterSource());
        return;
      }
      if (!controller.isClosed) unawaited(controller.close());
      release();
    }

    Future<void> cancelSource() => cancellation ??= cancelImplementation();

    controller.onListen = () {
      try {
        lease = _lifecycle.acquire(_accountId, generation: _generation);
      } catch (e, s) {
        controller.addError(e, s);
        unawaited(controller.close());
        return;
      }
      if (cancelled) {
        unawaited(controller.close());
        release();
        return;
      }
      final shared = redactCacheStream(_delegate.content).asBroadcastStream();
      subscription = shared.listen(
        (chunk) {
          if (!cancelled && !controller.isClosed) controller.add(chunk);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
        onDone: () async {
          markSourceSettled();
          await controller.close();
          release();
        },
      );
      // This passive listener preserves an independent source-completion
      // signal when the data subscription reports a cancellation error.
      shared.listen(
        (_) {},
        onError: (Object _, StackTrace _) {},
        onDone: markSourceSettled,
      );
      lease!.onRemoval(cancelSource);
    };
    controller.onCancel = cancelSource;
    return controller.stream;
  }

  @override
  int? get contentLength => _delegate.contentLength;

  @override
  int get statusCode => _delegate.statusCode;

  @override
  DateTime get validTill => _delegate.validTill;

  @override
  String? get eTag => _delegate.eTag;

  @override
  String get fileExtension => _delegate.fileExtension;
}

typedef AccountImageCacheFactory = BaseCacheManager Function(String accountId);
typedef AccountCacheRepositoryFactory =
    CacheInfoRepository Function(String namespace);
typedef AccountCacheDirectoryProvider = Future<Directory> Function();
typedef AccountImageCacheEvictor = FutureOr<void> Function(Object key);

/// Stable cache key for one authenticated media URL and one account.
///
/// Both parts are hashed so neither a URL query credential nor an account
/// identifier can become a raw cache identity or filesystem name.
String plankaImageCacheKey(String accountId, String imageUrl) =>
    'planka-image-${sha256.convert(utf8.encode('$accountId\u0000$imageUrl'))}';

String _plankaImageCacheNamespace(String accountId) =>
    'planka-images-${sha256.convert(utf8.encode(accountId))}';

/// Owns one persistent media cache namespace per account.
///
/// A manager is recreated from the same deterministic namespace after a
/// process restart, while [purgeAccount] only empties the requested account's
/// namespace.
class AccountImageCacheManager {
  AccountImageCacheManager({
    AccountImageCacheFactory? createManager,
    Directory? directory,
    AccountCacheLifecycle? lifecycle,
    AccountCacheRepositoryFactory? createRepository,
    AccountCacheDirectoryProvider? temporaryDirectory,
    FileService? fileService,
    file.FileSystem? fileSystem,
    AccountImageCacheEvictor? evictImageKey,
  })  : _lifecycle = lifecycle ?? AccountCacheLifecycle(),
        _evictImageKey = evictImageKey ?? _evictFlutterImage {
    _createManager =
        createManager ??
        ((accountId) => _createDefaultManager(
          accountId,
          directory,
          createRepository,
          temporaryDirectory,
          fileService,
          fileSystem,
          _lifecycle,
        ));
  }

  late final AccountImageCacheFactory _createManager;
  final AccountCacheLifecycle _lifecycle;
  final AccountImageCacheEvictor _evictImageKey;
  final Map<String, BaseCacheManager> _managers = {};
  final Map<String, _AccountCacheHandle> _handles = {};
  final Map<String, Set<Object>> _trackedImageKeys = {};
  final Set<String> _purgedImageAccounts = {};

  static void _evictFlutterImage(Object key) {
    PaintingBinding.instance.imageCache.evict(key);
  }

  /// Records the exact image-provider key created by a cached image widget.
  /// The provider object, rather than only its URL, is needed because Flutter's
  /// global image cache keys include the account cache manager and cache key.
  void trackImageKey(String accountId, Object key) {
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    if (_purgedImageAccounts.contains(accountId)) {
      unawaited(_evictLateImageKey(accountId, key));
      return;
    }
    _trackedImageKeys.putIfAbsent(accountId, () => <Object>{}).add(key);
  }

  Future<void> _evictLateImageKey(String accountId, Object key) async {
    try {
      await _evictImageKey(key);
    } catch (error) {
      _trackedImageKeys.putIfAbsent(accountId, () => <Object>{}).add(key);
      debugPrint('account image eviction failed: ${redactDiagnostic(error)}');
    }
  }

  Future<void> _evictTrackedImageKeys(String accountId) async {
    final keys = {...?_trackedImageKeys[accountId]};
    if (keys.isEmpty) return;
    final failed = <Object>{};
    Object? firstFailure;
    StackTrace? firstFailureStack;
    await Future.wait(
      keys.map((key) async {
        try {
          await _evictImageKey(key);
        } catch (error, stackTrace) {
          failed.add(key);
          firstFailure ??= error;
          firstFailureStack ??= stackTrace;
        }
      }),
    );
    // A late image builder can register another key while this pass is in
    // flight. Preserve that key, and only remove the snapshot entries that
    // were actually evicted by this pass.
    final remaining = {...?_trackedImageKeys[accountId]}
      ..removeAll(keys)
      ..addAll(failed);
    if (remaining.isEmpty) {
      _trackedImageKeys.remove(accountId);
    } else {
      _trackedImageKeys[accountId] = remaining;
    }
    if (firstFailure != null) {
      Error.throwWithStackTrace(firstFailure!, firstFailureStack!);
    }
  }

  /// Makes decoded images unavailable when an authenticated session leaves
  /// the foreground. Persistent files stay account-scoped for offline use,
  /// but Flutter's process-global decoded cache must not survive a logout or
  /// account switch. Late image builders for the inactive account are evicted
  /// as well until that account is selected again.
  Future<void> evictDecodedAccount(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    _purgedImageAccounts.add(accountId);
    try {
      await _evictTrackedImageKeys(accountId);
    } catch (error) {
      debugPrint(
        'account image eviction failed: ${redactDiagnostic(error)}',
      );
    }
  }

  BaseCacheManager forAccount(String accountId, {String? token}) {
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    registerSecret(token);
    _lifecycle.register(accountId);
    _purgedImageAccounts.remove(accountId);
    final generation = _lifecycle.generationFor(accountId);
    final existing = _handles[accountId];
    if (existing != null && existing.generation == generation) return existing;
    final manager = _managers.putIfAbsent(
      accountId,
      () => _createManager(accountId),
    );
    final handle = _AccountCacheHandle(
      accountId,
      manager,
      _lifecycle,
      generation,
    );
    _handles[accountId] = handle;
    return handle;
  }

  /// Removes every media entry in one account namespace and verifies that a
  /// fresh manager over the same on-disk namespace is empty before returning.
  Future<void> purgeAccount(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId');
    }
    _purgedImageAccounts.add(accountId);
    Object? firstFailure;
    StackTrace? firstFailureStack;
    final evictFuture = _evictTrackedImageKeys(accountId);
    try {
      await _lifecycle.beginRemoval(accountId);
    } catch (e, s) {
      firstFailure = e;
      firstFailureStack = s;
    }
    try {
      await evictFuture;
    } catch (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    }
    if (firstFailure != null) {
      throw CachePurgeException(
        'media',
        firstFailure,
        firstFailureStack ?? StackTrace.current,
      );
    }
    BaseCacheManager manager;
    try {
      manager = _managers.remove(accountId) ?? _createManager(accountId);
      _handles.remove(accountId);
    } catch (e, s) {
      throw CachePurgeException('media', e, s);
    }

    await _waitForPending(manager, (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    });
    final targets = await _mediaFiles(manager, (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    });
    if (targets != null) {
      if (manager case CacheManager concrete) {
        concrete.store.emptyMemoryCache();
      }
      await Future.wait(
        targets.map((target) async {
          try {
            if (await target.exists()) await target.delete();
          } catch (e, s) {
            firstFailure ??= e;
            firstFailureStack ??= s;
          }
        }),
      );
      for (final target in targets) {
        try {
          if (await target.exists()) {
            firstFailure ??= StateError('Media cache targets remain');
            firstFailureStack ??= StackTrace.current;
          }
        } catch (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        }
      }
    }
    await _waitForPending(manager, (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    });
    try {
      if (firstFailure == null) {
        await manager.emptyCache();
        await _waitForPending(manager, (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        });
        await _verifyEmpty(manager);
      }
    } catch (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    }

    try {
      await manager.dispose();
    } catch (e, s) {
      firstFailure ??= e;
      firstFailureStack ??= s;
    }

    if (firstFailure == null) {
      BaseCacheManager? reconstructed;
      try {
        reconstructed = _createManager(accountId);
        await _verifyEmpty(reconstructed);
      } catch (e, s) {
        firstFailure = e;
        firstFailureStack = s;
      } finally {
        try {
          await reconstructed?.dispose();
        } catch (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        }
      }
    }

    if (firstFailure != null) {
      throw CachePurgeException(
        'media',
        firstFailure!,
        firstFailureStack ?? StackTrace.current,
      );
    }
  }

  Future<void> dispose() async {
    final managers = _managers.values.toList();
    _managers.clear();
    _handles.clear();
    Object? firstFailure;
    StackTrace? firstFailureStack;
    await Future.wait(
      managers.map((manager) async {
        await _waitForPending(manager, (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        });
        try {
          await manager.dispose();
        } catch (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        }
      }),
    );
    if (firstFailure != null) {
      throw CachePurgeException(
        'media',
        firstFailure!,
        firstFailureStack ?? StackTrace.current,
      );
    }
  }

  static BaseCacheManager _createDefaultManager(
    String accountId,
    Directory? directory,
    AccountCacheRepositoryFactory? createRepository,
    AccountCacheDirectoryProvider? temporaryDirectory,
    FileService? fileService,
    file.FileSystem? fileSystem,
    AccountCacheLifecycle lifecycle,
  ) {
    final namespace = _plankaImageCacheNamespace(accountId);
    final storageFileSystem = fileSystem ?? LocalFileSystem();
    final accountFileSystem = _AccountDirectoryFileSystem(
      _accountDirectory(
        namespace,
        directory,
        temporaryDirectory ?? getTemporaryDirectory,
        storageFileSystem,
      ),
      accountId,
      lifecycle,
      lifecycle.generationFor(accountId),
    );
    final requestService = fileService == null
        ? plankaImageFileService
        : _RedactingFileService(fileService);
    final repository = createRepository?.call(namespace);
    final accountFileService = _AccountFileService(
      accountId,
      lifecycle,
      requestService,
    );
    late final Config baseConfig;
    if (repository != null) {
      baseConfig = Config(
        namespace,
        repo: repository,
        fileSystem: accountFileSystem,
        fileService: accountFileService,
      );
    } else if (directory == null) {
      baseConfig = Config(
        namespace,
        fileSystem: accountFileSystem,
        fileService: accountFileService,
      );
    } else {
      baseConfig = Config(
        namespace,
        repo: JsonCacheInfoRepository.withFile(
          storageFileSystem.file(p.join(directory.path, '$namespace.json')),
        ),
        fileSystem: accountFileSystem,
        fileService: accountFileService,
      );
    }
    final config = Config(
      baseConfig.cacheKey,
      stalePeriod: baseConfig.stalePeriod,
      maxNrOfCacheObjects: baseConfig.maxNrOfCacheObjects,
      repo: _TrackedCacheInfoRepository(
        baseConfig.repo,
        lifecycle: lifecycle,
        accountId: accountId,
        generation: lifecycle.generationFor(accountId),
      ),
      fileSystem: _SafeFileSystem(baseConfig.fileSystem),
      fileService: baseConfig.fileService,
    );
    return CacheManager(config);
  }

  static Future<file.Directory> _accountDirectory(
    String namespace,
    Directory? directory,
    AccountCacheDirectoryProvider temporaryDirectory,
    file.FileSystem fileSystem,
  ) async {
    final base = directory ?? await temporaryDirectory();
    return fileSystem.directory(p.join(base.path, namespace));
  }

  Future<void> _waitForPending(
    BaseCacheManager manager,
    void Function(Object, StackTrace) onFailure,
  ) async {
    if (manager case CacheManager concrete) {
      final repository = concrete.config.repo;
      if (repository is! _TrackedCacheInfoRepository) return;
      try {
        await repository.waitForPending();
      } catch (e, s) {
        onFailure(e, s);
      }
    }
  }

  Future<List<file.File>?> _mediaFiles(
    BaseCacheManager manager,
    void Function(Object, StackTrace) onFailure,
  ) async {
    if (manager case CacheManager concrete) {
      final repository = concrete.config.repo;
      final targets = <file.File>[];
      var opened = false;
      try {
        await repository.open();
        opened = true;
        final objects = await repository.getAllObjects();
        for (final object in objects) {
          try {
            final fileSystem = _rawFileSystem(concrete.config.fileSystem);
            final target = switch (fileSystem) {
              _AccountDirectoryFileSystem fs => await fs.rawFile(
                object.relativePath,
              ),
              _ => await concrete.config.fileSystem.createFile(
                object.relativePath,
              ),
            };
            targets.add(target);
          } catch (e, s) {
            onFailure(e, s);
          }
        }
      } catch (e, s) {
        onFailure(e, s);
      } finally {
        if (opened) {
          try {
            await repository.close();
          } catch (e, s) {
            onFailure(e, s);
          }
        }
      }

      // The repository can be missing a row when its asynchronous metadata
      // insert failed. Enumerate the owned physical directory independently
      // so that orphan files are still deleted and verified on retry.
      try {
        final fileSystem = _rawFileSystem(concrete.config.fileSystem);
        if (fileSystem case _AccountDirectoryFileSystem fs) {
          final directory = await fs.directory;
          if (await directory.exists()) {
            await for (final entry in directory.list(
              recursive: true,
              followLinks: false,
            )) {
              if (entry is file.File) targets.add(entry);
            }
          }
        }
      } catch (e, s) {
        onFailure(e, s);
      }

      final seen = <String>{};
      return targets.where((target) => seen.add(target.path)).toList();
    }
    return null;
  }

  Future<void> _verifyEmpty(BaseCacheManager manager) async {
    if (manager case CacheManager concrete) {
      final repository = concrete.config.repo;
      await repository.open();
      try {
        final entries = await repository.getAllObjects();
        if (entries.isNotEmpty) {
          throw StateError('Media cache entries remain');
        }
      } finally {
        await repository.close();
      }
      final fileSystem = _rawFileSystem(concrete.config.fileSystem);
      if (fileSystem case _AccountDirectoryFileSystem fs) {
        final directory = await fs.directory;
        if (await directory.exists()) {
          await for (final entry in directory.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entry is file.File) {
              throw StateError('Media cache files remain');
            }
          }
        }
      }
    }
  }
}

/// Tracks cache metadata writes that flutter_cache_manager starts without
/// awaiting. Removal must wait for those futures before deleting and verifying
/// the namespace, otherwise a late repository update can recreate an entry
/// after the cold check has passed.
class _TrackedCacheInfoRepository extends CacheInfoRepository {
  _TrackedCacheInfoRepository(
    this._delegate, {
    this._lifecycle,
    this._accountId,
    this._generation,
  });

  final CacheInfoRepository _delegate;
  final AccountCacheLifecycle? _lifecycle;
  final String? _accountId;
  final int? _generation;
  final _TrackedCacheOperation _unowned = _TrackedCacheOperation();

  _TrackedCacheOperation beginOperation() => _TrackedCacheOperation();

  _TrackedCacheOperation get _currentOperation =>
      (Zone.current[_cacheOperationZoneKey] as _TrackedCacheOperation?) ??
      _unowned;

  Future<T> _track<T>(Future<T> operation) {
    _trackCompletion(operation);
    return operation;
  }

  void _trackCompletion<T>(Future<T> operation) {
    final tracking = _currentOperation;
    final done = Completer<void>();
    final marker = done.future;
    tracking.pending.add(marker);
    operation.then<void>(
      (_) {
        _complete(tracking, marker, done);
      },
      onError: (Object _, StackTrace stackTrace) {
        tracking.failures.add(
          _TrackedRepositoryFailure(
            CacheOperationException('cache'),
            StackTrace.fromString(redactDiagnostic(stackTrace)),
          ),
        );
        _complete(tracking, marker, done);
      },
    );
  }

  void _complete(
    _TrackedCacheOperation tracking,
    Future<void> marker,
    Completer<void> done,
  ) {
    tracking.pending.remove(marker);
    if (!done.isCompleted) done.complete();
  }

  Future<void> waitForPending([_TrackedCacheOperation? tracking]) async {
    final operation = tracking ?? _unowned;
    while (operation.pending.isNotEmpty) {
      await Future.wait(operation.pending.toList());
    }
    if (operation.failures.isNotEmpty) {
      final failure = operation.failures.first;
      Error.throwWithStackTrace(failure.error, failure.stackTrace);
    }
  }

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  Future<bool> open() => _delegate.open();

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject) {
    AccountCacheLease? lease;
    final lifecycle = _lifecycle;
    final accountId = _accountId;
    final generation = _generation;
    if (lifecycle != null && accountId != null && generation != null) {
      try {
        // CacheManager starts this write without awaiting it. Admit the
        // metadata mutation itself, not only the caller that started the
        // response, so a late 304 update remains inside removal's drain.
        lease = lifecycle.acquire(accountId, generation: generation);
      } on AccountCacheClosedException {
        // An old-generation write that starts after removal is already closed
        // must be a no-op. Returning a completed future also prevents the
        // third-party cache manager's unhandled `.then` chain from surfacing a
        // raw backend error.
        return Future<dynamic>.value(null);
      }
    }

    late final Future<dynamic> operation;
    try {
      operation = _delegate.updateOrInsert(cacheObject);
    } catch (_) {
      lease?.release();
      rethrow;
    }
    final guarded = operation.then<dynamic>(
      (value) {
        // The lifecycle lease keeps removal behind the actual backend future.
        // A generation that was closed while the write was in flight is
        // deleted by the purge after this future settles.
        lease?.release();
        return value;
      },
      onError: (Object error, StackTrace stackTrace) {
        lease?.release();
        return Future<dynamic>.error(error, stackTrace);
      },
    );
    _trackCompletion(guarded);
    // CacheManager.putFile intentionally does not await this operation. Keep
    // its returned future error-free so the tracked, sanitized failure is
    // surfaced by the owning handle instead of as an unhandled exception.
    return guarded.catchError((Object _, StackTrace _) => null);
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) => _track(_delegate.insert(cacheObject, setTouchedToNow: setTouchedToNow));

  @override
  Future<CacheObject?> get(String key) => _delegate.get(key);

  @override
  Future<int> delete(int id) => _track(_delegate.delete(id));

  @override
  Future<int> deleteAll(Iterable<int> ids) => _track(_delegate.deleteAll(ids));

  @override
  Future<int> update(CacheObject cacheObject, {bool setTouchedToNow = true}) =>
      _track(_delegate.update(cacheObject, setTouchedToNow: setTouchedToNow));

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

class _TrackedRepositoryFailure {
  _TrackedRepositoryFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

class _TrackedCacheOperation {
  final Set<Future<void>> pending = {};
  final List<_TrackedRepositoryFailure> failures = [];
}

final Object _cacheOperationZoneKey = Object();

/// A per-account view over a cache backend. Every operation is admitted by the
/// shared lifecycle, including operations started through a handle retained by
/// a widget before account removal began.
class _AccountCacheHandle implements BaseCacheManager {
  _AccountCacheHandle(
    this._accountId,
    this._manager,
    this._lifecycle,
    this._generation,
  );

  final String _accountId;
  final BaseCacheManager _manager;
  final AccountCacheLifecycle _lifecycle;
  final int _generation;

  int get generation => _generation;

  String _safeUrl(String url) => cacheSafeUrl(url);

  Map<String, String> _requestHeaders(
    String url,
    Map<String, String>? headers,
  ) => {...?headers, _originalMediaUrlHeader: url};

  String _safeKey(String? key, String url) {
    final candidate = key ?? cacheIdentityUrl(url);
    if (RegExp(r'^planka-image-[0-9a-f]{64}$').hasMatch(candidate)) {
      return candidate;
    }
    return 'planka-cache-${sha256.convert(utf8.encode(candidate))}';
  }

  _TrackedCacheOperation? _beginBackendOperation() {
    if (_manager case CacheManager concrete) {
      final repository = concrete.config.repo;
      if (repository is _TrackedCacheInfoRepository) {
        return repository.beginOperation();
      }
    }
    return null;
  }

  Future<T> _runInBackendOperation<T>(
    _TrackedCacheOperation? operation,
    Future<T> Function() action,
  ) {
    if (operation == null) return action();
    return runZoned(action, zoneValues: {_cacheOperationZoneKey: operation});
  }

  T _callInBackendOperation<T>(
    _TrackedCacheOperation? operation,
    T Function() action,
  ) {
    if (operation == null) return action();
    return runZoned(action, zoneValues: {_cacheOperationZoneKey: operation});
  }

  Future<void> _settleBackend(_TrackedCacheOperation? operation) async {
    if (_manager case CacheManager concrete) {
      final repository = concrete.config.repo;
      if (repository is _TrackedCacheInfoRepository) {
        // CacheManager.putFile and WebHelper._manageResponse intentionally
        // start metadata updates without awaiting them. Give that handoff one
        // event-loop turn, then wait for the tracked operation itself.
        await Future<void>.delayed(Duration.zero);
        await repository.waitForPending(operation);
      }
    }
  }

  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    final lease = _lifecycle.acquire(_accountId, generation: _generation);
    final backendOperation = _beginBackendOperation();
    try {
      try {
        final result = await _runInBackendOperation(backendOperation, action);
        await _settleBackend(backendOperation);
        lease.ensureOpen();
        return result;
      } catch (e) {
        if (e is AccountCacheClosedException) rethrow;
        throw CacheOperationException(operation);
      }
    } finally {
      lease.release();
    }
  }

  Stream<T> _stream<T>(String operation, Stream<T> Function() create) {
    final lease = _lifecycle.acquire(_accountId, generation: _generation);
    final backendOperation = _beginBackendOperation();
    final controller = StreamController<T>();
    StreamSubscription<T>? subscription;
    final sourceSettled = Completer<void>();
    final bufferedFileInfos = <T>[];
    Future<void>? backendSettlement;
    var released = false;
    var listened = false;
    var sourceFailed = false;

    void release() {
      if (released) return;
      released = true;
      lease.release();
    }

    void markSourceSettled() {
      if (!sourceSettled.isCompleted) sourceSettled.complete();
    }

    Future<void> settleBackend() =>
        backendSettlement ??= _settleBackend(backendOperation);

    controller.onListen = () {
      if (listened) return;
      listened = true;
      if (lease.wasClosed) {
        unawaited(controller.close());
        release();
        return;
      }
      Stream<T> source;
      try {
        source = _callInBackendOperation(backendOperation, create);
      } catch (e) {
        if (e is AccountCacheClosedException) {
          controller.addError(e);
        } else {
          controller.addError(CacheOperationException(operation));
        }
        unawaited(controller.close());
        release();
        return;
      }
      final shared = source.asBroadcastStream();
      subscription = _callInBackendOperation(
        backendOperation,
        () => shared.listen(
          (value) {
            if (lease.wasClosed || controller.isClosed) return;
            if (value is FileInfo) {
              // WebHelper emits FileInfo before its intentionally unawaited
              // metadata update completes. Hold that success until the tracked
              // repository has settled, so a failed metadata commit cannot be
              // presented as a usable stream result.
              bufferedFileInfos.add(value);
            } else {
              controller.add(value);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            sourceFailed = true;
            bufferedFileInfos.clear();
            if (controller.isClosed) return;
            controller.addError(
              lease.wasClosed
                  ? AccountCacheClosedException()
                  : CacheOperationException(operation),
            );
          },
          onDone: () async {
            markSourceSettled();
            Object? settlementError;
            StackTrace? settlementStack;
            try {
              // A source error still leaves the cache backend free to finish
              // an already-admitted metadata write. Do not release the
              // lifecycle lease until that handoff settles, even when the
              // output error has already been delivered.
              await settleBackend();
            } catch (error, stackTrace) {
              settlementError = error is CacheOperationException
                  ? error
                  : CacheOperationException(operation);
              settlementStack = error is CacheOperationException
                  ? stackTrace
                  : StackTrace.current;
            }
            if (settlementError != null && !sourceFailed) {
              bufferedFileInfos.clear();
              if (!controller.isClosed) {
                controller.addError(
                  settlementError,
                  settlementStack ?? StackTrace.current,
                );
              }
            } else if (!sourceFailed &&
                !lease.wasClosed &&
                !controller.isClosed) {
              for (final value in bufferedFileInfos) {
                controller.add(value);
              }
            }
            bufferedFileInfos.clear();
            await controller.close();
            release();
          },
        ),
      );
      // Keep a passive subscription so a failed cancellation cannot make the
      // source's later close invisible. The source is drained while removal
      // is closed, and the lease is released only after that signal.
      _callInBackendOperation(
        backendOperation,
        () => shared.listen(
          (_) {},
          onError: (Object _, StackTrace _) {},
          onDone: markSourceSettled,
        ),
      );
    };
    // The source is deliberately drained rather than cancelled on consumer
    // cancellation. A cache backend may still be committing a file after its
    // subscription is cancelled; the purge must wait for source completion.
    controller.onCancel = () {};
    Future<void> finishAfterSource() async {
      try {
        await sourceSettled.future;
        await settleBackend();
      } catch (_) {
        lease.reportRemovalFailure();
      }
      if (!controller.isClosed) unawaited(controller.close());
      release();
    }

    lease.onRemoval(() async {
      if (subscription == null) {
        // A lazy stream can be admitted and returned without ever acquiring a
        // source subscription. Closing its controller waits for a listener
        // that may never arrive, so releasing this lease is the complete
        // quiescence proof.
        release();
        return;
      }
      try {
        await sourceSettled.future.timeout(_lifecycle.removalTimeout);
        await settleBackend();
      } on TimeoutException {
        // Return a bounded failure to removal, but keep this lease active until
        // the source's independent completion signal proves quiescence.
        lease.reportRemovalFailure();
        if (!controller.isClosed) unawaited(controller.close());
        unawaited(finishAfterSource());
        return;
      } catch (_) {
        lease.reportRemovalFailure();
        if (!controller.isClosed) unawaited(controller.close());
        unawaited(finishAfterSource());
        return;
      }
      if (!controller.isClosed) unawaited(controller.close());
      release();
    });
    return controller.stream;
  }

  @override
  Future<file.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => _run(
    'getSingleFile',
    () => _manager.getSingleFile(
      _safeUrl(url),
      key: _safeKey(key, url),
      headers: _requestHeaders(url, headers),
    ),
  );

  @override
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => _stream(
    'getFile',
    () => _manager
        .getFileStream(
          _safeUrl(url),
          key: _safeKey(key, url),
          headers: _requestHeaders(url, headers),
        )
        .where((response) => response is FileInfo)
        .cast<FileInfo>(),
  );

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => _stream(
    'getFileStream',
    () => _manager.getFileStream(
      _safeUrl(url),
      key: _safeKey(key, url),
      headers: _requestHeaders(url, headers),
      withProgress: withProgress,
    ),
  );

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) => _run(
    'downloadFile',
    () => _manager.downloadFile(
      _safeUrl(url),
      key: _safeKey(key, url),
      authHeaders: _requestHeaders(url, authHeaders),
      force: force,
    ),
  );

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) => _run(
    'getFileFromCache',
    () => _manager.getFileFromCache(
      _safeKey(key, key),
      ignoreMemCache: ignoreMemCache,
    ),
  );

  @override
  Future<FileInfo?> getFileFromMemory(String key) => _run(
    'getFileFromMemory',
    () => _manager.getFileFromMemory(_safeKey(key, key)),
  );

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => _run(
    'putFile',
    () => _manager.putFile(
      _safeUrl(url),
      redactCacheBytes(fileBytes),
      key: _safeKey(key, url),
      // ETags are durable cache metadata. Do not retain caller- or
      // server-supplied values because a credential can be used as one.
      eTag: null,
      maxAge: maxAge,
      fileExtension: 'file',
    ),
  );

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => _run(
    'putFileStream',
    () => _manager.putFileStream(
      _safeUrl(url),
      _redactedSource(source),
      key: _safeKey(key, url),
      eTag: null,
      maxAge: maxAge,
      fileExtension: 'file',
    ),
  );

  @override
  Future<void> removeFile(String key) =>
      _run('removeFile', () => _manager.removeFile(_safeKey(key, key)));

  Stream<List<int>> _redactedSource(Stream<List<int>> source) =>
      redactCacheStream(source);

  @override
  Future<void> emptyCache() => _run('emptyCache', _manager.emptyCache);

  @override
  Future<void> dispose() => _run('dispose', _manager.dispose);
}

final AccountImageCacheManager plankaImageCacheManager =
    AccountImageCacheManager(lifecycle: accountCacheLifecycle);

class _LifecycleFile extends file.ForwardingFileSystemEntity<file.File, io.File>
    with file.ForwardingFile {
  _LifecycleFile(
    this._fileSystem,
    this._delegate,
    this._lifecycle,
    this._accountId,
    this._generation,
  );

  final file.FileSystem _fileSystem;
  final io.File _delegate;
  final AccountCacheLifecycle _lifecycle;
  final String _accountId;
  final int _generation;

  @override
  file.FileSystem get fileSystem => _fileSystem;

  @override
  io.File get delegate => _delegate;

  @override
  _LifecycleFile wrap(io.File delegate) => _wrap(delegate);

  @override
  file.File wrapFile(io.File delegate) => _wrap(delegate);

  @override
  file.Directory wrapDirectory(io.Directory delegate) =>
      _fileSystem.directory(delegate.path);

  @override
  file.Link wrapLink(io.Link delegate) => _fileSystem.link(delegate.path);

  _LifecycleFile _wrap(io.File delegate) => _LifecycleFile(
    _fileSystem,
    delegate,
    _lifecycle,
    _accountId,
    _generation,
  );

  AccountCacheLease _acquire() =>
      _lifecycle.acquire(_accountId, generation: _generation);

  Future<T> _withLease<T>(Future<T> Function() operation) async {
    final lease = _acquire();
    try {
      final result = await operation();
      lease.ensureOpen();
      return result;
    } finally {
      lease.release();
    }
  }

  void _withLeaseSync(void Function() operation) {
    final lease = _acquire();
    try {
      operation();
      lease.ensureOpen();
    } finally {
      lease.release();
    }
  }

  @override
  Future<file.File> create({bool recursive = false, bool exclusive = false}) =>
      _withLease(
        () async => wrap(
          await delegate.create(recursive: recursive, exclusive: exclusive),
        ),
      );

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    _withLeaseSync(() {
      delegate.createSync(recursive: recursive, exclusive: exclusive);
    });
  }

  @override
  Future<file.File> copy(String newPath) =>
      _withLease(() async => wrap(await delegate.copy(newPath)));

  @override
  file.File copySync(String newPath) =>
      _withLeaseSyncResult(() => wrap(delegate.copySync(newPath)));

  @override
  Future<file.File> rename(String newPath) =>
      _withLease(() async => wrap(await delegate.rename(newPath)));

  @override
  file.File renameSync(String newPath) =>
      _withLeaseSyncResult(() => wrap(delegate.renameSync(newPath)));

  @override
  Future<file.File> delete({bool recursive = false}) => _withLease(
    () async => wrap(await delegate.delete(recursive: recursive) as io.File),
  );

  @override
  void deleteSync({bool recursive = false}) {
    _withLeaseSync(() {
      delegate.deleteSync(recursive: recursive);
    });
  }

  T _withLeaseSyncResult<T>(T Function() operation) {
    final lease = _acquire();
    try {
      final result = operation();
      lease.ensureOpen();
      return result;
    } finally {
      lease.release();
    }
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
  }) {
    final lease = _acquire();
    try {
      final sink = delegate.openWrite(mode: mode, encoding: encoding);
      final consumer = _LifecycleSinkConsumer(
        sink,
        lease,
        _lifecycle.removalTimeout,
      );
      final guarded = io.IOSink(consumer, encoding: encoding);
      consumer.attach(guarded);
      return guarded;
    } catch (_) {
      lease.release();
      rethrow;
    }
  }

  @override
  Future<file.File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) => _withLease(
    () async =>
        wrap(await delegate.writeAsBytes(bytes, mode: mode, flush: flush)),
  );

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    _withLeaseSync(() {
      delegate.writeAsBytesSync(bytes, mode: mode, flush: flush);
    });
  }

  @override
  Future<file.File> writeAsString(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => _withLease(
    () async => wrap(
      await delegate.writeAsString(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      ),
    ),
  );

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _withLeaseSync(() {
      delegate.writeAsStringSync(
        contents,
        mode: mode,
        encoding: encoding,
        flush: flush,
      );
    });
  }
}

class _LifecycleSinkConsumer implements StreamConsumer<List<int>> {
  _LifecycleSinkConsumer(this._delegate, this._lease, this._removalTimeout);

  final io.IOSink _delegate;
  final AccountCacheLease _lease;
  final Duration _removalTimeout;
  Future<void>? _active;
  var _released = false;

  void attach(io.IOSink owner) {
    unawaited(
      owner.done.then<void>(
        (_) => _releaseAfterDelegateDone(),
        onError: (Object _, StackTrace _) => _releaseAfterDelegateDone(),
      ),
    );
    _lease.onRemoval(_closeForRemoval);
  }

  Future<void> _releaseAfterDelegateDone() async {
    try {
      await _delegate.done;
    } catch (_) {
      // The delegate has still settled, even when it reports the same write
      // failure as the owner sink.
    }
    _release();
  }

  void _release() {
    if (_released) return;
    _released = true;
    _lease.release();
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final operation = _addStream(stream);
    _active = operation;
    return operation.whenComplete(() {
      if (identical(_active, operation)) _active = null;
    });
  }

  Future<void> _addStream(Stream<List<int>> stream) async {
    await _delegate.addStream(
      stream.map((chunk) {
        _lease.ensureOpen();
        return chunk;
      }),
    );
    _lease.ensureOpen();
  }

  @override
  Future<void> close() async {
    try {
      await _delegate.close();
      _lease.ensureOpen();
    } finally {
      _release();
    }
  }

  Future<void> _closeForRemoval() async {
    final active = _active;
    if (active != null) {
      try {
        await active.timeout(_removalTimeout);
      } on TimeoutException {
        _lease.reportRemovalFailure();
        // The bounded removal attempt has failed, but the sink lease remains
        // until this admitted operation settles and the delegate is closed.
        unawaited(_finishAfterActive(active));
        return;
      } catch (_) {
        // The underlying add/flush operation has settled with an error. Its
        // future is the quiescence proof, so close the sink before releasing.
      }
    }
    await _closeDelegateForRemoval();
  }

  Future<void> _finishAfterActive(Future<void> active) async {
    try {
      await active;
    } catch (_) {
      // A failed write is settled; the delegate still needs closing before
      // this lease can be released.
    }
    await _closeDelegateForRemoval();
  }

  Future<void> _closeDelegateForRemoval() async {
    try {
      await _delegate.close();
    } catch (_) {
      // A sink can report the close error through either close() or done. The
      // latter is the quiescence proof; do not release until it settles.
      try {
        await _delegate.done.timeout(_removalTimeout);
      } on TimeoutException {
        _lease.reportRemovalFailure();
        return;
      } catch (_) {
        // An errored done future still proves that the delegate is settled.
      }
    }
    _release();
  }
}

class _AccountDirectoryFileSystem implements FileSystem {
  _AccountDirectoryFileSystem(
    this._directory,
    this._accountId,
    this._lifecycle,
    this._generation,
  );

  final Future<file.Directory> _directory;
  final String _accountId;
  final AccountCacheLifecycle _lifecycle;
  final int _generation;

  Future<file.Directory> get directory => _directory;

  @override
  Future<file.File> createFile(String name) async {
    final safeName = _safeRelativePath(name);
    var canCreateDirectory = true;
    try {
      final lease = _lifecycle.acquire(_accountId, generation: _generation);
      lease.release();
    } on AccountCacheClosedException {
      // Cache Manager calls createFile outside its save try/catch. Return a
      // guarded handle for a closed generation so openWrite reports the
      // rejection inside that catch instead of leaking an async error.
      canCreateDirectory = false;
    }
    final directory = await _directory;
    if (canCreateDirectory) await directory.create(recursive: true);
    return _LifecycleFile(
      directory.fileSystem,
      directory.childFile(safeName) as io.File,
      _lifecycle,
      _accountId,
      _generation,
    );
  }

  Future<file.File> rawFile(String name) async {
    final safeName = _safeRelativePath(name);
    final directory = await _directory;
    return directory.childFile(safeName);
  }
}

/// Prevents cache metadata from escaping the configured cache directory via a
/// crafted relative path. The third-party cache manager treats this value as a
/// path, so validate it before delegating on every supported platform.
class _SafeFileSystem implements FileSystem {
  _SafeFileSystem(this._delegate);

  final FileSystem _delegate;

  @override
  Future<file.File> createFile(String name) =>
      _delegate.createFile(_safeRelativePath(name));
}

FileSystem _rawFileSystem(FileSystem fileSystem) =>
    fileSystem is _SafeFileSystem ? fileSystem._delegate : fileSystem;

String _safeRelativePath(String name) {
  final normalized = p.normalize(name);
  if (p.isAbsolute(name) ||
      normalized == '..' ||
      normalized.startsWith('..${p.separator}')) {
    throw ArgumentError.value(name, 'relativePath');
  }
  return normalized;
}

/// The `Authorization` header value for token auth. Single source for the REST
/// interceptor, the accept-terms call, and the socket handshake.
String bearerAuth(String token) {
  registerSecret(token);
  return 'Bearer $token';
}

class PlankaApi {
  /// A self-hosted Planka over a home network or VPN can accept the TCP
  /// handshake and then never send a byte; an unbounded client sits there
  /// forever, and on the login screen that is a spinner with no way back.
  /// Every request through this client therefore gets a finite connect bound.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// The receive bound is an *idle* bound, not a total transfer deadline: it
  /// fires only when no bytes arrive for the whole window, so a large
  /// attachment over a poor connection that keeps making progress survives.
  static const Duration receiveTimeout = Duration(seconds: 10);

  final String serverUrl;
  String? token;
  late final Dio dio;

  /// Called once per 401 on an authenticated request (session expiry).
  final void Function()? onUnauthorized;

  PlankaApi(this.serverUrl, this.token, {this.onUnauthorized}) {
    registerSecret(token);
    dio = Dio(
      BaseOptions(
        baseUrl: '$serverUrl/api',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = token;
          if (t != null) options.headers['Authorization'] = bearerAuth(t);
          handler.next(options);
        },
      ),
    );
  }

  Future<String> login(String emailOrUsername, String password) async {
    final res = await _request(
      () => dio.post<Map<String, dynamic>>(
        '/access-tokens',
        data: {'emailOrUsername': emailOrUsername, 'password': password},
      ),
    );
    // A fresh server answers this with 403 {step:accept-terms} — surfaced as
    // TermsRequiredException from _request, so we never reach here in that case.
    final item = res['item'];
    if (item is! String) {
      throw ApiException(null, 'Unexpected login response');
    }
    token = item;
    registerSecret(item);
    return item;
  }

  /// Accept the server's Terms of Service using the [pendingToken] from a
  /// [TermsRequiredException]. The accept-terms endpoint returns a real access
  /// token, which this stores and returns — no re-login needed.
  Future<String> acceptTerms(String pendingToken) async {
    registerSecret(pendingToken);
    final opts = Options(headers: {'Authorization': bearerAuth(pendingToken)});
    final terms = await _request(
      () => dio.get<Map<String, dynamic>>('/terms', options: opts),
    );
    final signature = (terms['item'] as Map?)?['signature'];
    if (signature is! String) {
      throw ApiException(null, 'Unexpected terms response');
    }
    final res = await _request(
      () => dio.post<Map<String, dynamic>>(
        '/access-tokens/accept-terms',
        data: {'pendingToken': pendingToken, 'signature': signature},
      ),
    );
    final item = res['item'];
    // Same rule as verifyTotp: a server echoing the pending token back as the
    // access token would have signIn persist the pending token as the account
    // credential. Both continuation steps refuse it.
    if (item is! String || item == pendingToken) {
      throw ApiException(null, 'Unexpected accept-terms response');
    }
    token = item;
    registerSecret(item);
    return item;
  }

  /// Completes a two-factor login. [code] is a TOTP code or a recovery code —
  /// the server decides which it accepted, so nothing here may judge its shape.
  ///
  /// [pendingToken] is passed per call and is never assigned to [token]: only
  /// the real access token this returns is, so no response shape can leave the
  /// pending token sitting in the field that [CurrentAccountNotifier.signIn]
  /// persists.
  ///
  /// Deliberately bypasses [_request]: the server's 401/403 distinction has to
  /// survive to the caller, and neither the server's `message` nor the pending
  /// token may reach a user-visible string.
  Future<String> verifyTotp(String pendingToken, String code) async {
    registerSecret(pendingToken);
    final Response<Map<String, dynamic>> res;
    try {
      res = await dio.post<Map<String, dynamic>>(
        '/access-tokens/verify-totp',
        data: {'pendingToken': pendingToken, 'code': code},
      );
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 403:
          throw TotpCodeRejectedException();
        case 401:
          // Not onUnauthorized: there is no session to expire yet, so this must
          // never be mistaken for the signed-in session dying.
          throw TotpPendingTokenExpiredException();
      }
      // e.message describes the transport, never the response body — the body
      // could echo the pending token straight into a snackbar.
      throw ApiException(e.response?.statusCode, e.message ?? 'Request failed');
    }
    final item = (res.data ?? const {})['item'];
    // Refusing an item equal to the pending token is what makes ruling 1 total:
    // a server that echoes it back would otherwise have signIn persist the
    // pending token itself as the account credential.
    if (item is! String || item == pendingToken) {
      throw ApiException(null, 'Unexpected verify-totp response');
    }
    token = item;
    registerSecret(item);
    return item;
  }

  Future<void> logout() async {
    await _request(() => dio.delete<Map<String, dynamic>>('/access-tokens/me'));
    token = null;
  }

  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse(
        await _request(
          () => dio.get<Map<String, dynamic>>(path, queryParameters: query),
        ),
      );

  Future<Envelope> post(String path, Object? body) async => Envelope.parse(
    await _request(() => dio.post<Map<String, dynamic>>(path, data: body)),
  );

  Future<Envelope> patch(String path, Object? body) async => Envelope.parse(
    await _request(() => dio.patch<Map<String, dynamic>>(path, data: body)),
  );

  Future<Envelope> delete(String path) async => Envelope.parse(
    await _request(() => dio.delete<Map<String, dynamic>>(path)),
  );

  /// Downloads a server file (attachment download endpoint — root-level, not
  /// under /api, and cookie-authenticated like images) to [savePath].
  Future<void> download(String urlPath, String savePath) async {
    final t = token;
    if (t == null) throw ApiException(401, 'Not signed in');
    final url = '$serverUrl$urlPath';
    final headers = imageAuthHeaders(t, serverUrl: serverUrl, imageUrl: url);
    if (headers == null) {
      throw ApiException(null, 'Invalid download URL');
    }
    try {
      await dio.download(
        url,
        savePath,
        options: Options(headers: headers, followRedirects: false),
      );
    } on DioException catch (e) {
      // Same session-expiry handling as _request: 401 with a token means the
      // session died, so kick off the re-login flow.
      if (e.response?.statusCode == 401) onUnauthorized?.call();
      throw ApiException(
        e.response?.statusCode,
        e.message ?? 'Download failed',
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    try {
      final res = await send();
      return res.data ?? const {};
    } on DioException catch (e) {
      final data = e.response?.data;
      // Login answers 403 {step, pendingToken} when it needs one more thing
      // before issuing a token: a fresh server wants its terms accepted, a 2FA
      // account wants a code. Neither is a failure — the caller continues.
      //
      // The status gate matters: without it any error carrying a `step` field
      // is read as a continuation, so a 401 that really means the session
      // expired would raise one of these instead of reaching onUnauthorized
      // below, and the session-expiry landing would never fire.
      if (e.response?.statusCode == 403 && data is Map) {
        final pendingToken = data['pendingToken'];
        if (pendingToken is String) {
          switch (data['step']) {
            case 'accept-terms':
              throw TermsRequiredException(pendingToken);
            case 'verify-totp':
              throw TotpRequiredException(pendingToken);
          }
        }
      }
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : e.message ?? 'Request failed';
      // 401 with a token = expired session; 401 without = bad credentials.
      if (e.response?.statusCode == 401 && token != null) {
        onUnauthorized?.call();
      }
      throw ApiException(e.response?.statusCode, message);
    }
  }
}
