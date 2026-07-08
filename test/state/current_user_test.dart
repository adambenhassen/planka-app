import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/current_user_state.dart';

class _FakeApi extends PlankaApi {
  _FakeApi(super.serverUrl, super.token);

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'item': {'id': 'u1', 'name': 'Alice', 'role': 'boardUser'}
      });
}

void main() {
  test('currentUserProvider is null with no account, parses me() once selected',
      () async {
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWith((ref) {
        final acc = ref.watch(currentAccountProvider)!;
        return _FakeApi(acc.serverUrl, acc.token);
      }),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(currentUserProvider.future), null);

    await container.read(currentAccountProvider.notifier).select(Account(
        serverUrl: 'http://a', token: 'tok', userId: 'u1', displayName: 'Alice'));

    final user = await container.read(currentUserProvider.future);
    expect(user?.name, 'Alice');
    expect(user?.role, 'boardUser');
  });
}
