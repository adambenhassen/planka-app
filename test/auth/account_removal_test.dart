import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/account_removal.dart';
import 'package:planka_app/auth/accounts.dart';

class _FakeApi extends PlankaApi {
  _FakeApi(super.serverUrl, super.token, {this.error});

  final Object? error;
  var logoutCalls = 0;
  final started = Completer<void>();
  final release = Completer<void>();
  var waitForRelease = false;

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (!started.isCompleted) started.complete();
    if (waitForRelease) await release.future;
    if (error != null) throw error!;
  }
}

Account _account(String server, String token) => Account(
      serverUrl: server,
      token: token,
      userId: 'user',
      displayName: server,
    );

void main() {
  test('remote revocation uses DELETE and the captured bearer token', () async {
    final requests = <HttpRequest>[];
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((request) {
      requests.add(request);
      request.response.headers.contentType = ContentType.json;
      request.response.write('{}');
      request.response.close();
    });
    addTearDown(() => server.close());

    final target = _account('http://127.0.0.1:${server.port}', 'token-a');
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (account) => PlankaApi(account.serverUrl, account.token),
      removeLocally: (_) async {},
      invalidateProviders: (_) {},
    );

    expect(
      (await coordinator.remove(target)).status,
      AccountRemovalStatus.removed,
    );
    expect(requests, hasLength(1));
    expect(requests.single.method, 'DELETE');
    expect(requests.single.uri.path, '/api/access-tokens/me');
    expect(requests.single.headers.value('authorization'), 'Bearer token-a');
  });

  test('captures the target before account selection changes', () async {
    final target = _account('https://a.example', 'token-a');
    final other = _account('https://b.example', 'token-b');
    _FakeApi? api;
    var selected = target;
    final removed = <String>[];
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (account) {
        expect(account.id, target.id);
        expect(account.token, target.token);
        api = _FakeApi(account.serverUrl, account.token)
          ..waitForRelease = true;
        return api!;
      },
      removeLocally: (accountId) async {
        removed.add(accountId);
        expect(accountId, target.id);
        selected = other;
      },
      invalidateProviders: (accountId) {
        expect(accountId, target.id);
      },
    );

    final removal = coordinator.remove(target);
    await api!.started.future;
    expect(removed, [target.id]);
    selected = other;
    api!.release.complete();

    final result = await removal;
    expect(result.status, AccountRemovalStatus.removed);
    expect(selected, same(other));
    expect(removed, [target.id]);
  });

  test(
    'remote failure still completes local removal and returns a warning result',
    () async {
      final target = _account('https://a.example', 'token-a');
      final api = _FakeApi(
        target.serverUrl,
        target.token,
        error: StateError('server detail'),
      );
      var localCalls = 0;
      final coordinator = AccountRemovalCoordinator(
        apiFactory: (_) => api,
        removeLocally: (_) async => localCalls++,
        invalidateProviders: (_) {},
      );

      final result = await coordinator.remove(target);

      expect(result.status, AccountRemovalStatus.remoteRevocationFailed);
      expect(localCalls, 1);
      expect('$result', isNot(contains('server detail')));
      expect('$result', isNot(contains(target.token)));
    },
  );

  test('remote revocation diagnostics use fixed metadata only', () async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    final target = _account('https://a.example', 'token-a');
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (_) => _FakeApi(
        target.serverUrl,
        target.token,
        error: StateError('server-controlled detail'),
      ),
      removeLocally: (_) async {},
      invalidateProviders: (_) {},
    );

    await coordinator.remove(target);

    expect(messages, contains('account_removal_remote_revocation_failed'));
    expect(messages.join('\n'), isNot(contains('server-controlled detail')));
    expect(messages.join('\n'), isNot(contains(target.token)));
  });

  test('remote timeout does not delay local cleanup', () async {
    final target = _account('https://a.example', 'token-a');
    final api = _FakeApi(
      target.serverUrl,
      target.token,
      error: TimeoutException('server detail'),
    )..waitForRelease = true;
    var localCalls = 0;
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (_) => api,
      removeLocally: (_) async => localCalls++,
      invalidateProviders: (_) {},
    );

    final removal = coordinator.remove(target);
    await api.started.future;
    expect(localCalls, 1);
    api.release.complete();

    expect(
      (await removal).status,
      AccountRemovalStatus.remoteRevocationFailed,
    );
  });

  test('duplicate removals share one remote and local sequence', () async {
    final target = _account('https://a.example', 'token-a');
    final api = _FakeApi(target.serverUrl, target.token)
      ..waitForRelease = true;
    var localCalls = 0;
    var invalidations = 0;
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (_) => api,
      removeLocally: (_) async {
        localCalls++;
      },
      invalidateProviders: (_) => invalidations++,
    );

    final first = coordinator.remove(target);
    await api.started.future;
    final second = coordinator.remove(target);
    expect(second, same(first));
    api.release.complete();

    final results = await Future.wait([first, second]);
    expect(results[0].status, AccountRemovalStatus.removed);
    expect(results[1].status, AccountRemovalStatus.removed);
    expect(api.logoutCalls, 1);
    expect(localCalls, 1);
    expect(invalidations, 1);
  });

  test('local failure is not reported as successful removal', () async {
    final target = _account('https://a.example', 'token-a');
    final coordinator = AccountRemovalCoordinator(
      apiFactory: (_) => _FakeApi(target.serverUrl, target.token),
      removeLocally: (_) async => throw StateError('local detail'),
      invalidateProviders: (_) => fail('providers must stay valid'),
    );

    final result = await coordinator.remove(target);

    expect(result.status, AccountRemovalStatus.localCleanupFailed);
    expect('$result', isNot(contains('local detail')));
    expect('$result', isNot(contains(target.token)));
  });
}
