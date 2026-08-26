import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

/// A self-hosted Planka reached over a home network or VPN can accept the TCP
/// handshake and then never send a byte, or dribble an attachment out at one
/// byte a minute. Both are hostile from the client's point of view, so every
/// [PlankaApi] request — including [PlankaApi.download] — runs against
/// [PlankaApi.connectTimeout] and [PlankaApi.receiveTimeout] set on the shared
/// Dio. The receive bound is an idle bound: a slow transfer that keeps making
/// progress must survive it.
void main() {
  group('PlankaApi default transport bounds', () {
    test('connect and receive are both bounded at 10 seconds', () {
      final api = PlankaApi('http://127.0.0.1:1', null);
      expect(api.dio.options.connectTimeout, PlankaApi.connectTimeout);
      expect(api.dio.options.receiveTimeout, PlankaApi.receiveTimeout);
      expect(PlankaApi.connectTimeout, const Duration(seconds: 10));
      expect(PlankaApi.receiveTimeout, const Duration(seconds: 10));
    });
  });

  group('a server that accepts and never answers', () {
    late HttpServer server;

    // The bound is real at 10 s; a short test value keeps the suite fast.
    final bound = const Duration(milliseconds: 500);

    // Margin over the bound for timer scheduling and socket teardown; a
    // multi-second regression in the actual bound must fail this.
    const margin = Duration(seconds: 2);
    final limit = bound + margin;

    setUp(() async {
      // Accepts every connection, reads the request, sends nothing.
      server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        await req.drain<void>();
        // No response headers, no body, then let the request live.
      });
    });

    tearDown(() => server.close(force: true));

    test('get fails within the bound through the sanitized error path',
        () async {
      final api = PlankaApi('http://127.0.0.1:${server.port}', 'sometoken');
      // Shorten the bounds in the test so the suite stays fast; the
      // production values are asserted in the group above.
      api.dio.options.connectTimeout = bound;
      api.dio.options.receiveTimeout = bound;
      final sw = Stopwatch()..start();
      try {
        await api.get('/hang');
        fail('expected the request to time out');
      } on ApiException catch (e) {
        expect(e.statusCode, isNull);
        // The message is the transport description, never response data —
        // there is none here, but the shape must hold either way.
        expect(e.toString(), isNot(contains('sometoken')));
      }
      sw.stop();
      // The failure must come from the bound, not an immediate error: it
      // waited at least the bound and no more than the bound plus margin.
      expect(sw.elapsed, greaterThanOrEqualTo(bound));
      expect(sw.elapsed, lessThan(limit));
      // No session exists here that could be misread as expired.
      expect(api.token, 'sometoken');
    });

    test('a hung login fails within the bound and leaks no credentials',
        () async {
      final api = PlankaApi('http://127.0.0.1:${server.port}', null);
      api.dio.options.connectTimeout = bound;
      api.dio.options.receiveTimeout = bound;
      final sw = Stopwatch()..start();
      try {
        await api.login('demo@demo.demo', 'hunter2-secret');
        fail('expected the request to time out');
      } on ApiException catch (e) {
        expect(e.toString(), isNot(contains('hunter2-secret')));
        expect(e.toString(), isNot(contains('demo@demo.demo')));
      }
      sw.stop();
      expect(sw.elapsed, greaterThanOrEqualTo(bound));
      expect(sw.elapsed, lessThan(limit));
      expect(api.token, isNull);
    });

    test('a hung verification fails within the bound and leaks no token',
        () async {
      final api = PlankaApi('http://127.0.0.1:${server.port}', null);
      api.dio.options.connectTimeout = bound;
      api.dio.options.receiveTimeout = bound;
      final sw = Stopwatch()..start();
      try {
        await api.verifyTotp('pt-hang', '123456');
        fail('expected the request to time out');
      } on ApiException catch (e) {
        expect(e.toString(), isNot(contains('pt-hang')));
        expect(e.toString(), isNot(contains('123456')));
      }
      sw.stop();
      expect(sw.elapsed, greaterThanOrEqualTo(bound));
      expect(sw.elapsed, lessThan(limit));
      expect(api.token, isNull);
    });

    test('a hung download fails within the bound and leaks no token',
        () async {
      final api = PlankaApi('http://127.0.0.1:${server.port}', 'dl-token');
      api.dio.options.connectTimeout = bound;
      api.dio.options.receiveTimeout = bound;
      final sw = Stopwatch()..start();
      try {
        await api.download('/files/1', '/tmp/never-written');
        fail('expected the download to time out');
      } on ApiException catch (e) {
        expect(e.toString(), isNot(contains('dl-token')));
      }
      sw.stop();
      expect(sw.elapsed, greaterThanOrEqualTo(bound));
      expect(sw.elapsed, lessThan(limit));
      expect(File('/tmp/never-written').existsSync(), isFalse);
    });
  });

  group('a slow but progressing download', () {
    late ServerSocket server;

    // The receive bound is an idle bound, not a total transfer deadline:
    // chunks arriving every 150 ms must survive a 300 ms bound even though
    // the whole transfer takes far longer than the bound itself.
    final bound = const Duration(milliseconds: 300);
    final chunk = List<int>.generate(1024, (i) => i & 0xff);
    const chunkCount = 8;

    // A raw-socket server: dart:io's HttpServer buffers response bodies and
    // does not deliver them per flush, so it cannot play a slow stream.
    setUp(() async {
      server = await ServerSocket.bind('127.0.0.1', 0);
      server.listen((socket) async {
        var responding = false;
        socket.listen((data) async {
          if (responding) return;
          responding = true;
          socket.write('HTTP/1.1 200 OK\r\n'
              'Transfer-Encoding: chunked\r\n'
              'Content-Type: application/octet-stream\r\n'
              'Connection: close\r\n\r\n');
          for (var i = 0; i < chunkCount; i++) {
            socket.write('${chunk.length.toRadixString(16)}\r\n');
            socket.add(chunk);
            socket.write('\r\n');
            await socket.flush();
            await Future<void>.delayed(const Duration(milliseconds: 150));
          }
          socket.write('0\r\n\r\n');
          await socket.close();
        });
      });
    });

    tearDown(() => server.close());

    test('completes past the bound and the saved bytes are intact',
        () async {
      final api = PlankaApi('http://127.0.0.1:${server.port}', 'dl-token');
      api.dio.options.connectTimeout = bound;
      api.dio.options.receiveTimeout = bound;
      final dir = Directory.systemTemp.createTempSync('planka-download');
      final path = '${dir.path}/attachment.bin';
      final sw = Stopwatch()..start();
      await api.download('/files/1', path);
      sw.stop();
      // The transfer takes at least 1.05 s — well past the 300 ms bound —
      // and it must still have succeeded.
      expect(sw.elapsed, greaterThan(bound));
      // Validate against the fixed sequence the server sent — never a
      // sequence built from what came back, which a truncated or empty
      // download would also match.
      final expected = List<int>.generate(chunk.length * chunkCount,
          (i) => i & 0xff);
      final saved = File(path).readAsBytesSync();
      expect(saved.length, expected.length);
      expect(saved, expected);
      dir.deleteSync(recursive: true);
    });
  });
}
