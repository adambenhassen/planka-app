import 'dart:async';

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
import 'package:planka_app/ui/privacy_policy.dart';

/// Distinctive so an assertion can scan the whole store for it.
const _pendingToken = 'pt-secret-must-never-persist';

/// An account with two-factor authentication on: the password is accepted, then
/// login always demands a code. Each verifyTotp call consumes one queued
/// outcome — an access token, or the exception the server would have caused.
class TotpApi extends PlankaApi {
  TotpApi(super.serverUrl, super.token, {required this.outcomes});

  final List<Object> outcomes;
  final verifyCalls = <(String, String)>[];
  int loginCalls = 0;

  /// When set, a request blocks on it — lets a test hold one call in flight
  /// while it tries to start a second. Calls are counted before they block, so
  /// a leaked second request shows up even though neither has returned.
  Completer<void>? gate;

  @override
  Future<String> login(String emailOrUsername, String password) async {
    loginCalls++;
    final g = gate;
    if (g != null) await g.future;
    throw TotpRequiredException(_pendingToken);
  }

  @override
  Future<String> verifyTotp(String pendingToken, String code) async {
    verifyCalls.add((pendingToken, code));
    final g = gate;
    if (g != null) await g.future;
    final outcome = outcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    token = outcome as String;
    return token!;
  }

  /// Fails the profile fetch that `signIn` makes after a code is accepted —
  /// the stand-in for anything that can throw between a spent code and the
  /// projects screen (a 500, or a keychain write the store rejects).
  bool failProfile = false;

