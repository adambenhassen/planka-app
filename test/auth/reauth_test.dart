import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

void main() {
  test('401 invokes onUnauthorized and throws ApiException', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"code":"E_UNAUTHORIZED","message":"expired"}');
      req.response.close();
    });

    var unauthorizedCalls = 0;
    final api = PlankaApi('http://127.0.0.1:${server.port}', 'stale-token',
        onUnauthorized: () => unauthorizedCalls++);

    await expectLater(
      api.get('/users/me'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
    expect(unauthorizedCalls, 1);
    await server.close();
  });

  test('login 401 does not trigger onUnauthorized', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      req.response.statusCode = 401;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"message":"Invalid credentials"}');
      req.response.close();
    });

    var unauthorizedCalls = 0;
    final api = PlankaApi('http://127.0.0.1:${server.port}', null,
        onUnauthorized: () => unauthorizedCalls++);

    await expectLater(api.login('a', 'b'), throwsA(isA<ApiException>()));
    expect(unauthorizedCalls, 0);
    await server.close();
  });
}
