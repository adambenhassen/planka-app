import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/planka_api.dart';
import '../api/repositories.dart';
import 'accounts.dart';

final accountStoreProvider = Provider<AccountStore>((ref) {
  // Mobile has a hardware-backed keystore/keychain — use it. Desktop builds are
  // unsigned locally, so the keychain is unavailable there (errSecMissingEntitlement);
  // fall back to an owner-only file under the app's home dir instead.
  final SecureKeyValueStore store = (Platform.isAndroid || Platform.isIOS)
      ? const FlutterSecureKeyValueStore()
      : FileKeyValueStore(Directory('${_desktopHome()}/.planka_app'));
  return AccountStore(store);
});

String _desktopHome() =>
    Platform.environment['HOME'] ??
    Platform.environment['USERPROFILE'] ??
    Directory.systemTemp.path;

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

  /// Completes login for an already-authenticated [api]: fetches the profile,
  /// assembles and stores the account, then selects it. Keeps the repository
  /// and model layers out of the login UI.
  Future<void> signIn(PlankaApi api, String serverUrl) async {
    final me = PlankaUser.fromJson((await PlankaRepo(api).me()).item);
    final account = Account(
      serverUrl: serverUrl,
      token: api.token!,
      userId: me.id,
      displayName: me.name.isNotEmpty ? me.name : (me.username ?? ''),
    );
    await ref.read(accountsProvider.notifier).upsert(account);
    await select(account);
  }
}

/// Set when a request 401s with a token: the session expired.
/// Carries the expired account so the login screen can prefill.
final authExpiredProvider =
    NotifierProvider<AuthExpiredNotifier, Account?>(AuthExpiredNotifier.new);

class AuthExpiredNotifier extends Notifier<Account?> {
  @override
  Account? build() => null;

  void expire(Account account) => state = account;
  void clear() => state = null;
}

/// Builds an unauthenticated API client for an arbitrary server URL — used by
/// the login flow before an account exists. A provider so tests can inject a
/// fake API.
final apiFactoryProvider = Provider<PlankaApi Function(String serverUrl)>(
    (ref) => (url) => PlankaApi(url, null));

final apiProvider = Provider<PlankaApi>((ref) {
  final account = ref.watch(currentAccountProvider);
  if (account == null) throw StateError('No account selected');
  return PlankaApi(account.serverUrl, account.token, onUnauthorized: () {
    ref.read(authExpiredProvider.notifier).expire(account);
    ref.read(currentAccountProvider.notifier).select(null);
  });
});
