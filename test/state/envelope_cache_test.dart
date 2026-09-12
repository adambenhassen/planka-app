import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/state/envelope_cache.dart';

void main() {
  late Directory dir;
  late EnvelopeCache cache;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('envelope_cache_test');
    cache = EnvelopeCache(directory: dir);
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

  test('round-trips real account-shaped keys containing a server URL',
      () async {
    const key = 'https://planka.example.com#u1-board-42';
    await cache.put(key, env('board'));
    expect((await cache.get(key))!.item['name'], 'board');
  });

  test('fetchOrCached serves the fetch result and caches it', () async {
    final got = await cache.fetchOrCached('k', () async => env('fresh'));
    expect(got.item['name'], 'fresh');
    expect((await cache.get('k'))!.item['name'], 'fresh');
  });

  test('fetchOrCached falls back to the cached copy on failure', () async {
    await cache.put('k', env('stale'));
    final got =
        await cache.fetchOrCached('k', () async => throw Exception('offline'));
    expect(got.item['name'], 'stale');
  });

  test('fetchOrCached rethrows when there is no cached copy', () async {
    expect(cache.fetchOrCached('k', () async => throw Exception('offline')),
        throwsException);
  });

  test('fetchAndCache caches the fetch result without falling back',
      () async {
    await cache.put('k', env('stale'));
    final got = await cache.fetchAndCache('k', () async => env('fresh'));
    expect(got.item['name'], 'fresh');
    expect((await cache.get('k'))!.item['name'], 'fresh');
  });

  test('fetchAndCache rethrows on failure and leaves the cache untouched',
      () async {
    await cache.put('k', env('stale'));
    await expectLater(
        cache.fetchAndCache('k', () async => throw Exception('offline')),
        throwsException);
    expect((await cache.get('k'))!.item['name'], 'stale');
  });
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

    expect(await cache.get(accountKey), isNull);
    expect(await cache.get(accountDetailKey), isNull);
    expect((await cache.get(otherKey))!.item['name'], 'substring');
    expect((await cache.get(exactAccountKey))!.item['name'], 'exact');

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

    final encoded = base64Url.encode(utf8.encode(blockedKey));
    final blockedFile = File('${dir.path}/envelope_cache/$encoded.json');
    await blockedFile.delete();
    final blockedDirectory = Directory(blockedFile.path);
    await blockedDirectory.create();
    await File('${blockedDirectory.path}/still-present').writeAsString('x');

    await expectLater(cache.purgeAccount(account), throwsException);
    expect(await blockedDirectory.exists(), isTrue);
    expect((await cache.get(otherKey))!.item['name'], 'other');
  });
}
