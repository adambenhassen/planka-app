import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../api/envelope.dart';
import '../cache_lifecycle.dart';
import '../cache_purge.dart';
import '../security_redaction.dart';

final envelopeCacheProvider = Provider<EnvelopeCache>(
  (_) => EnvelopeCache(lifecycle: accountCacheLifecycle),
);

/// Offline read cache: the last successful response envelope per key, stored
/// as a JSON file. Keys must include the account id so accounts on different
/// servers never see each other's data.
/// ponytail: plain JSON files, no expiry — stale data beats a blank screen,
/// and every online fetch overwrites it; move to a real DB if boards get huge.
class EnvelopeCache {
  EnvelopeCache({Directory? directory, AccountCacheLifecycle? lifecycle})
    : _override = directory,
      _lifecycle = lifecycle ?? AccountCacheLifecycle();

  final Directory? _override;
  final AccountCacheLifecycle _lifecycle;

  Future<File> _file(String key) async {
    final base = await _baseDirectory();
    final bucket = _bucketForKey(key);
    final dir = Directory('${base.path}/envelope_cache/$bucket');
    await dir.create(recursive: true);
    // A digest is intentionally one-way: account URLs, user IDs, and any
    // accidental credential in a caller-provided key never become metadata.
    final safe = sha256.convert(utf8.encode(key));
    return File('${dir.path}/$safe.json');
  }

  Future<File> _invalidationFile(String key) async {
    final base = await _baseDirectory();
    final dir = Directory(
      '${base.path}/envelope_cache_invalidations/${_bucketForKey(key)}',
    );
    await dir.create(recursive: true);
    final safe = sha256.convert(utf8.encode(key));
    return File('${dir.path}/$safe.invalidated');
  }

  Future<File> _deletionIntentFile(String key) async {
    final base = await _baseDirectory();
    final dir = Directory(
      '${base.path}/envelope_cache_delete_intents/${_bucketForKey(key)}',
    );
    await dir.create(recursive: true);
    final safe = sha256.convert(utf8.encode(key));
    return File('${dir.path}/$safe.pending');
  }

  Future<File> _failClosedFile(String key) async {
    final base = await _baseDirectory();
    final dir = Directory(
      '${base.path}/envelope_cache_fail_closed/${_bucketForKey(key)}',
    );
    await dir.create(recursive: true);
    final safe = sha256.convert(utf8.encode(key));
    return File('${dir.path}/$safe.failed');
  }

  Future<Directory> _baseDirectory() async =>
      _override ?? await getApplicationSupportDirectory();

  String _bucketForKey(String key) {
    final accountId = _lifecycle.accountIdForKey(key);
    return accountId == null
        ? 'unscoped'
        : 'account-${sha256.convert(utf8.encode(accountId))}';
  }

  Future<void> put(String key, Envelope env) async {
    final lease = _lifecycle.acquireForKey(key);
    try {
      await _putWithLease(key, env, lease);
      lease.ensureOpen();
    } finally {
      lease.release();
    }
  }

  Future<Envelope?> get(String key) async {
    final lease = _lifecycle.acquireForKey(key);
    try {
      final env = await _getWithLease(key, lease);
      lease.ensureOpen();
      return env;
    } finally {
      lease.release();
    }
  }

