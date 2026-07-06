import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/planka_api.dart';
import 'accounts.dart';

final accountStoreProvider = Provider<AccountStore>(
    (ref) => AccountStore(const FlutterSecureKeyValueStore()));

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(
        AccountsNotifier.new);

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() => ref.read(accountStoreProvider).load();

  Future<void> upsert(Account account) async {
    // Await the loaded list so a call during loading can't drop stored accounts.
    final list = <Account>[...await future]
      ..removeWhere((a) => a.id == account.id)
      ..add(account);
    await ref.read(accountStoreProvider).save(list);
    state = AsyncData(list);
  }

  Future<void> remove(String accountId) async {
    final list = <Account>[...await future]
      ..removeWhere((a) => a.id == accountId);
    await ref.read(accountStoreProvider).save(list);
    state = AsyncData(list);
    final current = ref.read(currentAccountProvider);
    if (current?.id == accountId) {
      await ref.read(currentAccountProvider.notifier).select(null);
    }
  }
}

final currentAccountProvider =
    NotifierProvider<CurrentAccountNotifier, Account?>(
        CurrentAccountNotifier.new);

class CurrentAccountNotifier extends Notifier<Account?> {
  @override
  Account? build() => null;

  Future<void> restore() async {
    final store = ref.read(accountStoreProvider);
    final id = await store.readCurrentId();
    if (id == null) return;
    final accounts = await ref.read(accountsProvider.future);
    state = accounts.where((a) => a.id == id).firstOrNull;
  }

  Future<void> select(Account? account) async {
    state = account;
    final store = ref.read(accountStoreProvider);
    await store.writeCurrentId(account?.id);
  }
}

final apiProvider = Provider<PlankaApi>((ref) {
  final account = ref.watch(currentAccountProvider);
  if (account == null) throw StateError('No account selected');
  return PlankaApi(account.serverUrl, account.token);
});
