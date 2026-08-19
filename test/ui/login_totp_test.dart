import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/ui/login_screen.dart';

/// Distinctive so an assertion can scan the whole store for it.
const _pendingToken = 'pt-secret-must-never-persist';

/// An account with two-factor authentication on: the password is accepted, then
/// login always demands a code. Each verifyTotp call consumes one queued
/// outcome — an access token, or the exception the server would have caused.
class TotpApi extends PlankaApi {
  TotpApi(super.serverUrl, super.token, {required this.outcomes});

  final List<Object> outcomes;
  final verifyCalls = <(String, String)>[];

  @override
  Future<String> login(String emailOrUsername, String password) async =>
      throw TotpRequiredException(_pendingToken);

  @override
  Future<String> verifyTotp(String pendingToken, String code) async {
    verifyCalls.add((pendingToken, code));
    final outcome = outcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    token = outcome as String;
    return token!;
  }

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'item': {'id': 'u1', 'name': 'Demo', 'username': 'demo'}
      });
}

class MemStorage implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late TotpApi api;
  late MemStorage storage;

  Widget app(List<Object> outcomes) {
    storage = MemStorage();
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: '/projects',
          builder: (_, _) => const Scaffold(body: Text('PROJECTS'))),
    ]);
    return ProviderScope(
      overrides: [
        apiFactoryProvider.overrideWithValue((url) {
          api = TotpApi(url, null, outcomes: outcomes);
          return api;
        }),
        accountStoreProvider.overrideWithValue(AccountStore(storage)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> reachCodeStep(
      WidgetTester tester, List<Object> outcomes) async {
    await tester.pumpWidget(app(outcomes));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'), 'http://x');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or username'), 'demo@d.d');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'pw');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
  }

  Future<void> submitCode(WidgetTester tester, String code) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), code);
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
  }

  /// The acceptance criterion that holds on every path: whatever the server
  /// answered, the pending token is not in the account store.
  void expectNoPendingTokenStored() {
    expect(storage.data.values.join('|'), isNot(contains(_pendingToken)));
  }

  /// Text of every field currently on screen, in layout order.
  List<String> fieldTexts(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .map((w) => w.controller.text)
      .toList();

  testWidgets('a 2FA account reaches the code step instead of an error',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    expect(find.text('Two-factor authentication'), findsOneWidget);
    // The credentials are replaced, not merely covered.
    expect(find.widgetWithText(TextFormField, 'Password'), findsNothing);
    expect(find.text('PROJECTS'), findsNothing);
    expectNoPendingTokenStored();
  });

  testWidgets('a valid code signs in and stores only the access token',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    await submitCode(tester, '123456');
    expect(api.verifyCalls, [(_pendingToken, '123456')]);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(storage.data['accounts'], contains('realtok'));
    expectNoPendingTokenStored();
  });

  testWidgets('a recovery code is accepted in the same field', (tester) async {
    // Non-numeric and not six characters: no client-side rule may reject it.
    await reachCodeStep(tester, ['realtok']);
    await submitCode(tester, 'abcd-efgh-ijkl');
    expect(api.verifyCalls, [(_pendingToken, 'abcd-efgh-ijkl')]);
    expect(find.text('PROJECTS'), findsOneWidget);
  });

  testWidgets('a rejected code keeps the step and the pending token usable',
      (tester) async {
    await reachCodeStep(tester, [TotpCodeRejectedException(), 'realtok']);
    await submitCode(tester, '000000');

    expect(find.text('That code was rejected. Try again.'), findsOneWidget);
    expect(find.text('Two-factor authentication'), findsOneWidget);
    expect(find.text('PROJECTS'), findsNothing);
    // One request per user action — nothing retried on its own.
    expect(api.verifyCalls.length, 1);
    expectNoPendingTokenStored();

    // The same pending token still buys a token on a second attempt.
    await submitCode(tester, '123456');
    expect(api.verifyCalls, [
      (_pendingToken, '000000'),
      (_pendingToken, '123456'),
    ]);
    expect(find.text('PROJECTS'), findsOneWidget);
    expectNoPendingTokenStored();
  });

  testWidgets('an expired pending token returns to the credentials step',
      (tester) async {
    await reachCodeStep(tester, [TotpPendingTokenExpiredException()]);
    await submitCode(tester, '123456');

    expect(find.text('Sign-in timed out. Enter your password again.'),
        findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Two-factor authentication'), findsNothing);
    expect(find.text('PROJECTS'), findsNothing);
    // Server and identity survive; the password is not cached for a silent
    // re-login, so it has to be typed again.
    expect(fieldTexts(tester), ['http://x', 'demo@d.d', '']);
    expectNoPendingTokenStored();
  });

  testWidgets('cancelling the code step returns to credentials and stores nothing',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Two-factor authentication'), findsNothing);
    expect(api.verifyCalls, isEmpty);
    expectNoPendingTokenStored();
  });

  testWidgets('an empty code is refused without a request', (tester) async {
    await reachCodeStep(tester, ['realtok']);
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(api.verifyCalls, isEmpty);
    expectNoPendingTokenStored();
  });

  testWidgets('an unexpected verify-totp response stores no pending token',
      (tester) async {
    await reachCodeStep(
        tester, [ApiException(null, 'Unexpected verify-totp response')]);
    await submitCode(tester, '123456');

    expect(find.text('PROJECTS'), findsNothing);
    expectNoPendingTokenStored();
    // Let the error snackbar time out so no timer outlives the test.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
