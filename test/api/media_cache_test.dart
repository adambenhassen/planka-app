import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const accountA = 'https://planka.example#user';
  const accountB = 'https://planka.example#user2';
  const imageUrl = 'https://planka.example/media/shared.png';

  test(
    'same media URL is stored separately and survives another purge',
    () async {
      final directory = await Directory.systemTemp.createTemp('media_cache');
      addTearDown(() => directory.delete(recursive: true));
      final cache = AccountImageCacheManager(directory: directory);
      final managerA = cache.forAccount(accountA);
      final managerB = cache.forAccount(accountB);
      final keyA = plankaImageCacheKey(accountA, imageUrl);
      final keyB = plankaImageCacheKey(accountB, imageUrl);

      expect(managerA, isNot(same(managerB)));
      expect(keyA, isNot(keyB));
      expect(keyA, isNot(contains('access-token')));

      await managerA.putFile(
        imageUrl,
        Uint8List.fromList('A'.codeUnits),
        key: keyA,
      );
      await managerB.putFile(
        imageUrl,
        Uint8List.fromList('B'.codeUnits),
        key: keyB,
      );
      expect(await managerA.getFileFromCache(keyA, ignoreMemCache: true),
          isNotNull);
      expect(await managerB.getFileFromCache(keyB, ignoreMemCache: true),
          isNotNull);
      await cache.dispose();

      final purge = AccountImageCacheManager(directory: directory);
      await purge.purgeAccount(accountA);

      final reconstructed = AccountImageCacheManager(directory: directory);
      final reconstructedA = reconstructed.forAccount(accountA);
      final reconstructedB = reconstructed.forAccount(accountB);
      expect(await reconstructedA.getFileFromCache(keyA), isNull);
      expect(
        await (await reconstructedB.getFileFromCache(
          keyB,
        ))!.file.readAsString(),
        'B',
      );

      await reconstructed.dispose();
    },
  );
}
