import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

/// Shapes/status codes below mirror a live Planka 2.x fresh server (observed
/// against ghcr.io/plankanban/planka: login → 403 accept-terms step, and
/// accept-terms → 200 {item: token}).
void main() {
  late HttpServer server;
  late PlankaApi api;
  String? termsAuthHeader;
  Map<String, dynamic>? acceptBody;

  setUp(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final path = req.uri.path;
      final raw = await utf8.decoder.bind(req).join();
      req.response.headers.contentType = ContentType.json;
      if (path == '/api/access-tokens' && req.method == 'POST') {
        req.response.statusCode = 403;
        req.response.write('{"code":"E_FORBIDDEN",'
            '"message":"Terms acceptance required",'
            '"step":"accept-terms","pendingToken":"pt1"}');
      } else if (path == '/api/terms' && req.method == 'GET') {
        termsAuthHeader = req.headers.value('authorization');
        req.response.write('{"item":{"signature":"sig1"}}');
      } else if (path == '/api/access-tokens/accept-terms' &&
          req.method == 'POST') {
        acceptBody = jsonDecode(raw) as Map<String, dynamic>;
        req.response.write('{"item":"realtok"}');
      } else {
        req.response.statusCode = 404;
        req.response.write('{"message":"not found"}');
      }
      await req.response.close();
    });
    api = PlankaApi('http://127.0.0.1:${server.port}', null);
  });

  tearDown(() => server.close());

  test('fresh-server login (403) surfaces the accept-terms step', () async {
    await expectLater(
      api.login('demo@demo.demo', 'demo'),
      throwsA(isA<TermsRequiredException>()
          .having((e) => e.pendingToken, 'pendingToken', 'pt1')),
    );
  });

  test('acceptTerms signs with the pending token and returns the token',
      () async {
    final token = await api.acceptTerms('pt1');
    expect(termsAuthHeader, 'Bearer pt1');
    expect(acceptBody, {'pendingToken': 'pt1', 'signature': 'sig1'});
    expect(token, 'realtok');
    expect(api.token, 'realtok');
  });
}
