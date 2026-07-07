import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/ui/widgets/prompt_dialog.dart';

/// Renders a button that opens the prompt on tap (not during build, which would
/// mark the Overlay dirty mid-build) and stashes the returned future.
Widget _host(Future<String?> Function(BuildContext) onTap,
        void Function(Future<String?>) capture) =>
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
  testWidgets('promptText returns trimmed value', (tester) async {
    late Future<String?> result;
    await tester.pumpWidget(_host(
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

  testWidgets('promptText returns null on empty input', (tester) async {
    late Future<String?> result;
    await tester.pumpWidget(_host(
      (c) => promptText(c, title: 'Rename', initialValue: 'Old'),
      (f) => result = f,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
