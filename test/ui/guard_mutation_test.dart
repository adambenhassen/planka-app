import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/ui/error_handling.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ),
  ));
  return ctx;
}

void main() {
  testWidgets('guardMutation surfaces a rejected future via a SnackBar',
      (tester) async {
    final ctx = await _pumpHost(tester);

    guardMutation(ctx, Future<void>.error(Exception('boom')));
    await tester.pump(); // reject the future
    await tester.pump(); // animate the SnackBar in

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('guardMutation stays silent when the future succeeds',
      (tester) async {
    final ctx = await _pumpHost(tester);

    guardMutation(ctx, Future<void>.value());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
