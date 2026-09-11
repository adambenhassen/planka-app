import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/main.dart';
import 'package:planka_app/ui/card_sheet.dart';

const _url =
    String.fromEnvironment('PLANKA_URL', defaultValue: 'http://localhost:3000');
const _email =
    String.fromEnvironment('PLANKA_EMAIL', defaultValue: 'demo@demo.demo');
const _password = String.fromEnvironment('PLANKA_PASSWORD', defaultValue: 'demo');
const _loadedCardCoverKey =
    ValueKey<String>('store-capture-loaded-card-cover');
const _loadedAttachmentPrefix = 'store-capture-loaded-attachment:';
const _loadedBackgroundPrefix = 'store-capture-loaded-background-image:';

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
  // A capture must exercise the same hit targets as a user interaction. Do
  // not let an off-screen finder pass while Flutter only reports a warning.
  WidgetController.hitTestWarningShouldBeFatal = true;

  final imageErrors = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('store-capture-image-error');
  });
  final loadedBackgrounds = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith(_loadedBackgroundPrefix);
  });

  void assertNoCaptureError(WidgetTester tester) {
    if (tester.any(find.text('Reconnecting…')) ||
        tester.any(find.byIcon(Icons.wifi_off))) {
      fail('Store capture is not connected: Reconnecting… is visible');
    }
    if (tester.any(imageErrors)) {
      fail('Store capture has a failed network image');
    }
  }

  Future<void> waitForCaptureReady(
    WidgetTester tester, {
    int loadedImages = 0,
    Finder? loadedFinder,
    int? distinctLoadedImages,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final deadline = DateTime.now().add(timeout);
    final loaded = loadedFinder ?? loadedBackgrounds;
    int loadedCount() {
      if (distinctLoadedImages == null) return loaded.evaluate().length;
      return loaded
          .evaluate()
          .map((element) => element.widget.key)
          .whereType<ValueKey<String>>()
          .map((key) => key.value)
          .toSet()
          .length;
    }
    while (DateTime.now().isBefore(deadline)) {
      if (tester.any(imageErrors)) {
        fail('Store capture has a failed network image');
      }
      // A connecting socket briefly renders the banner while the initial
      // request and image loads can already be complete. Keep waiting for the
      // connection edge; shot() turns a later reconnect into a hard failure.
      final connected = !tester.any(find.text('Reconnecting…')) &&
          !tester.any(find.byIcon(Icons.wifi_off));
      if (connected && loadedCount() >= loadedImages) return;
      await tester.pump(const Duration(milliseconds: 200));
    }
    assertNoCaptureError(tester);
    fail('Timed out waiting for $loadedImages loaded store images; found '
        '${loadedCount()}');
  }

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

  Future<void> shot(WidgetTester tester, String name,
      {int loadedImages = 0,
      Finder? loadedFinder,
      int? distinctLoadedImages}) async {
    await waitForCaptureReady(
      tester,
      loadedImages: loadedImages,
      loadedFinder: loadedFinder,
      distinctLoadedImages: distinctLoadedImages,
    );
    // Keep pumping real frames so network images (backgrounds, covers,
    // avatars) finish loading before the capture.
    final until = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(until)) {
      await tester.pump(const Duration(milliseconds: 100));
      assertNoCaptureError(tester);
    }
    assertNoCaptureError(tester);
    await binding.takeScreenshot(name);
  }

  Future<void> submitLoginAndWait(WidgetTester tester) async {
    final productLaunch = find.text('Product Launch');
    final loginButton = find.ancestor(
      of: find.text('Log in'),
      matching: find.byType(FilledButton),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    var attempts = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (tester.any(productLaunch)) return;

      // A simulator can deliver the keyboard dismissal after the first tap.
      // Give the frame a bounded pump, then re-check the live finder before
      // tapping so the retry never targets a stale login tree.
      if (attempts < 3 && tester.any(loginButton)) {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 500));
        if (tester.any(productLaunch)) return;
        if (tester.any(loginButton)) {
          await tester.ensureVisible(loginButton);
          if (tester.any(loginButton)) {
            await tester.tap(loginButton);
            attempts++;
          }
        }
      }

      await tester.pump(const Duration(milliseconds: 200));
    }

    final texts =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    fail('Timed out waiting for $productLaunch; visible texts: $texts');
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
    // Submit through the button after dismissing the simulator keyboard. The
    // iPad simulator does not reliably deliver the password field's done
    // action, and a direct text tap can land outside the button bounds.
    await submitLoginAndWait(tester);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await shot(
      tester,
      'projects',
      loadedImages: 2,
      loadedFinder: loadedBackgrounds,
      distinctLoadedImages: 2,
    );

    // The board tile is inside a non-scrollable GridView nested in the
    // projects ListView. Scroll the owning list explicitly and tap the tile's
    // actual hit target, rather than its overlaid title text.
    final projectsScroll = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ).first;
    final roadmapStack = find.ancestor(
      of: find.text('Roadmap').first,
      matching: find.byType(Stack),
    ).first;
    final roadmapTile = find.descendant(
      of: roadmapStack,
      matching: find.byType(InkWell),
    );
    await tester.scrollUntilVisible(
      roadmapTile,
      300,
      scrollable: projectsScroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(roadmapTile.first);
    await pumpUntilFound(tester, find.text('Design onboarding flow'));
    await waitForCaptureReady(
      tester,
      loadedImages: 1,
      loadedFinder: find.byKey(_loadedCardCoverKey),
    );
    await shot(tester, 'board', loadedImages: 1);

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
      matching: find.byType(InkWell),
    );
    await tester.tap(cardTile.first);
    // The card sheet is a lazy list, so lower sections are not built until
    // its own scrollable is advanced.
    await pumpUntilFound(tester, find.byType(CardSheet));
    final cardSheetScroll = find.descendant(
      of: find.byType(CardSheet),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text('Checklists'),
      400,
      scrollable: cardSheetScroll,
    );
    await pumpUntilFound(tester, find.text('Checklists'));
    await pumpUntilFound(tester, find.text('photo-60.jpg'));
    final loadedAttachment = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value == '${_loadedAttachmentPrefix}photo-60.jpg';
    });
    await shot(
      tester,
      'card',
      loadedImages: 1,
      loadedFinder: loadedAttachment,
    );

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
