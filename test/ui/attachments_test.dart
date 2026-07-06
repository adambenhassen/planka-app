import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
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
  PlankaAttachment attachment(String id, String name) => PlankaAttachment(
      id: id, cardId: 'c1', type: 'file', name: name); // data null → no thumb

  Widget host({
    List<PlankaAttachment> attachments = const [],
    required void Function(String path, String name) onUpload,
    void Function(String id) onDelete = _noop,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: CardAttachmentsSection(
            attachments: attachments,
            token: 'tok',
            onUpload: onUpload,
            onDelete: onDelete,
          ),
        ),
      );

  testWidgets('picking a file uploads it with path and name', (tester) async {
    FileSelectorPlatform.instance =
        _FakeSelector(XFile('/tmp/report.pdf', name: 'report.pdf'));
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
    await tester.pumpWidget(host(
      attachments: [attachment('a1', 'spec.txt')],
      onUpload: (_, _) {},
      onDelete: (id) => deleted = id,
    ));

    expect(find.text('spec.txt'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete attachment'));
    expect(deleted, 'a1');
  });
}

void _noop(String _) {}
