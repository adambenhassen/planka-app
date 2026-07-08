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
}
