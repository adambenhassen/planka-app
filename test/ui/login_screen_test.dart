import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/ui/login_screen.dart';

class RecordingApi extends PlankaApi {
  RecordingApi(super.serverUrl, super.token);
  final calls = <(String, String)>[];

  @override
  Future<String> login(String emailOrUsername, String password) async {
    calls.add((emailOrUsername, password));
    token = 'jwt-test';
    return 'jwt-test';
  }

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'item': {'id': 'u1', 'name': 'Demo', 'username': 'demo'}
      });
}

/// Fresh server: first login needs terms, then succeeds after acceptTerms.
class TermsApi extends PlankaApi {
  TermsApi(super.serverUrl, super.token);
  int acceptCalls = 0;

  @override
  Future<String> login(String emailOrUsername, String password) async {
    throw TermsRequiredException('pt1');
  }

  @override
  Future<String> acceptTerms(String pendingToken) async {
    acceptCalls++;
    token = 'jwt-test';
    return 'jwt-test';
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
  late RecordingApi api;
  late GoRouter router;

  Widget app() {
    router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: '/projects',
          builder: (_, _) => const Scaffold(body: Text('PROJECTS'))),
    ]);
    return ProviderScope(
      overrides: [
        apiFactoryProvider.overrideWithValue((url) {
          api = RecordingApi(url, null);
          return api;
        }),
        accountStoreProvider.overrideWithValue(AccountStore(MemStorage())),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('login flow records call and navigates', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Server URL'), 'http://x');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email or username'), 'demo@d.d');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'pw');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(api.calls, [('demo@d.d', 'pw')]);
    expect(find.text('PROJECTS'), findsOneWidget);
  });

  group('fresh-server terms step', () {
    late TermsApi termsApi;

    Widget termsApp() {
      router = GoRouter(initialLocation: '/login', routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
            path: '/projects',
            builder: (_, _) => const Scaffold(body: Text('PROJECTS'))),
      ]);
      return ProviderScope(
        overrides: [
          apiFactoryProvider.overrideWithValue((url) {
            termsApi = TermsApi(url, null);
            return termsApi;
          }),
          accountStoreProvider.overrideWithValue(AccountStore(MemStorage())),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.pumpWidget(termsApp());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Server URL'), 'http://x');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or username'), 'demo@d.d');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'pw');
      await tester.tap(find.text('Log in'));
      await tester.pump(); // let login throw and the terms dialog build
      await tester.pump();
    }

    testWidgets('accepting the dialog logs in', (tester) async {
      await fillAndSubmit(tester);
      expect(find.text('Accept Terms of Service?'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(termsApi.acceptCalls, 1);
      expect(find.text('PROJECTS'), findsOneWidget);
    });

    testWidgets('cancelling stays on login without accepting', (tester) async {
      await fillAndSubmit(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(termsApi.acceptCalls, 0);
      expect(find.text('PROJECTS'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Server URL'), findsOneWidget);
    });
  });

  testWidgets('empty fields show Required', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(3));
  });
}
