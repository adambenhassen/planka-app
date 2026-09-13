import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

void main() {
  test('authenticates media on the configured origin across path prefixes', () {
    expect(
      imageAuthHeaders(
        'jwt',
        serverUrl: 'https://my.planka.test:8443/planka',
        imageUrl: 'https://my.planka.test:8443/media/thumb.png',
      ),
      {'Cookie': 'accessToken=jwt'},
    );
  });

  test('does not authenticate media on a different origin', () {
    const serverUrl = 'https://my.planka.test:8443/planka';
    for (final imageUrl in [
      'https://evil.example/?u=https://my.planka.test:8443',
      'https://my.planka.test.evil.example/thumb.png',
      'https://my.planka.test:9443/thumb.png',
      'http://my.planka.test:8443/thumb.png',
    ]) {
      expect(
        imageAuthHeaders('jwt', serverUrl: serverUrl, imageUrl: imageUrl),
        isNull,
        reason: imageUrl,
      );
    }
  });

  test(
    'attachment downloads keep cookie auth on a server path prefix',
    () async {
      final server = await HttpServer.bind('127.0.0.1', 0);
      String? cookie;
      String? path;
      server.listen((request) async {
        cookie = request.headers.value('cookie');
        path = request.uri.path;
        request.response.write('ok');
        await request.response.close();
      });
      final dir = Directory.systemTemp.createTempSync('planka-image-auth');
      final savePath = '${dir.path}/attachment.bin';
      try {
        final api = PlankaApi('http://127.0.0.1:${server.port}/planka', 'jwt');
        await api.download('/attachments/a1/download/photo.png', savePath);

        expect(cookie, 'accessToken=jwt');
        expect(path, '/planka/attachments/a1/download/photo.png');
        expect(File(savePath).readAsStringSync(), 'ok');
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    },
  );

  test(
    'attachment downloads do not send the cookie after a foreign redirect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      String? redirectedCookie;
      server.listen((request) async {
        final response = request.response;
        if (request.uri.path == '/redirect') {
          response.statusCode = HttpStatus.found;
          response.headers.set(
            HttpHeaders.locationHeader,
            'http://attacker.localhost:${server.port}/stolen',
          );
        } else {
          redirectedCookie = request.headers.value(HttpHeaders.cookieHeader);
          response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
      final dir = Directory.systemTemp.createTempSync('planka-image-auth');
      final savePath = '${dir.path}/attachment.bin';
      try {
        final api = PlankaApi('http://localhost:${server.port}', 'jwt');

        await expectLater(
          api.download('/redirect', savePath),
          throwsA(isA<ApiException>()),
        );
        expect(redirectedCookie, isNull);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    },
  );

  test(
    'cached media does not send the cookie after a foreign redirect',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      String? redirectedCookie;
      server.listen((request) async {
        final response = request.response;
        if (request.uri.path == '/redirect') {
          response.statusCode = HttpStatus.found;
          response.headers.set(
            HttpHeaders.locationHeader,
            'http://attacker.localhost:${server.port}/stolen',
          );
        } else {
          redirectedCookie = request.headers.value(HttpHeaders.cookieHeader);
          response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
      try {
        final response = await plankaImageFileService.get(
          'http://localhost:${server.port}/redirect',
          headers: {'Cookie': 'accessToken=jwt'},
        );
        await response.content.drain<void>();

        expect(response.statusCode, HttpStatus.found);
        expect(redirectedCookie, isNull);
      } finally {
        await server.close(force: true);
      }
    },
  );

  test(
    'authenticated media preserves the complete request URL query',
    () async {
      const token = 'query-token-canary';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seen = <({String path, String query, String? cookie})>[];
      server.listen((request) async {
        seen.add((
          path: request.uri.path,
          query: request.uri.query,
          cookie: request.headers.value(HttpHeaders.cookieHeader),
        ));
        request.response.write('media');
        await request.response.close();
      });
      try {
        final base = 'http://127.0.0.1:${server.port}';
        const paths = [
          '/attachments/a1/thumb.png?token=query-token-canary&size=small',
          '/covers/c1.png?token=query-token-canary&variant=retina',
          '/backgrounds/b1.png?token=query-token-canary&theme=dark',
        ];
        for (final path in paths) {
          final response = await plankaImageFileService.get(
            '$base$path',
            headers: {'Cookie': 'accessToken=$token'},
          );
          await response.content.drain<void>();
        }

        expect(seen, hasLength(paths.length));
        expect(
          seen.map((request) => request.path).toList(),
          paths.map((path) => Uri.parse(path).path).toList(),
        );
        expect(
          seen.map((request) => request.query).toList(),
          paths.map((path) => Uri.parse(path).query).toList(),
        );
        expect(
          seen.map((request) => request.cookie).toList(),
          everyElement('accessToken=$token'),
        );
      } finally {
        await server.close(force: true);
      }
    },
  );
}
