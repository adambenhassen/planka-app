import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

/// Shapes/status codes below mirror a live Planka 2.2 server with two-factor
/// authentication enabled (observed against ghcr.io/plankanban/planka:latest —
/// login → 403 verify-totp step, verify-totp → 200 {item: token}, 403 for a
/// rejected code, 401 for an invalid or expired pending token).
void main() {
  late HttpServer server;
  late PlankaApi api;

  // Per-test knobs for the verify-totp endpoint.
  late int verifyStatus;
  late String verifyBodyJson;
  Map<String, dynamic>? sentBody;
  String? sentAuthHeader;

  setUp(() async {
    verifyStatus = 200;
    verifyBodyJson = '{"item":"realtok"}';
    sentBody = null;
    sentAuthHeader = null;
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final path = req.uri.path;
      final raw = await utf8.decoder.bind(req).join();
      req.response.headers.contentType = ContentType.json;
      if (path == '/api/access-tokens' && req.method == 'POST') {
        req.response.statusCode = 403;
        req.response.write('{"code":"E_FORBIDDEN",'
            '"message":"TOTP verification required",'
            '"step":"verify-totp","pendingToken":"pt1"}');
      } else if (path == '/api/access-tokens/verify-totp' &&
          req.method == 'POST') {
        sentBody = jsonDecode(raw) as Map<String, dynamic>;
        sentAuthHeader = req.headers.value('authorization');
        req.response.statusCode = verifyStatus;
        req.response.write(verifyBodyJson);
      } else {
        req.response.statusCode = 404;
        req.response.write('{"message":"not found"}');
      }
      await req.response.close();
    });
    api = PlankaApi('http://127.0.0.1:${server.port}', null);
  });

  tearDown(() => server.close());

  test('login (403) surfaces the verify-totp step and stores no token',
      () async {
    await expectLater(
      api.login('demo@demo.demo', 'demo'),
      throwsA(isA<TotpRequiredException>()
          .having((e) => e.pendingToken, 'pendingToken', 'pt1')),
    );
    expect(api.token, isNull);
  });

  test('no pending token reaches a user-visible exception string', () {
    // showApiError renders '$error' for anything it does not recognise, so the
    // token must not be reachable through toString on any of these.
    expect(TotpRequiredException('pt1').toString(), isNot(contains('pt1')));
    expect(TotpCodeRejectedException().toString(), isNot(contains('pt1')));
    expect(
        TotpPendingTokenExpiredException().toString(), isNot(contains('pt1')));
  });

  test('verifyTotp posts the pending token and returns the access token',
      () async {
    final token = await api.verifyTotp('pt1', '123456');
    expect(sentBody, {'pendingToken': 'pt1', 'code': '123456'});
    // The pending token is a per-call argument, never the client's credential:
    // no Authorization header goes out, because `token` was still null.
    expect(sentAuthHeader, isNull);
    expect(token, 'realtok');
    expect(api.token, 'realtok');
  });

  test('a recovery code is sent verbatim', () async {
    // Neither six digits nor numeric — nothing may reject it before it is sent.
    await api.verifyTotp('pt1', 'abcd-efgh-ijkl');
    expect(sentBody, {'pendingToken': 'pt1', 'code': 'abcd-efgh-ijkl'});
  });

  test('a rejected code (403) is its own error and stores no token', () async {
    verifyStatus = 403;
    verifyBodyJson = '{"code":"E_FORBIDDEN","message":"Invalid code pt1"}';
    await expectLater(api.verifyTotp('pt1', '000000'),
        throwsA(isA<TotpCodeRejectedException>()));
    expect(api.token, isNull);
  });

  test("a rejected code surfaces neither the server's message nor the token",
      () async {
    verifyStatus = 403;
    verifyBodyJson = '{"code":"E_FORBIDDEN","message":"Invalid code pt1"}';
    try {
      await api.verifyTotp('pt1', '000000');
      fail('expected the code to be rejected');
    } on TotpCodeRejectedException catch (e) {
      expect(e.toString(), isNot(contains('pt1')));
      expect(e.toString(), isNot(contains('Invalid code')));
    }
  });

  test('an expired pending token (401) is its own error and stores no token',
      () async {
    verifyStatus = 401;
    verifyBodyJson = '{"code":"E_UNAUTHORIZED","message":"Expired pt1"}';
    await expectLater(api.verifyTotp('pt1', '123456'),
        throwsA(isA<TotpPendingTokenExpiredException>()));
    expect(api.token, isNull);
  });

  test('a verification 401 is not session expiry', () async {
    // Reaching this state needs no signed-in session, so a rejected pending
    // token must never fire the callback that clears the current account.
    var expired = false;
    final loginApi = PlankaApi('http://127.0.0.1:${server.port}', null,
        onUnauthorized: () => expired = true);
    verifyStatus = 401;
    verifyBodyJson = '{"message":"nope"}';
    await expectLater(loginApi.verifyTotp('pt1', '123456'),
        throwsA(isA<TotpPendingTokenExpiredException>()));
    expect(expired, isFalse);
  });

  test('an unexpected verify-totp response never stores the pending token',
      () async {
    verifyBodyJson = '{"item":{"nested":"unexpected"}}';
    await expectLater(
        api.verifyTotp('pt1', '123456'), throwsA(isA<ApiException>()));
    expect(api.token, isNull);
  });

  test('an unexpected verify-totp response does not leak the token', () async {
    verifyBodyJson = '{"item":{"nested":"pt1"}}';
    try {
      await api.verifyTotp('pt1', '123456');
      fail('expected an ApiException');
    } on ApiException catch (e) {
      expect(e.toString(), isNot(contains('pt1')));
    }
  });
}
