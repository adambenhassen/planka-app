import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/projects_state.dart';

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
}
