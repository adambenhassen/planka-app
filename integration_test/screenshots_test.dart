import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/main.dart';

const _url =
    String.fromEnvironment('PLANKA_URL', defaultValue: 'http://localhost:3000');
const _email =
    String.fromEnvironment('PLANKA_EMAIL', defaultValue: 'demo@demo.demo');
const _password = String.fromEnvironment('PLANKA_PASSWORD', defaultValue: 'demo');

/// Keychain needs signing entitlements not present in dev builds.
class MemStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Captures README screenshots against a seeded dev Planka (dev/seed_demo.sh).
/// Run:
///   flutter drive --driver=test_driver/screenshots_driver.dart \
///     --target=integration_test/screenshots_test.dart -d "iPhone 16 Pro"
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Simulator builds are always debug; hide the DEBUG banner for captures.
  WidgetsApp.debugAllowBannerOverride = false;

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (tester.any(finder)) return;
    }
    final texts =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    fail('Timed out waiting for $finder; visible texts: $texts');
  }

  Future<void> shot(WidgetTester tester, String name) async {
    // Keep pumping real frames so network images (backgrounds, covers,
    // avatars) finish loading before the capture.
    final until = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(until)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('capture README screenshots', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        accountStoreProvider.overrideWithValue(AccountStore(MemStorage())),
      ],
      child: const PlankaApp(),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'), _url);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or username'), _email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), _password);
    // Submit from the password field: the on-screen keyboard can cover the
    // button on a real device/simulator, making a tap on it unreliable. Some
    // iPad simulator keyboard configurations do not deliver the action, so
    // fall back to the button only while the credentials screen is still up.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    if (tester.any(find.text('Log in'))) {
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log in'));
    }

    await pumpUntilFound(tester, find.text('Product Launch'),
        timeout: const Duration(seconds: 40));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await shot(tester, 'projects');

    await tester.ensureVisible(find.text('Roadmap').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roadmap').first);
    await pumpUntilFound(tester, find.text('Design onboarding flow'));
    await shot(tester, 'board');

    // The card is in the second horizontally scrolling board list. The card's
    // own vertical ListView is the nearest scrollable to the finder, so
    // ensureVisible() cannot reveal the list itself.
    final horizontalScroll = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    );
    await tester.drag(horizontalScroll, const Offset(-400, 0));
    await tester.pumpAndSettle();
    final cardTile = find.ancestor(
      of: find.text('Design onboarding flow'),
      matching: find.byType(Card),
    );
    await tester.tap(cardTile.first);
    await pumpUntilFound(tester, find.text('Checklists'));
    await shot(tester, 'card');

    // Close sheet, back to projects, open notifications.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await pumpUntilFound(tester, find.text('Product Launch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await pumpUntilFound(tester, find.text('Notifications'));
    await shot(tester, 'notifications');
  });
}
