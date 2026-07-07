import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';

class FakeStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
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
    final b = Account.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    expect(b.id, a.id);
    expect(b.token, 'jwt');
    expect(b.displayName, 'Demo');
  });

  test('AccountStore save/load', () async {
    final store = AccountStore(FakeStorage());
    final a = Account(
        serverUrl: 'https://x', token: 't', userId: 'u', displayName: 'D');
    await store.save([a]);
    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, a.id);
  });

  test('AccountStore load empty', () async {
    expect(await AccountStore(FakeStorage()).load(), isEmpty);
  });

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
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
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
