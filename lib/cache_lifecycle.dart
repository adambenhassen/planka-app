import 'dart:async';

/// Raised when an operation tries to use an account cache after its removal
/// barrier has closed.
class AccountCacheClosedException implements Exception {
  @override
  String toString() => 'AccountCacheClosedException';
}

/// Raised when an admitted cache operation cannot be quiesced in time.
class AccountCacheQuiesceException implements Exception {
  @override
  String toString() => 'AccountCacheQuiesceException';
}

/// Shared by the app's envelope and media cache providers.
final accountCacheLifecycle = AccountCacheLifecycle();

/// A reference held by one admitted cache operation.
///
/// The reference keeps account removal from reaching its cold verification
/// until the operation has finished. If removal starts while the operation is
/// waiting, [ensureOpen] makes the operation fail instead of returning data
/// that was produced during teardown.
class AccountCacheLease {
  AccountCacheLease._(
    this._lifecycle,
    this._accountId,
    this._state,
    this._generation,
  );

  AccountCacheLease._unscoped()
    : _lifecycle = null,
      _accountId = null,
      _state = null,
      _generation = null;

  final AccountCacheLifecycle? _lifecycle;
  final String? _accountId;
  final _AccountCacheState? _state;
  final int? _generation;
  FutureOr<void> Function()? _onRemoval;
  bool _invalidated = false;
  bool _released = false;

  /// Whether removal has started since this operation was admitted.
  bool get wasClosed =>
      _invalidated ||
      (_state?.removing ?? false) ||
      (_generation != null && _state?.generation != _generation);

  /// Fails an admitted operation that crossed the removal barrier.
  void ensureOpen() {
    if (wasClosed) throw AccountCacheClosedException();
  }

  /// Registers cancellation for a stream-backed operation.
  void onRemoval(FutureOr<void> Function() callback) {
    if (_released) return;
    if (wasClosed) {
      _invoke(callback);
    } else {
      _onRemoval = callback;
    }
  }

  /// Records that cancellation or draining could not safely complete.
  void reportRemovalFailure() {
    final lifecycle = _lifecycle;
    final accountId = _accountId;
    final state = _state;
    if (lifecycle != null && accountId != null && state != null) {
      lifecycle._recordRemovalFailure(accountId, state);
    }
  }

  void _invoke(FutureOr<void> Function() callback) {
    unawaited(_runRemovalCallback(callback));
  }

  Future<void> _runRemovalCallback(FutureOr<void> Function() callback) async {
    try {
      await callback();
    } catch (_) {
      reportRemovalFailure();
    }
  }

  void _invalidate() {
    if (_released) return;
    _invalidated = true;
    final callback = _onRemoval;
    _onRemoval = null;
    if (callback != null) _invoke(callback);
  }

  void release() {
    if (_released) return;
    _released = true;
    _onRemoval = null;
    final lifecycle = _lifecycle;
    final accountId = _accountId;
    final state = _state;
    if (lifecycle != null && accountId != null && state != null) {
      lifecycle._release(accountId, state, this);
    }
  }
}

/// Coordinates all cache families for account removal.
///
/// The lifecycle is intentionally independent from either cache
/// implementation. The envelope cache and media cache can therefore share one
/// barrier, while tests and isolated cache instances can use their own.
class AccountCacheLifecycle {
  AccountCacheLifecycle({this.removalTimeout = const Duration(seconds: 5)});

  final Duration removalTimeout;
  final Map<String, _AccountCacheState> _states = {};

  /// Records an account as a cache owner without admitting an operation.
  void register(String accountId) {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    if (state.removing || state.removed) {
      throw AccountCacheClosedException();
    }
  }

  /// Remembers an account loaded from durable credentials without reopening a
  /// cache that is already being removed. This makes account-shaped envelope
  /// keys unambiguous before the first cache operation reaches the provider.
  void registerKnown(String accountId) {
    _validate(accountId);
    _states.putIfAbsent(accountId, _AccountCacheState.new);
  }

  /// Restores a durable failed-removal tombstone before startup registers the
  /// account. Registration intentionally does not reopen this state.
  void restoreRemovalFailure(String accountId) {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    state.removing = true;
    state.removed = false;
    state.removalFailure = AccountCacheQuiesceException();
  }

  /// Admits one operation for [accountId], or fails after removal begins.
  AccountCacheLease acquire(String accountId, {int? generation}) {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    if (state.removing ||
        state.removed ||
        (generation != null && state.generation != generation)) {
      throw AccountCacheClosedException();
    }
    final lease = AccountCacheLease._(this, accountId, state, state.generation);
    state.leases.add(lease);
    state.active++;
    return lease;
  }

