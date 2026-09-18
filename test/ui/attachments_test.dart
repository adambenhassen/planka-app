import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/ui/card_sections/attachments.dart';

/// Stands in for the native file dialog, which can't be driven in a test.
class _FakeSelector extends FileSelectorPlatform {
  _FakeSelector(this.file);
  final XFile? file;
  int openFileCalls = 0;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    openFileCalls++;
    return file;
  }
}

void main() {
  PlankaAttachment attachment(String id, String name, {String? thumb}) =>
      PlankaAttachment(
        id: id,
        cardId: 'c1',
        type: 'file',
        name: name,
        data: thumb == null
            ? null
            : {
                'thumbnailUrls': {'outside360': thumb},
              },
      );

  Widget host({
    List<PlankaAttachment> attachments = const [],
    required void Function(String path, String name) onUpload,
    void Function(String id) onDelete = _noop,
    String? serverUrl,
    String accountId = 'https://my.planka.test#test-user',
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CardAttachmentsSection(
        attachments: attachments,
        token: 'tok',
        serverUrl: serverUrl,
        accountId: accountId,
        coverAttachmentId: null,
        onUpload: onUpload,
        onDelete: onDelete,
        onSetCover: (_) {},
        onOpen: (_) {},
      ),
    ),
  );

  testWidgets('picking a file uploads it with path and name', (tester) async {
    FileSelectorPlatform.instance = _FakeSelector(
      XFile('/tmp/report.pdf', name: 'report.pdf'),
    );
    (String, String)? uploaded;
    await tester.pumpWidget(host(onUpload: (p, n) => uploaded = (p, n)));

    await tester.tap(find.text('Add attachment'));
    await tester.pump();

    expect(uploaded, ('/tmp/report.pdf', 'report.pdf'));
  });

  testWidgets('cancelling the picker uploads nothing', (tester) async {
    final selector = _FakeSelector(null); // user cancels
    FileSelectorPlatform.instance = selector;
    var uploads = 0;
    await tester.pumpWidget(host(onUpload: (_, _) => uploads++));

    await tester.tap(find.text('Add attachment'));
    await tester.pump();

    expect(selector.openFileCalls, 1);
    expect(uploads, 0);
  });

  testWidgets('existing attachments render and delete by id', (tester) async {
    String? deleted;
    await tester.pumpWidget(
      host(
        attachments: [attachment('a1', 'spec.txt')],
        onUpload: (_, _) {},
        onDelete: (id) => deleted = id,
      ),
    );

    expect(find.text('spec.txt'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 'a1');
  });

  testWidgets('same-origin attachment thumbnail uses cookie auth', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        attachments: [
          attachment(
            'a1',
            'photo.png',
            thumb: 'https://my.planka.test:8443/thumb.png',
          ),
        ],
        serverUrl: 'https://my.planka.test:8443/planka',
        onUpload: (_, _) {},
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.httpHeaders, {'Cookie': 'accessToken=tok'});
  });

  testWidgets('foreign-origin attachment thumbnail renders no image', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        attachments: [
          attachment(
            'a1',
            'photo.png',
            thumb: 'https://my.planka.test.evil.example/thumb.png',
          ),
        ],
        serverUrl: 'https://my.planka.test:8443/planka',
        onUpload: (_, _) {},
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
  });
}

void _noop(String _) {}
