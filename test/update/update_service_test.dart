import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/update/update_service.dart';

void main() {
  group('isNewerVersion', () {
    test('greater major/minor/patch', () {
      expect(isNewerVersion('1.1.0', '1.0.0'), isTrue);
      expect(isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });
    test('equal or older is not newer', () {
      expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0', '1.1.0'), isFalse);
      expect(isNewerVersion('1.0', '1.0.0'), isFalse);
    });
  });

  group('checkForUpdate', () {
    late HttpServer server;
    String body = '';
    int status = 200;

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      server.listen((req) async {
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        req.response.write(body);
        await req.response.close();
      });
    });
    tearDown(() => server.close());

    String url() => 'http://127.0.0.1:${server.port}/latest';

    test('newer release with apk asset → UpdateInfo', () async {
      body = '{"tag_name":"v1.2.0","html_url":"http://x/rel",'
          '"assets":[{"name":"app-release.apk","browser_download_url":"http://x/app.apk"}]}';
      final info = await checkForUpdate(currentVersion: '1.0.0', url: url());
      expect(info, isNotNull);
      expect(info!.version, '1.2.0');
      expect(info.url, 'http://x/app.apk');
      expect(info.isApk, isTrue);
    });

    test('same version → null', () async {
      body = '{"tag_name":"v1.0.0","assets":[]}';
      expect(await checkForUpdate(currentVersion: '1.0.0', url: url()), isNull);
    });

    test('newer but no apk asset → falls back to release page', () async {
      body = '{"tag_name":"v1.2.0","html_url":"http://x/rel","assets":[]}';
      final info = await checkForUpdate(currentVersion: '1.0.0', url: url());
      expect(info!.url, 'http://x/rel');
      expect(info.isApk, isFalse);
    });

    test('server error → null (fails soft)', () async {
      status = 404;
      body = '{"message":"Not Found"}';
      expect(await checkForUpdate(currentVersion: '1.0.0', url: url()), isNull);
    });
  });
}