  /// Removes the cached copy for [key]. Used when a known-stale entry must
  /// not be served as the last good copy (a mutation landed but its
  /// confirming refresh failed, so the cached value is pre-mutation).
  Future<void> delete(String key) async {
    final lease = _lifecycle.acquireForKey(key);
    Object? firstFailure;
    StackTrace? firstFailureStack;
    void recordFailure(Object error, StackTrace stackTrace) {
      firstFailure ??= error;
      firstFailureStack ??= stackTrace;
    }

    try {
      // Record the removal intent before touching either representation. If
      // one delete and the normal invalidation marker fail together, this
      // independent durable marker keeps both live and cold readers from
      // serving the stale envelope.
      File? intent;
      File? failClosed;
      try {
        intent = await _deletionIntentFile(key);
        await intent.writeAsString('');
        if (!await intent.exists()) {
          throw StateError('Envelope deletion intent was not persisted');
        }
      } catch (e, _) {
        if (e is AccountCacheClosedException) rethrow;
        // A malformed or unwritable .pending path cannot be the fail-closed
        // record. Keep a separate durable marker before touching either
        // envelope representation, and verify that marker independently.
        try {
          failClosed = await _failClosedFile(key);
          await failClosed.writeAsString('');
          if (!await failClosed.exists()) {
            throw StateError('Envelope fail-closed marker was not persisted');
          }
        } catch (fallbackError, fallbackStack) {
          if (fallbackError is AccountCacheClosedException) rethrow;
          recordFailure(fallbackError, fallbackStack);
          lease.ensureOpen();
          throw CachePurgeException(
            'envelopes',
            firstFailure!,
            firstFailureStack ?? StackTrace.current,
          );
        }
      }
      final files = <File>[];
      try {
        files.add(await _file(key));
      } catch (e, s) {
        if (e is AccountCacheClosedException) rethrow;
        recordFailure(e, s);
      }
      try {
        files.add(await _legacyFile(key));
      } catch (e, s) {
        if (e is AccountCacheClosedException) rethrow;
        recordFailure(e, s);
      }
      for (final file in files) {
        try {
          if (await file.exists()) await file.delete();
        } catch (e, s) {
          if (e is AccountCacheClosedException) rethrow;
          recordFailure(e, s);
        }
        try {
          if (await file.exists()) {
            recordFailure(
              StateError('Envelope cache target remains'),
              StackTrace.current,
            );
          }
        } catch (e, s) {
          recordFailure(e, s);
        }
      }
      try {
        final invalidation = await _invalidationFile(key);
        if (firstFailure != null) {
          await invalidation.writeAsString('');
        } else if (await invalidation.exists()) {
          await invalidation.delete();
        }
      } catch (e, s) {
        if (e is AccountCacheClosedException) rethrow;
        recordFailure(e, s);
      }
      if (firstFailure == null && intent != null) {
        try {
          if (await intent.exists()) await intent.delete();
        } catch (e, s) {
          if (e is AccountCacheClosedException) rethrow;
          recordFailure(e, s);
        }
      }
      if (firstFailure == null && failClosed != null) {
        try {
          if (await failClosed.exists()) await failClosed.delete();
          if (await failClosed.exists()) {
            recordFailure(
              StateError('Envelope fail-closed marker remains'),
              StackTrace.current,
            );
          }
        } catch (e, s) {
          if (e is AccountCacheClosedException) rethrow;
          recordFailure(e, s);
        }
      }
      lease.ensureOpen();
      if (firstFailure != null) {
        throw CachePurgeException(
          'envelopes',
          firstFailure!,
          firstFailureStack ?? StackTrace.current,
        );
      }
    } finally {
      lease.release();
    }
  }

  /// Removes every envelope owned by [accountId] and verifies the same
  /// account namespace while cold, including entries from the old filename
  /// format. Other account namespaces are not inspected or modified.
  Future<void> purgeAccount(String accountId) async {
    try {
      await _lifecycle.beginRemoval(accountId);
    } catch (e, s) {
      throw CachePurgeException('envelopes', e, s);
    }
    Object? firstFailure;
    StackTrace? firstFailureStack;
    Directory? directory;

    try {
      directory = await _directory();
    } catch (e, s) {
      firstFailure = e;
      firstFailureStack = s;
    }

    if (directory != null) {
      final namespace = Directory(
        '${directory.path}/account-${sha256.convert(utf8.encode(accountId))}',
      );
      final invalidationNamespace = Directory(
        '${directory.parent.path}/envelope_cache_invalidations/account-${sha256.convert(utf8.encode(accountId))}',
      );
      final deletionIntentNamespace = Directory(
        '${directory.parent.path}/envelope_cache_delete_intents/account-${sha256.convert(utf8.encode(accountId))}',
      );
      final failClosedNamespace = Directory(
        '${directory.parent.path}/envelope_cache_fail_closed/account-${sha256.convert(utf8.encode(accountId))}',
      );
      try {
        if (await namespace.exists()) await namespace.delete(recursive: true);
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }
      try {
        if (await failClosedNamespace.exists()) {
          await failClosedNamespace.delete(recursive: true);
        }
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }
      try {
        if (await invalidationNamespace.exists()) {
          await invalidationNamespace.delete(recursive: true);
        }
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }
      try {
        if (await deletionIntentNamespace.exists()) {
          await deletionIntentNamespace.delete(recursive: true);
        }
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }

      // Remove entries written by the old reversible filename scheme too.
      // This compatibility path is read-only for new writes.
      try {
        final legacyTargets = <FileSystemEntity>[];
        await for (final entry in directory.list(followLinks: false)) {
          final key = _decodedLegacyKey(entry);
          if (key != null && key.startsWith('$accountId-')) {
            legacyTargets.add(entry);
          }
        }
        await Future.wait(
          legacyTargets.map((target) async {
            try {
              await target.delete();
            } catch (e, s) {
              firstFailure ??= e;
              firstFailureStack ??= s;
            }
          }),
        );
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }

      // Cold verification happens after every delete attempt.
      try {
        if (await namespace.exists() && !await _hasEntries(namespace)) {
          await namespace.delete();
        }
        await for (final entry in directory.list(followLinks: false)) {
          final key = _decodedLegacyKey(entry);
          if (key != null && key.startsWith('$accountId-')) {
            firstFailure ??= StateError('Envelope cache targets remain');
            firstFailureStack ??= StackTrace.current;
          }
        }
        if (await namespace.exists() && await _hasEntries(namespace)) {
          firstFailure ??= StateError('Envelope cache targets remain');
          firstFailureStack ??= StackTrace.current;
        }
        if (await invalidationNamespace.exists() &&
            await _hasEntries(invalidationNamespace)) {
          firstFailure ??= StateError('Envelope invalidations remain');
          firstFailureStack ??= StackTrace.current;
        }
        if (await deletionIntentNamespace.exists() &&
            await _hasEntries(deletionIntentNamespace)) {
          firstFailure ??= StateError('Envelope deletion intents remain');
          firstFailureStack ??= StackTrace.current;
        }
        if (await failClosedNamespace.exists() &&
            await _hasEntries(failClosedNamespace)) {
          firstFailure ??= StateError('Envelope fail-closed markers remain');
          firstFailureStack ??= StackTrace.current;
        }
      } catch (e, s) {
        firstFailure ??= e;
        firstFailureStack ??= s;
      }
    }

    if (firstFailure != null) {
      throw CachePurgeException(
        'envelopes',
        firstFailure!,
        firstFailureStack ?? StackTrace.current,
      );
    }
  }