  /// Returns the epoch for handles created during the current authentication.
  int generationFor(String accountId) {
    _validate(accountId);
    final state = _states[accountId];
    if (state == null) throw StateError('Unknown account cache');
    return state.generation;
  }

  /// Admits an operation whose account is encoded in the established cache
  /// key format, `[account-id]-[resource]`.
  ///
  /// Keys without an account-shaped prefix are still supported for the small
  /// unscoped cache entries used by older callers.
  AccountCacheLease acquireForKey(String key) {
    final accountId = accountIdForKey(key);
    return accountId == null
        ? AccountCacheLease._unscoped()
        : acquire(accountId);
  }

  /// Resolves an account prefix without treating a substring account as the
  /// owner of another account's key. Registered IDs win, using the longest
  /// match; the fallback handles the first use before a media handle registers
  /// the account.
  String? accountIdForKey(String key) {
    final matches =
        _states.keys
            .where((accountId) => key.startsWith('$accountId-'))
            .toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    if (matches.isNotEmpty) return matches.first;

    final hash = key.indexOf('#');
    if (hash < 0) return null;

    // Account ids normally end in a UUID, so a first-separator fallback would
    // split a user id at its first UUID hyphen. These are the resource suffixes
    // used by the envelope cache; registered ids still take precedence above.
    for (final marker in const ['-projects', '-project-', '-board-']) {
      final separator = key.indexOf(marker, hash + 1);
      if (separator <= hash + 1) continue;
      if (marker == '-projects' && separator + marker.length != key.length) {
        continue;
      }
      return key.substring(0, separator);
    }

    final separator = key.indexOf('-', hash + 1);
    if (separator <= hash + 1) return null;
    return key.substring(0, separator);
  }

  /// Closes new acquisitions and waits for every already admitted operation.
  ///
  /// A failed purge deliberately leaves this state closed. Calling this again
  /// for an idempotent retry waits for any current work and then returns.
  Future<void> beginRemoval(String accountId) async {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    state.removing = true;
    // A failed cancellation closes the account but does not make the failure
    // permanent. Once the failed callback has released its lease, the next
    // purge attempt may retry the same namespace idempotently.
    if (state.removalFailure != null && state.active == 0) {
      state.removalFailure = null;
    }
    if (state.active == 0) return;
    if (state.drain == null || state.drain!.isCompleted) {
      state.drain = Completer<void>();
    }
    for (final lease in state.leases.toList()) {
      lease._invalidate();
    }
    try {
      await state.drain!.future.timeout(removalTimeout);
    } on TimeoutException {
      final failure = AccountCacheQuiesceException();
      state.removalFailure ??= failure;
      throw failure;
    }
    final failure = state.removalFailure;
    if (failure != null) throw failure;
  }

  /// Reopens an account after a new authenticated account has been persisted.
  /// This is separate from removal so an old cache handle cannot reopen itself.
  void reopen(String accountId) {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    if (state.removing && !state.removed) {
      throw AccountCacheClosedException();
    }
    if (!state.removing && !state.removed) return;
    if (state.active != 0) {
      throw StateError('Cannot reopen an active account cache');
    }
    state.removing = false;
    state.removed = false;
    state.generation++;
    state.removalFailure = null;
    state.drain = null;
  }

  /// Marks a completed account removal. A later explicit [reopen] is the only
  /// operation allowed to make a newly authenticated account with this id
  /// usable again.
  void completeRemoval(String accountId) {
    _validate(accountId);
    final state = _states.putIfAbsent(accountId, _AccountCacheState.new);
    if (state.active != 0) {
      throw StateError('Cannot complete an active account cache removal');
    }
    state.removing = true;
    state.removed = true;
  }

  void _release(
    String accountId,
    _AccountCacheState state,
    AccountCacheLease lease,
  ) {
    if (!_states.containsKey(accountId)) return;
    state.leases.remove(lease);
    state.active--;
    if (state.active == 0 && state.drain != null && !state.drain!.isCompleted) {
      state.drain!.complete();
    }
  }

  void _recordRemovalFailure(String accountId, _AccountCacheState state) {
    if (_states[accountId] == state) {
      state.removalFailure ??= AccountCacheQuiesceException();
    }
  }

  void _validate(String accountId) {
    if (accountId.isEmpty) throw ArgumentError.value(accountId, 'accountId');
  }
}

class _AccountCacheState {
  var active = 0;
  var generation = 0;
  var removing = false;
  var removed = false;
  AccountCacheQuiesceException? removalFailure;
  Completer<void>? drain = Completer<void>()..complete();
  final Set<AccountCacheLease> leases = {};
}
