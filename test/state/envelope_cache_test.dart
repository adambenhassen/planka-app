import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/cache_lifecycle.dart';
import 'package:planka_app/security_redaction.dart';
import 'package:planka_app/state/envelope_cache.dart';

void main() {
  late Directory dir;
  late EnvelopeCache cache;
  late AccountCacheLifecycle lifecycle;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('envelope_cache_test');
    lifecycle = AccountCacheLifecycle();
    cache = EnvelopeCache(directory: dir, lifecycle: lifecycle);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Envelope env(String name) => Envelope.parse({
    'item': {'id': '1', 'name': name},
  });

  test('put/get round-trips an envelope', () async {
    await cache.put('k', env('hello'));
    final got = await cache.get('k');
    expect(got!.item['name'], 'hello');
  });

  test('get returns null on a miss and on a corrupt entry', () async {
    expect(await cache.get('missing'), isNull);
    final encoded = base64Url.encode(utf8.encode('bad'));
    File('${dir.path}/envelope_cache/$encoded.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('not json');
    expect(await cache.get('bad'), isNull);
  });

  test(
    'round-trips real account-shaped keys containing a server URL',
    () async {
      const key = 'https://planka.example.com#u1-board-42';
      await cache.put(key, env('board'));
      expect((await cache.get(key))!.item['name'], 'board');
    },
  );

  test('token canaries do not enter envelope files or metadata', () async {
    const token = 'envelope-secret-token-canary';
    registerSecret(token);
    const key = 'https://planka.example#user-projects';
    await cache.put(key, env(token));

    final files = <File>[];
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File) files.add(entry);
    }
    final encoded = base64Url.encode(utf8.encode(token));
    for (final file in files) {
      final contents = await file.readAsString();
      expect(contents, isNot(contains(token)));
      expect(contents, isNot(contains(encoded)));
      expect(file.path, isNot(contains(token)));
      expect(file.path, isNot(contains(encoded)));
    }
  });

  test('fetchOrCached serves the fetch result and caches it', () async {
    final got = await cache.fetchOrCached('k', () async => env('fresh'));
    expect(got.item['name'], 'fresh');
    expect((await cache.get('k'))!.item['name'], 'fresh');
  });

  test('fetchOrCached falls back to the cached copy on failure', () async {
    await cache.put('k', env('stale'));
    final got = await cache.fetchOrCached(
      'k',
      () async => throw Exception('offline'),
    );
    expect(got.item['name'], 'stale');
  });

  test('fetchOrCached rethrows when there is no cached copy', () async {
    expect(
      cache.fetchOrCached('k', () async => throw Exception('offline')),
      throwsException,
    );
  });

  test('fetchAndCache caches the fetch result without falling back', () async {
    await cache.put('k', env('stale'));
    final got = await cache.fetchAndCache('k', () async => env('fresh'));
    expect(got.item['name'], 'fresh');
    expect((await cache.get('k'))!.item['name'], 'fresh');
  });

  test(
    'fetchAndCache rethrows on failure and leaves the cache untouched',
    () async {
      await cache.put('k', env('stale'));
      await expectLater(
        cache.fetchAndCache('k', () async => throw Exception('offline')),
        throwsException,
      );
      expect((await cache.get('k'))!.item['name'], 'stale');
    },
  );

  test(
    'deleting an envelope invalidates current and legacy representations',
    () async {
      const account = 'https://planka.example#user';
      const otherAccount = 'https://planka.example#user2';
      final key = '$account-projects';
      final otherKey = '$otherAccount-projects';
      final stale = env('stale');
      await cache.put(key, stale);
      await cache.put(otherKey, env('other'));

      final legacy =
          File(
              '${dir.path}/envelope_cache/${base64Url.encode(utf8.encode(key))}.json',
            )
            ..createSync(recursive: true)
            ..writeAsStringSync(jsonEncode(stale.raw));

      await cache.delete(key);

      expect(await cache.get(key), isNull);
      final cold = EnvelopeCache(directory: dir);
      expect(await cold.get(key), isNull);
      expect((await cold.get(otherKey))!.item['name'], 'other');
      expect(await legacy.exists(), isFalse);
    },
  );

  test('purges one account by its complete decoded key prefix', () async {
    const account = 'https://planka.example#user';
    const substringAccount = 'https://planka.example#user2';
    final accountKey = '$account-projects';
    final otherKey = '$substringAccount-projects';
    final accountDetailKey = '$account-project-42';
    final exactAccountKey = account;

    await cache.put(accountKey, env('account'));
    await cache.put(otherKey, env('substring'));
    await cache.put(accountDetailKey, env('detail'));
    await cache.put(exactAccountKey, env('exact'));

    await cache.purgeAccount(account);

    final cold = EnvelopeCache(directory: dir);

    expect(await cold.get(accountKey), isNull);
    expect(await cold.get(accountDetailKey), isNull);
    expect((await cold.get(otherKey))!.item['name'], 'substring');
    expect((await cold.get(exactAccountKey))!.item['name'], 'exact');

    final reconstructed = EnvelopeCache(directory: dir);
    expect(await reconstructed.get(accountKey), isNull);
    expect(await reconstructed.get(accountDetailKey), isNull);
    expect((await reconstructed.get(otherKey))!.item['name'], 'substring');
    expect((await reconstructed.get(exactAccountKey))!.item['name'], 'exact');
  });

  test('account purge reports a target that cannot be deleted', () async {
    const account = 'https://planka.example#user';
    const otherAccount = 'https://planka.example#user2';
    final blockedKey = '$account-projects';
    final otherKey = '$otherAccount-projects';
    await cache.put(blockedKey, env('blocked'));
    await cache.put(otherKey, env('other'));

    // Seed the legacy filename so the test exercises upgrade-time purge
    // verification rather than a path that the new writer no longer creates.
    final encoded = base64Url.encode(utf8.encode(blockedKey));
    final blockedFile = File('${dir.path}/envelope_cache/$encoded.json');
    await blockedFile.create(recursive: true);
    await blockedFile.writeAsString('legacy');
    await blockedFile.delete();
    final blockedDirectory = Directory(blockedFile.path);
    await blockedDirectory.create();
    await File('${blockedDirectory.path}/still-present').writeAsString('x');

    await expectLater(cache.purgeAccount(account), throwsException);
    expect(await blockedDirectory.exists(), isTrue);
    expect((await cache.get(otherKey))!.item['name'], 'other');
  });

  test(
    'purge blocks new writes and drains an admitted fetch before cold purge',
    () async {
      const account = 'https://planka.example#user';
      final key = '$account-projects';
      final gate = Completer<void>();
      final pending = cache.fetchOrCached(key, () async {
        await gate.future;
        return env('late');
      });

      final purge = cache.purgeAccount(account);
      expect(
        cache.put(key, env('new')),
        throwsA(isA<AccountCacheClosedException>()),
      );

      gate.complete();
      await expectLater(pending, throwsA(isA<AccountCacheClosedException>()));
      await purge;

      final cold = EnvelopeCache(
        directory: dir,
        lifecycle: AccountCacheLifecycle(),
      );
      expect(await cold.get(key), isNull);
    },
  );

  test(
    'a direct envelope put crossing removal cannot commit after the barrier',
    () async {
      const account = 'https://planka.example#direct-put';
      const otherAccount = 'https://planka.example#other';
      final key = '$account-projects';
      final otherKey = '$otherAccount-projects';
      await cache.put(otherKey, env('other'));

      final pending = cache.put(key, env('late'));
      final removal = cache.purgeAccount(account);

      await expectLater(pending, throwsA(isA<AccountCacheClosedException>()));
      await removal;

      expect((await cache.get(otherKey))!.item['name'], 'other');
      final cold = EnvelopeCache(directory: dir);
      expect(await cold.get(key), isNull);
      expect((await cold.get(otherKey))!.item['name'], 'other');
    },
  );
}
