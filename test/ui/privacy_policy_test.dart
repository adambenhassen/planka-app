import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/ui/login_screen.dart';
import 'package:planka_app/ui/privacy_policy.dart';
import 'package:url_launcher/url_launcher.dart';

Widget _app(PrivacyPolicyLauncher launcher) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LoginScreen(privacyPolicyLauncher: launcher),
  ),
);

void main() {
  testWidgets('privacy policy launches in the external browser', (
    tester,
  ) async {
    Uri? openedUri;
    LaunchMode? openedMode;
    await tester.pumpWidget(
      _app((uri, mode) async {
        openedUri = uri;
        openedMode = mode;
        return true;
      }),
    );

    await tester.tap(find.text('Privacy policy'));
    await tester.pump();

    expect(openedUri, Uri.parse(privacyPolicyUrl));
    expect(openedMode, LaunchMode.externalApplication);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed launch shows a retryable localized message', (
    tester,
  ) async {
    var attempts = 0;
    Future<bool> launcher(Uri _, LaunchMode _) async {
      attempts++;
      return attempts > 1;
    }
    await tester.pumpWidget(_app(launcher));

    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(find.text('Could not open privacy policy.'), findsOneWidget);

    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(attempts, 2);
  });

  testWidgets('a launcher exception shows the same failure message', (
    tester,
  ) async {
    Future<bool> launcher(Uri _, LaunchMode _) async {
      throw StateError('no browser');
    }
    await tester.pumpWidget(_app(launcher));

    await tester.tap(find.text('Privacy policy'));
    await tester.pump();

    expect(find.text('Could not open privacy policy.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('privacy policy exposes one localized button semantics node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app((_, _) async => true));

    final action = find.widgetWithText(TextButton, 'Privacy policy');
    final data = tester.getSemantics(action).getSemanticsData();
    expect(data.label, 'Privacy policy');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    semantics.dispose();
  });

  testWidgets('privacy policy can be activated from the keyboard', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app((_, _) async {
        attempts++;
        return true;
      }),
    );

    for (var i = 0; i < 10 && attempts == 0; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
    }

    expect(attempts, 1);
  });
}
