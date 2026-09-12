import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/cache_lifecycle.dart';
import 'package:planka_app/cache_purge.dart';
import 'package:planka_app/state/envelope_cache.dart';

class FakeStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class _RecordingEnvelopeCache extends EnvelopeCache {
  _RecordingEnvelopeCache({bool shouldFail = false, int? failuresRemaining})
    : failuresRemaining = failuresRemaining ?? (shouldFail ? 1 : 0);

  int failuresRemaining;
  final purgedAccountIds = <String>[];

  @override
  Future<void> purgeAccount(String accountId) async {
    purgedAccountIds.add(accountId);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('secret-access-token');
    }
  }
}

class _RecordingImageCache extends AccountImageCacheManager {
  _RecordingImageCache({this.failuresRemaining = 0});

  int failuresRemaining;
  final purgedAccountIds = <String>[];

  @override
  Future<void> purgeAccount(String accountId) async {
    purgedAccountIds.add(accountId);
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('secret-access-token');
    }
  }
}

void main() {
  test('Account json round-trip', () {
    final a = Account(
      serverUrl: 'https://p.example.com',
      token: 'jwt',
      userId: 'u1',
      displayName: 'Demo',
    );
    expect(a.id, 'https://p.example.com#u1');
    final b = Account.fromJson(
      jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
    );
    expect(b.id, a.id);
    expect(b.token, 'jwt');
    expect(b.displayName, 'Demo');
  });

  test('AccountStore save/load', () async {
    final store = AccountStore(FakeStorage());
    final a = Account(
      serverUrl: 'https://x',
      token: 't',
      userId: 'u',
      displayName: 'D',
    );
    await store.save([a]);
    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, a.id);
  });

  test('AccountStore load empty', () async {
    expect(await AccountStore(FakeStorage()).load(), isEmpty);
  });

  test('removing an account purges both caches before deleting it', () async {
    final storage = FakeStorage();
    final store = AccountStore(storage);
    final account = Account(
      serverUrl: 'https://p.example.com',
      token: 'secret-access-token',
      userId: 'u1',
      displayName: 'Demo',
    );
    await store.save([account]);
    final envelopes = _RecordingEnvelopeCache();
    final images = _RecordingImageCache();
    final container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        envelopeCacheProvider.overrideWithValue(envelopes),
        imageCacheProvider.overrideWithValue(images),
      ],
    );
    addTearDown(container.dispose);

    await container.read(accountsProvider.future);
    await container.read(accountsProvider.notifier).remove(account.id);

    expect(envelopes.purgedAccountIds, [account.id]);
    expect(images.purgedAccountIds, [account.id]);
    expect(await store.load(), isEmpty);
  });

  test(
    'removal reports purge failure without leaking the token or deleting the account',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://p.example.com',
        token: 'secret-access-token',
        userId: 'u1',
        displayName: 'Demo',
      );
      await store.save([account]);
      final envelopes = _RecordingEnvelopeCache(shouldFail: true);
      final images = _RecordingImageCache();
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(envelopes),
          imageCacheProvider.overrideWithValue(images),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountsProvider.future);
      Object? error;
      try {
        await container.read(accountsProvider.notifier).remove(account.id);
        fail('expected account removal to fail');
      } catch (e) {
        error = e;
      }

      expect(error, isA<CachePurgeException>());
      expect('$error', isNot(contains(account.token)));
      expect(
        (error as CachePurgeException).cause,
        isNot(contains(account.token)),
      );
      expect(envelopes.purgedAccountIds, [account.id]);
      expect(images.purgedAccountIds, [account.id]);
      expect((await store.load()).single.id, account.id);
    },
  );

  test(
    'independent purge failures retain the account and retry idempotently',
    () async {
      final storage = FakeStorage();
      final store = AccountStore(storage);
      final account = Account(
        serverUrl: 'https://retry.example',
        token: 'retry-secret-token',
        userId: 'u1',
        displayName: 'Retry',
      );
      await store.save([account]);
      final envelopes = _RecordingEnvelopeCache(failuresRemaining: 1);
      final images = _RecordingImageCache(failuresRemaining: 1);
      final lifecycle = AccountCacheLifecycle();
      final container = ProviderContainer(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          envelopeCacheProvider.overrideWithValue(envelopes),
          imageCacheProvider.overrideWithValue(images),
          cacheLifecycleProvider.overrideWithValue(lifecycle),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accountsProvider.future);
      await expectLater(
        container.read(accountsProvider.notifier).remove(account.id),
        throwsA(isA<CachePurgeException>()),
      );
      expect(envelopes.purgedAccountIds, [account.id]);
      expect(images.purgedAccountIds, [account.id]);
      expect((await store.load()).single.id, account.id);

      await container.read(accountsProvider.notifier).remove(account.id);
      expect(envelopes.purgedAccountIds, [account.id, account.id]);
      expect(images.purgedAccountIds, [account.id, account.id]);
      expect(await store.load(), isEmpty);
    },
  );

  test('FileKeyValueStore read/write/delete round-trip', () async {
    final dir = await Directory.systemTemp.createTemp('planka_fkv');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = FileKeyValueStore(Directory('${dir.path}/store'));
    expect(await store.read('accounts'), isNull);
    await store.write('accounts', '[{"x":1}]');
    expect(await store.read('accounts'), '[{"x":1}]');
    await store.delete('accounts');
    expect(await store.read('accounts'), isNull);
  });

  test('login returns jwt and sets header', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"item":"jwt-abc"}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', null);
    expect(await api.login('demo@demo.demo', 'demo'), 'jwt-abc');
    await server.close();
  });

  test('non-2xx throws ApiException with statusCode', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"code":"E_UNAUTHORIZED","message":"nope"}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', 'bad');
    await expectLater(
      api.get('/users/me'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
    await server.close();
  });

  test('bearer header sent when token set', () async {
    String? seenAuth;
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      seenAuth = req.headers.value('authorization');
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"item":{"id":"1"}}');
      req.response.close();
    });
    final api = PlankaApi('http://127.0.0.1:${server.port}', 'tok');
    await api.get('/users/me');
    expect(seenAuth, 'Bearer tok');
    await server.close();
  });
}
