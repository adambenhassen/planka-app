import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/ui/dialogs.dart';

/// Renders a button that, when tapped, opens a dialog via [onTap] and stashes
/// the returned future so the test can await it. Opening on tap (not during
/// build) avoids marking the Overlay dirty mid-build.
Widget _host<T>(Future<T> Function(BuildContext) onTap, void Function(Future<T>) capture) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => capture(onTap(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('confirmDestructive returns true when confirmed', (tester) async {
    late Future<bool> result;
    await tester.pumpWidget(_host<bool>(
      (c) => confirmDestructive(c, title: 'Delete list?', message: 'Gone.'),
      (f) => result = f,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('confirmDestructive returns false on cancel', (tester) async {
    late Future<bool> result;
    await tester.pumpWidget(_host<bool>(
      (c) => confirmDestructive(c, title: 'Delete?', message: 'Gone.'),
      (f) => result = f,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('promptText returns trimmed value, null on empty', (tester) async {
    late Future<String?> result;
    await tester.pumpWidget(_host<String?>(
      (c) => promptText(c, title: 'Rename', initialValue: 'Old'),
      (f) => result = f,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  New  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await result, 'New');
  });
}
