import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../api/envelope.dart';

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
}
