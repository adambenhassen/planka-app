import 'package:flutter/foundation.dart';

import '../api/planka_api.dart';
import '../security_redaction.dart';
import 'accounts.dart';

typedef AccountRemovalApiFactory = PlankaApi Function(Account account);
typedef AccountRemovalLocalHandler = Future<void> Function(String accountId);
typedef AccountRemovalInvalidator = void Function(String accountId);

enum AccountRemovalStatus {
  removed,
  remoteRevocationFailed,
  localCleanupFailed,
}

/// The outcome of one account-removal operation.
///
/// This object deliberately contains no exception or account credential. A
/// remote server can put sensitive details in either, and account removal must
/// only expose fixed, token-free outcomes to the UI.
class AccountRemovalResult {
  const AccountRemovalResult(this.status);

  final AccountRemovalStatus status;

  @override
  String toString() => 'AccountRemovalResult($status)';
}

/// Coordinates best-effort server revocation with authoritative local
/// cleanup for one immutable account target.
class AccountRemovalCoordinator {
  AccountRemovalCoordinator({
    required this.apiFactory,
    required this.removeLocally,
    required this.invalidateProviders,
  });

  final AccountRemovalApiFactory apiFactory;
  final AccountRemovalLocalHandler removeLocally;
  final AccountRemovalInvalidator invalidateProviders;
  final Map<String, Future<AccountRemovalResult>> _inFlight = {};
  final Map<String, String> _inFlightTokens = {};

  /// Starts removal for [account], or returns the already-running operation
  /// for the same account id and credential. A reauthenticated copy with a
  /// new token starts its own operation. The copied fields are the only values
  /// used by every await below, so changing selection cannot retarget it.
  Future<AccountRemovalResult> remove(Account account) {
    final existing = _inFlight[account.id];
    if (existing != null && _inFlightTokens[account.id] == account.token) {
      return existing;
    }

    final target = Account(
      serverUrl: account.serverUrl,
      token: account.token,
      userId: account.userId,
      displayName: account.displayName,
    );
    late final Future<AccountRemovalResult> operation;
    operation = _run(target).whenComplete(() {
      if (identical(_inFlight[target.id], operation)) {
        _inFlight.remove(target.id);
        _inFlightTokens.remove(target.id);
      }
    });
    _inFlight[target.id] = operation;
    _inFlightTokens[target.id] = target.token;
    return operation;
  }

  Future<AccountRemovalResult> _run(Account target) async {
    // Start both sides immediately. A slow server must not hold the local
    // purge behind its timeout; the result waits for both bounded operations.
    final remote = _revokeRemotely(target);
    var localFailed = false;
    try {
      await removeLocally(target.id);
    } catch (_) {
      // The local handler retains its durable retry marker and redacted cause.
      // Do not turn that cause into user-visible text here.
      localFailed = true;
    }

    if (!localFailed) {
      try {
        invalidateProviders(target.id);
      } catch (_) {
        // A successful purge with a failed invalidation is not safe to report
        // as complete: stale account-backed state could remain readable.
        localFailed = true;
      }
    }

    final remoteFailed = await remote;
    if (localFailed) {
      return const AccountRemovalResult(
        AccountRemovalStatus.localCleanupFailed,
      );
    }
    return AccountRemovalResult(
      remoteFailed
          ? AccountRemovalStatus.remoteRevocationFailed
          : AccountRemovalStatus.removed,
    );
  }

  Future<bool> _revokeRemotely(Account target) async {
    try {
      final api = apiFactory(target);
      await api.logout();
      return false;
    } catch (error) {
      // Revocation is explicitly best-effort. The local cleanup is already
      // running independently, and the UI receives only a fixed warning.
      debugPrint(
        'account removal remote revocation failed: '
        '${redactDiagnostic(error)}',
      );
      return true;
    }
  }
}
