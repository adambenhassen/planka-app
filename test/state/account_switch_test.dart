import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/envelope_cache.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/state/user_socket.dart';

/// Returns projects tagged by server, so each account yields a distinct list.
class _FakeApi extends PlankaApi {
  _FakeApi(super.serverUrl, super.token);

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'items': [
          {'id': 'p@$serverUrl', 'name': 'Project @ $serverUrl'}
        ]
      });
}

class _BoardApi extends PlankaApi {
  _BoardApi(super.serverUrl, super.token, {this.gate});

  final Completer<void>? gate;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    final pending = gate;
    if (pending != null) await pending.future;
    final fixture = jsonDecode(
      File('test/fixtures/board_show.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final item = (fixture['item'] as Map).cast<String, dynamic>();
    item['name'] = serverUrl;
    return Envelope.parse(fixture);
  }
}

class _MutableAccount extends CurrentAccountNotifier {
  _MutableAccount(this.account);

  Account? account;

  @override
  Account? build() => account;

  void switchTo(Account? next) {
    account = next;
    state = next;
  }
}

class _MemStore implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  Account account(String server) => Account(
      serverUrl: server, token: 'tok', userId: 'u1', displayName: 'User');

  test('switching the current account reloads projects for that account',
      () async {
    final container = ProviderContainer(overrides: [
      accountStoreProvider.overrideWithValue(AccountStore(_MemStore())),
      apiProvider.overrideWith((ref) {
        final acc = ref.watch(currentAccountProvider)!;
        return _FakeApi(acc.serverUrl, acc.token);
      }),
    ]);
    addTearDown(container.dispose);

    await container
        .read(currentAccountProvider.notifier)
        .select(account('http://a'));
    final first = await container.read(projectsProvider.future);
    expect(first.projects.map((p) => p.name), ['Project @ http://a']);

    await container
        .read(currentAccountProvider.notifier)
        .select(account('http://b'));
    final second = await container.read(projectsProvider.future);
    expect(second.projects.map((p) => p.name), ['Project @ http://b']);
  });

  test('switching accounts clears same-board state before the new load',
      () async {
    final accountA = account('http://a');
    final accountB = account('http://b');
    final mutable = _MutableAccount(accountA);
    final bGate = Completer<void>();
    final cacheDir = await Directory.systemTemp.createTemp('board_switch');
    final container = ProviderContainer(overrides: [
      currentAccountProvider.overrideWith(() => mutable),
      apiProvider.overrideWith((ref) {
        final active = ref.watch(currentAccountProvider)!;
        return _BoardApi(
          active.serverUrl,
          active.token,
          gate: active.id == accountB.id ? bGate : null,
        );
      }),
      envelopeCacheProvider.overrideWithValue(
        EnvelopeCache(directory: cacheDir),
      ),
      userSocketProvider.overrideWithValue(null),
      userEventsProvider.overrideWithValue(const Stream.empty()),
      userConnectedProvider.overrideWithValue(const Stream.empty()),
    ]);
    addTearDown(container.dispose);
    addTearDown(() => cacheDir.delete(recursive: true));

    final boardId = 'b1';
    await container.read(boardProvider(boardId).future);
    expect(container.read(boardProvider(boardId)).value?.board.name, 'http://a');

    mutable.switchTo(accountB);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).value, isNull);

    final loading = container.read(boardProvider(boardId).future);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).value, isNull);
    bGate.complete();
    await loading;
    expect(container.read(boardProvider(boardId)).value?.board.name, 'http://b');

    mutable.switchTo(null);
    await pumpEventQueue();
    expect(container.read(boardProvider(boardId)).value, isNull);
  });
}
