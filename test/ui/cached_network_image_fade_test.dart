import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' as file;
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/ui/card_sections/attachments.dart';
import 'package:planka_app/ui/card_tile.dart';
import 'package:planka_app/ui/theme/app_theme.dart';
import 'package:planka_app/ui/widgets/board_background.dart';

class _AccNotifier extends CurrentAccountNotifier {
  _AccNotifier(this.account);
  final Account? account;

  @override
  Account? build() => account;
}

class _ControlledCacheManager implements BaseCacheManager {
  final _fileSystem = MemoryFileSystem();
  final _requestedPaths = <String>{};
  final _releases = <String, Completer<void>>{};
  final _files = <String, file.File>{};

  String imageUrl(String path) {
    _releases[path] = Completer<void>();
    return 'https://fade.test$path';
  }

  bool wasRequested(String path) => _requestedPaths.contains(path);

  void release(String path) {
    final completer = _releases[path];
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<file.File> _load(String url) async {
    final path = Uri.parse(url).path;
    _requestedPaths.add(path);
    final release = _releases[path];
    if (release == null) throw StateError('unexpected image request $url');
    await release.future;
    final imageFile = _files.putIfAbsent(
      path,
      () => _fileSystem.file('/image-${_files.length}.png'),
    );
    await imageFile.writeAsBytes(_pngBytes);
    return imageFile;
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    final imageFile = await _load(url);
    yield FileInfo(
      imageFile,
      FileSource.Online,
      DateTime.now().add(const Duration(days: 1)),
      url,
    );
  }

  @override
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) =>
      getFileStream(url, key: key, headers: headers).whereType<FileInfo>();

  @override
  Future<file.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async =>
      (await getFileStream(url, key: key, headers: headers)
              .whereType<FileInfo>()
              .first)
          .file;

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async =>
      (await getFileStream(url, key: key, headers: authHeaders)
              .whereType<FileInfo>()
              .first);

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final imageFile = _files[key];
    if (imageFile == null) return null;
    return FileInfo(
      imageFile,
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 1)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) => getFileFromCache(key);

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final file = _fileSystem.file('/put-${_files.length}.$fileExtension');
    await file.writeAsBytes(fileBytes);
    return file;
  }

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final bytes = await source.expand((chunk) => chunk).toList();
    return putFile(
      url,
      Uint8List.fromList(bytes),
      key: key,
      eTag: eTag,
      maxAge: maxAge,
      fileExtension: fileExtension,
    );
  }

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

final _pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');

void main() {
  late _ControlledCacheManager cacheManager;

  setUp(() {
    cacheManager = _ControlledCacheManager();
  });

  testWidgets('all store images fade after a successful load', (tester) async {
    final previousCacheManager =
        CachedNetworkImageProvider.defaultCacheManager;
    CachedNetworkImageProvider.defaultCacheManager = cacheManager;
    addTearDown(() async {
      CachedNetworkImageProvider.defaultCacheManager = previousCacheManager;
      await cacheManager.dispose();
    });

    const cardId = 'card-1';
    const attachmentName = 'cover.png';
    const backgroundPath = '/background.png';
    const cardPath = '/card.png';
    const attachmentPath = '/attachment.png';
    final backgroundUrl = cacheManager.imageUrl(backgroundPath);
    final cardUrl = cacheManager.imageUrl(cardPath);
    final attachmentUrl = cacheManager.imageUrl(attachmentPath);
    final attachment = PlankaAttachment(
      id: 'attachment-1',
      cardId: cardId,
      type: 'file',
      name: attachmentName,
      data: {
        'thumbnailUrls': {
          'outside720': cardUrl,
          'outside360': attachmentUrl,
        },
      },
    );
    final card = PlankaCard(
      id: cardId,
      boardId: 'board-1',
      listId: 'list-1',
      type: 'project',
      name: 'Card',
      coverAttachmentId: attachment.id,
    );
    final state = BoardState(
      board: const PlankaBoard(
        id: 'board-1',
        projectId: 'project-1',
        name: 'Board',
      ),
      lists: const [],
      cards: {card.id: card},
      attachments: [attachment],
    );
    const backgroundGradient = LinearGradient(
      colors: [Colors.blue, Colors.indigo],
    );
    final keys = <String, String>{
      backgroundPath:
          'store-capture-loaded-background-image:$backgroundUrl',
      cardPath: 'store-capture-loaded-card-cover:$cardId',
      attachmentPath:
          'store-capture-loaded-attachment:$attachmentName',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(
            () => _AccNotifier(
              Account(
                serverUrl: 'http://127.0.0.1',
                token: 'token',
                userId: 'user-1',
                displayName: 'User',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    height: 120,
                    child: BoardBackgroundView(
                      background: BoardBackground(
                        backgroundGradient,
                        backgroundUrl,
                      ),
                      token: 'token',
                    ),
                  ),
                  CardTile(card: card, state: state),
                  CardAttachmentsSection(
                    attachments: [attachment],
                    token: 'token',
                    coverAttachmentId: null,
                    onUpload: (_, _) {},
                    onDelete: (_) {},
                    onSetCover: (_) {},
                    onOpen: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (final path in keys.keys) {
      for (var i = 0; i < 500 && !cacheManager.wasRequested(path); i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(cacheManager.wasRequested(path), isTrue, reason: 'request $path');
      expect(find.byKey(ValueKey<String>(keys[path]!)), findsNothing);
    }

    for (final path in keys.keys) {
      cacheManager.release(path);
    }

    for (final key in keys.values) {
      final image = find.byKey(ValueKey<String>(key));
      for (var i = 0; i < 500 && !tester.any(image); i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(image, findsOneWidget, reason: 'loaded image $key');

      final fade = find
          .ancestor(of: image, matching: find.byType(FadeTransition))
          .first;
      await tester.pump(const Duration(milliseconds: 250));
      final halfwayOpacity =
          tester.widget<FadeTransition>(fade).opacity.value;
      expect(halfwayOpacity, greaterThan(0));
      expect(halfwayOpacity, lessThan(1));

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    }
  });
}
