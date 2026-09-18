import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';

/// The signed-in user's own profile. Null when no account is selected;
/// re-fetches whenever the current account changes.
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, PlankaUser?>(
      CurrentUserNotifier.new,
    );

class CurrentUserNotifier extends AsyncNotifier<PlankaUser?> {
  void Function()? _removeAccountEpochListener;

  void _invalidateAccountState() {
    ref.invalidateSelf();
    if (ref.mounted) {
      state = AsyncLoading<PlankaUser?>().copyWithPrevious(
        AsyncError<PlankaUser?>(
          StateError('Account changed'),
          StackTrace.current,
        ),
      );
    }
  }

  @override
  Future<PlankaUser?> build() async {
    ref.watch(accountStateEpochProvider);
    if (_removeAccountEpochListener == null) {
      _removeAccountEpochListener = ref
          .read(accountStateEpochProvider.notifier)
          .listen(_invalidateAccountState);
      ref.onDispose(() {
        _removeAccountEpochListener?.call();
        _removeAccountEpochListener = null;
      });
    }
    final account = ref.watch(currentAccountProvider);
    if (account == null) return null;
    final env = await PlankaRepo(ref.watch(apiProvider)).me();
    return PlankaUser.fromJson(env.item);
  }
}
