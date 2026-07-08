import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';

/// The signed-in user's own profile. Null when no account is selected;
/// re-fetches whenever the current account changes.
final currentUserProvider = FutureProvider<PlankaUser?>((ref) async {
  final account = ref.watch(currentAccountProvider);
  if (account == null) return null;
  final env = await PlankaRepo(ref.watch(apiProvider)).me();
  return PlankaUser.fromJson(env.item);
});
