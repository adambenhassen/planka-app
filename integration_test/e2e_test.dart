import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/main.dart';

/// Keychain needs signing entitlements not present in dev builds; the E2E
/// exercises app flows, not secure storage (unit-tested separately).
class MemStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// End-to-end against the local Docker Planka (dev/docker-compose.yml).
/// Run: flutter test integration_test -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (tester.any(finder)) return;
    }
    final texts =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    fail('Timed out waiting for $finder; visible texts: $texts');
  }

  testWidgets('login → projects → board → create card → comment',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountStoreProvider.overrideWithValue(AccountStore(MemStorage())),
      ],
      child: const PlankaApp(),
    ));
    await tester.pumpAndSettle();

    // Login screen (no stored account in fresh test env, or switcher present).
    if (tester.any(find.text('Log in'))) {
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Server URL'),
          'http://localhost:3000');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or username'),
          'demo@demo.demo');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'demo');
      await tester.tap(find.text('Log in'));
    }

    // Projects screen with fixture data.
    await pumpUntilFound(tester, find.text('Fixture Project'));
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Fixture Project'), findsWidgets);

    // Open the fixture board.
    await tester.tap(find.text('Fixture Board').first);
    await pumpUntilFound(tester, find.text('To Do'));

    // Create a card.
    final cardName = 'E2E card ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.text('Add card').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Card name'), cardName);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpUntilFound(tester, find.text(cardName));

    // Open card sheet, add a comment.
    await tester.tap(find.text(cardName));
    await pumpUntilFound(tester, find.text('Comments'));
    final comment = 'e2e comment ${DateTime.now().millisecondsSinceEpoch}';
    await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Write a comment…'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.enterText(
        find.widgetWithText(TextField, 'Write a comment…'), comment);
    await tester.tap(find.byIcon(Icons.send));
    await pumpUntilFound(tester, find.text(comment));
  });
}