  /// When set, the profile fetch blocks on it — lets a test hold finalization
  /// open (between an accepted code and the projects screen) long enough to
  /// poke at the UI from inside the window.
  Completer<void>? profileGate;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final g = profileGate;
    if (g != null) await g.future;
    if (failProfile) throw ApiException(500, 'Profile fetch failed');
    return Envelope.parse({
      'item': {'id': 'u1', 'name': 'Demo', 'username': 'demo'}
    });
  }
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

  /// Every client the login flow built. A second `_submit` would build a second
  /// one, so counting logins across all of them is what proves no login was
  /// started twice — `api` alone would silently follow the newest instance.
  late List<TotpApi> apis;

  int totalLogins() => apis.fold(0, (sum, a) => sum + a.loginCalls);

  Widget app(List<Object> outcomes,
      {Completer<void>? gate, PrivacyPolicyLauncher? privacyPolicyLauncher}) {
    storage = MemStorage();
    apis = [];
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(
          path: '/login',
          builder: (_, _) => LoginScreen(
              privacyPolicyLauncher: privacyPolicyLauncher)),
      GoRoute(
          path: '/projects',
          builder: (_, _) => const Scaffold(body: Text('PROJECTS'))),
    ]);
    return ProviderScope(
      overrides: [
        apiFactoryProvider.overrideWithValue((url) {
          api = TotpApi(url, null, outcomes: outcomes)..gate = gate;
          apis.add(api);
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
    expect(find.text('Privacy policy'), findsOneWidget);
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

  testWidgets('Enter cannot start a second verification while one is in flight',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final gate = Completer<void>();
    api.gate = gate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    final field = find.widgetWithText(TextFormField, 'Authentication code');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    // `done` unfocuses the field, so a second Enter needs the caret back in it
    // first. That is a plain user action and nothing about it waits for the
    // request still in flight.
    await tester.showKeyboard(field);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Two Enter presses, one request against the pending token.
    expect(api.verifyCalls, [(_pendingToken, '123456')]);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.verifyCalls, [(_pendingToken, '123456')]);
    expect(find.text('PROJECTS'), findsOneWidget);
    expectNoPendingTokenStored();
  });

  testWidgets('Enter cannot start a second login while one is in flight',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(app(['realtok'], gate: gate));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'), 'http://x');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or username'), 'demo@d.d');
    final password = find.widgetWithText(TextFormField, 'Password');
    await tester.enterText(password, 'pw');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.showKeyboard(password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // One login in flight, and no second client built to carry another.
    expect(totalLogins(), 1);
    expect(apis, hasLength(1));

    gate.complete();
    await tester.pumpAndSettle();
    expect(totalLogins(), 1);
    // The single login still lands on the code step as usual.
    expect(find.text('Two-factor authentication'), findsOneWidget);
  });

  testWidgets('privacy policy stays enabled while login is loading',
      (tester) async {
    final gate = Completer<void>();
    Uri? openedUri;
    await tester.pumpWidget(app(
      ['realtok'],
      gate: gate,
      privacyPolicyLauncher: (uri, _) async {
        openedUri = uri;
        return true;
      },
    ));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'), 'http://x');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or username'), 'demo@d.d');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'pw');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    await tester.tap(find.text('Privacy policy'));
    await tester.pump();
    expect(openedUri, Uri.parse(privacyPolicyUrl));

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Two-factor authentication'), findsOneWidget);
  });

  testWidgets('cancelling during an in-flight verification never signs in',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final gate = Completer<void>();
    api.gate = gate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    await tester.tap(find.text('Verify'));
    // Deliberately no pump: Cancel is still enabled in this frame, so the
    // cancel lands while the verification is in flight. The submit captured
    // its own client and pending token and would otherwise carry them past
    // the cancel and sign the user in anyway.
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    // The request went out and cannot be unsent, but nothing may come of it.
    expect(api.verifyCalls, hasLength(1));
    expect(find.text('PROJECTS'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(storage.data['accounts'], isNull);
    expectNoPendingTokenStored();
  });

  testWidgets('a cancelled step shows no rejected-code message afterwards',
      (tester) async {
    await reachCodeStep(tester, [TotpCodeRejectedException()]);
    final gate = Completer<void>();
    api.gate = gate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '000000');

    await tester.tap(find.text('Verify'));
    await tester.tap(find.text('Cancel')); // same frame, while in flight
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    // The step the rejection belonged to is gone, so its message must not
    // land on the credentials step the user is now looking at.
    expect(find.text('That code was rejected. Try again.'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
  });

  testWidgets('a cancelled step does not clear a password typed after it',
      (tester) async {
    await reachCodeStep(tester, [TotpPendingTokenExpiredException()]);
    final gate = Completer<void>();
    api.gate = gate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    await tester.tap(find.text('Verify'));
    await tester.tap(find.text('Cancel')); // same frame, while in flight
    await tester.pump();

    // Back on credentials, the user starts over and types a password.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'newpw');

    gate.complete();
    await tester.pumpAndSettle();

    // The expiry belongs to a step that was already cancelled; it must not
    // wipe what the user has typed since.
    expect(fieldTexts(tester), ['http://x', 'demo@d.d', 'newpw']);
    expect(find.text('Sign-in timed out. Enter your password again.'),
        findsNothing);
  });

  testWidgets('a failure after a valid code is still reported', (tester) async {
    await reachCodeStep(tester, ['realtok']);
    api.failProfile = true;
    await submitCode(tester, '123456');

    // The code is spent and the user is back on credentials, so being told
    // nothing is the worst outcome. This is the one branch reachable after
    // our own _clearPending(), which is what made it easy to suppress.
    expect(find.text('Profile fetch failed'), findsOneWidget);
    expect(find.text('PROJECTS'), findsNothing);
    expect(storage.data['accounts'], isNull);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a cancelled step raises no error snackbar afterwards',
      (tester) async {
    await reachCodeStep(
        tester, [ApiException(null, 'Unexpected verify-totp response')]);
    final gate = Completer<void>();
    api.gate = gate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    await tester.tap(find.text('Verify'));
    await tester.tap(find.text('Cancel')); // same frame, while in flight
    await tester.pump();

    gate.complete();
    await tester.pumpAndSettle();

    // Third branch of the same rule: a step the user cancelled produces no
    // effect on screen, errors included.
    expect(find.text('Unexpected verify-totp response'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
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

  testWidgets(
      'a stale cancel during finalization is inert and login still completes',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final gate = Completer<void>();
    final profileGate = Completer<void>();
    api.gate = gate;
    api.profileGate = profileGate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    // Capture the Cancel callback while the step is idle — before
    // verification resolves. It is the "stale" callback the fix must
    // neutralize: it reads the step's state at call time, so invoking it
    // during finalization must reach _cancelCode with _finalizing already set.
    final staleCancel = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
        .onPressed;
    expect(staleCancel, isNotNull);

    await tester.tap(find.text('Verify'));
    // Hold the verification in flight so the screen is still on the code step.
    await tester.pump();

    gate.complete();
    await tester.pump(); // verification accepted; finalization now in flight,
                         // the profile fetch held by profileGate

    // Vacuity assertion: the captured callback is real and reaches the
    // handler.
    staleCancel!();
    await tester.pump();

    // The cancel demonstrably ran, but the accepted flow is untouched: still
    // on the code step, visibly finalizing, not back on credentials.
    expect(find.text('Two-factor authentication'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsNothing);
    expect(find.text('PROJECTS'), findsNothing);
    expect(storage.data['accounts'], isNull);

    // Finalization finishes on its own: profile fetch, upsert, select, then
    // the projects screen with the accepted account selected and stored.
    profileGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(storage.data['accounts'], contains('realtok'));
    expectNoPendingTokenStored();
  });

  /// Taps Verify and pumps a bounded number of frames. Used while a gate is
  /// holding finalization open: the indeterminate spinner animates forever, so
  /// `pumpAndSettle` (as in [submitCode]) would time out.
  Future<void> tapVerify(WidgetTester tester) async {
    await tester.tap(find.text('Verify'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('the code step stays visibly finalizing until the account is stored',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final profileGate = Completer<void>();
    api.profileGate = profileGate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');
    await tapVerify(tester);

    // Still on the code step, loading, before the profile fetch, the upsert
    // and the selection have finished.
    expect(find.text('Two-factor authentication'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('PROJECTS'), findsNothing);
    expect(storage.data['accounts'], isNull);

    profileGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(storage.data['accounts'], contains('realtok'));
    expectNoPendingTokenStored();
  });

  testWidgets('a fresh cancel cannot land while finalization is in flight',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final profileGate = Completer<void>();
    api.profileGate = profileGate;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');
    await tapVerify(tester);

    // While the accepted flow is finalizing the Cancel button is inert: a
    // held frame, a queued gesture or an OS back press cannot reach a live
    // handler, and the handler itself refuses to act.
    final cancel = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
        .onPressed;
    expect(cancel, isNull);
    expect(find.text('Two-factor authentication'), findsOneWidget);
    expect(storage.data['accounts'], isNull);

    profileGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(storage.data['accounts'], contains('realtok'));
    expectNoPendingTokenStored();
  });

  testWidgets('a stale cancel during finalization cannot hide a post-acceptance failure',
      (tester) async {
    await reachCodeStep(tester, ['realtok']);
    final gate = Completer<void>();
    final profileGate = Completer<void>();
    api.gate = gate;
    api.profileGate = profileGate;
    api.failProfile = true;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Authentication code'), '123456');

    // Stale Cancel, captured while the step is idle, before finalization.
    final staleCancel = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
        .onPressed;
    expect(staleCancel, isNotNull);

    await tester.tap(find.text('Verify'));
    await tester.pump();

    gate.complete();
    await tester.pump(); // accepted; the profile fetch is held, about to fail

    staleCancel!(); // vacuity: the callback demonstrably ran
    await tester.pump();

    profileGate.complete();
    await tester.pumpAndSettle();

    // The failure of an already-accepted sign-in remains visible: not
    // swallowed as if the step had been cancelled, not a silent no-op.
    expect(find.text('Profile fetch failed'), findsOneWidget);
    expect(find.text('PROJECTS'), findsNothing);
    expect(storage.data['accounts'], isNull);
    expectNoPendingTokenStored();
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