  /// Fetches via [fetch], caching the result under [key]; on failure falls
  /// back to the cached copy, rethrowing only when there is none.
  Future<Envelope> fetchOrCached(
    String key,
    Future<Envelope> Function() fetch,
  ) async {
    final lease = _lifecycle.acquireForKey(key);
    try {
      try {
        final env = await fetch();
        lease.ensureOpen();
        await _putWithLease(key, env, lease);
        lease.ensureOpen();
        return env;
      } catch (e, s) {
        if (e is AccountCacheClosedException) rethrow;
        final cached = await _getWithLease(key, lease);
        lease.ensureOpen();
        if (cached != null) return cached;
        Error.throwWithStackTrace(e, s);
      }
    } finally {
      lease.release();
    }
  }

  /// Fetches via [fetch] and caches the result, rethrowing on failure. Unlike
  /// [fetchOrCached] there is no fallback to the cached copy: the caller
  /// already knows the cached state is stale (a mutation landed but its
  /// confirming refresh failed, so serving it would be wrong).
  Future<Envelope> fetchAndCache(
    String key,
    Future<Envelope> Function() fetch,
  ) async {
    final lease = _lifecycle.acquireForKey(key);
    try {
      final env = await fetch();
      lease.ensureOpen();
      await _putWithLease(key, env, lease);
      lease.ensureOpen();
      return env;
    } finally {
      lease.release();
    }
  }

  Future<void> _putWithLease(
    String key,
    Envelope env,
    AccountCacheLease lease,
  ) async {
    try {
      final file = await _file(key);
      // Envelope data normally contains board state, not credentials, but the
      // redaction boundary also protects an accidental server echo.
      await file.writeAsString(redactDiagnostic(jsonEncode(env.raw)));
      var invalidationCleared = false;
      try {
        final invalidation = await _invalidationFile(key);
        if (await invalidation.exists()) await invalidation.delete();
        invalidationCleared = true;
      } catch (_) {
        // Leaving an invalidation marker in place is fail-closed: a fresh
        // result may be cached for a later retry, but it will not make a
        // previously invalidated fallback readable.
      }
      if (invalidationCleared) {
        try {
          final intent = await _deletionIntentFile(key);
          if (await intent.exists()) await intent.delete();
        } catch (_) {
          // A pending delete intent is also fail-closed until it can be
          // removed by a later successful cache write or delete.
        }
      }
    } catch (e) {
      if (e is AccountCacheClosedException) rethrow;
      // A failed cache write must never break the fetch that produced it.
    }
    lease.ensureOpen();
  }

  Future<Envelope?> _getWithLease(String key, AccountCacheLease lease) async {
    try {
      final failClosed = await _failClosedFile(key);
      if (await failClosed.exists()) return null;
      final intent = await _deletionIntentFile(key);
      if (await intent.exists()) return null;
      final invalidation = await _invalidationFile(key);
      if (await invalidation.exists()) return null;
      final file = await _file(key);
      File source = file;
      if (!await source.exists()) {
        source = await _legacyFile(key);
        if (!await source.exists()) return null;
      }
      final env = Envelope.parse(
        (jsonDecode(redactDiagnostic(await source.readAsString())) as Map)
            .cast(),
      );
      lease.ensureOpen();
      return env;
    } catch (e) {
      if (e is AccountCacheClosedException) rethrow;
      lease.ensureOpen();
      return null; // Corrupt or unreadable cache entry — treat as a miss.
    }
  }

  Future<Directory> _directory() async {
    final base = await _baseDirectory();
    final dir = Directory('${base.path}/envelope_cache');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _legacyFile(String key) async {
    final directory = await _directory();
    final safe = base64Url.encode(utf8.encode(key));
    return File('${directory.path}/$safe.json');
  }

  String? _decodedLegacyKey(FileSystemEntity entry) {
    final name = entry.uri.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (!name.endsWith('.json')) return null;
    try {
      return utf8.decode(
        base64Url.decode(name.substring(0, name.length - '.json'.length)),
      );
    } on FormatException {
      return null;
    }
  }

  Future<bool> _hasEntries(Directory directory) async {
    await for (final _ in directory.list(recursive: true, followLinks: false)) {
      return true;
    }
    return false;
  }
}
