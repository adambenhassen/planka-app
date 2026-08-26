import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/ui/privacy_policy.dart';

Widget _app(PrivacyPolicyLauncher launcher) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => openPrivacyPolicy(context, launcher: launcher),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('browser-unavailable result shows a retryable failure', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app((_, _) async {
        attempts++;
        return false;
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Could not open privacy policy.'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(attempts, 2);
  });

  testWidgets('launcher exceptions show the same failure instead of escaping', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((_, _) async {
        throw StateError('no browser');
      }),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(find.text('Could not open privacy policy.'), findsOneWidget);
  });
}
