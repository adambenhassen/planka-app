import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../api/envelope.dart';
import '../cache_purge.dart';

final envelopeCacheProvider = Provider<EnvelopeCache>((_) => EnvelopeCache());

/// Offline read cache: the last successful response envelope per key, stored
/// as a JSON file. Keys must include the account id so accounts on different
/// servers never see each other's data.
/// ponytail: plain JSON files, no expiry — stale data beats a blank screen,
/// and every online fetch overwrites it; move to a real DB if boards get huge.
class EnvelopeCache {
  EnvelopeCache({Directory? directory}) : _override = directory;
  final Directory? _override;

  Future<File> _file(String key) async {
    final base = _override ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/envelope_cache');
    await dir.create(recursive: true);
    // Keys embed the account id, which contains a server URL — encode so
    // slashes and other unsafe characters can't leak into the path.
    final safe = base64Url.encode(utf8.encode(key));
    return File('${dir.path}/$safe.json');
  }

  Future<void> put(String key, Envelope env) async {
    try {
      await (await _file(key)).writeAsString(jsonEncode(env.raw));
    } catch (_) {
      // A failed cache write (IO error, missing platform support in tests)
      // must never break the fetch that produced it.
    }
  }

  Future<Envelope?> get(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      return Envelope.parse(
          (jsonDecode(await file.readAsString()) as Map).cast());
    } catch (_) {
      return null; // Corrupt or unreadable cache entry — treat as a miss.
    }
  }

  /// Removes the cached copy for [key]. Used when a known-stale entry must
  /// not be served as the last good copy (a mutation landed but its
  /// confirming refresh failed, so the cached value is pre-mutation).
  Future<void> delete(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A failed delete (IO error, missing platform support in tests) must
      // never break the caller; the entry simply stays until overwritten.
    }
  }

  /// Removes every envelope whose decoded logical key starts with
  /// [accountId] followed by a separator. The decoded comparison is
  /// intentional: comparing encoded filenames would make account boundaries
  /// depend on the encoding rather than the cache-key contract.
  Future<void> purgeAccount(String accountId) async {
    final prefix = '$accountId-';
    final directory = await _directory();
    final targets = <FileSystemEntity>[];
    await for (final entry in directory.list(followLinks: false)) {
      final key = _decodedKey(entry);
      if (key != null && key.startsWith(prefix)) targets.add(entry);
    }

    Object? firstFailure;
    StackTrace? firstFailureStack;
    await Future.wait(
      targets.map((target) async {
        try {
          await target.delete();
        } catch (e, s) {
          firstFailure ??= e;
          firstFailureStack ??= s;
        }
      }),
    );

    final remaining = <FileSystemEntity>[];
    await for (final entry in directory.list(followLinks: false)) {
      final key = _decodedKey(entry);
      if (key != null && key.startsWith(prefix)) remaining.add(entry);
    }
    if (firstFailure != null || remaining.isNotEmpty) {
      throw CachePurgeException(
        'envelopes',
        firstFailure ?? StateError('Envelope cache targets remain'),
        firstFailureStack ?? StackTrace.current,
      );
    }
  }

  /// Fetches via [fetch], caching the result under [key]; on failure falls
  /// back to the cached copy, rethrowing only when there is none.
  Future<Envelope> fetchOrCached(
      String key, Future<Envelope> Function() fetch) async {
    try {
      final env = await fetch();
      await put(key, env);
      return env;
    } catch (_) {
      final cached = await get(key);
      if (cached == null) rethrow;
      return cached;
    }
  }

  /// Fetches via [fetch] and caches the result under [key], rethrowing on
  /// failure. Unlike [fetchOrCached] there is no fallback to the cached copy:
  /// the caller already knows the cached state is stale (a mutation landed),
  /// so serving it would be wrong. A successful fetch still refreshes the
  /// cache, so the next offline start sees the post-mutation state.
  Future<Envelope> fetchAndCache(
      String key, Future<Envelope> Function() fetch) async {
    final env = await fetch();
    await put(key, env);
    return env;
  }

  Future<Directory> _directory() async {
    final base = _override ?? await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/envelope_cache');
    await dir.create(recursive: true);
    return dir;
  }

  String? _decodedKey(FileSystemEntity entry) {
    final name = entry.uri.pathSegments
        .lastWhere((segment) => segment.isNotEmpty, orElse: () => '');
    if (!name.endsWith('.json')) return null;
    try {
      return utf8.decode(
        base64Url.decode(name.substring(0, name.length - '.json'.length)),
      );
    } on FormatException {
      return null;
    }
  }
}
