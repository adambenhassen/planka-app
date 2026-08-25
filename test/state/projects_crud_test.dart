import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/envelope_cache.dart';
import 'package:planka_app/state/projects_state.dart';

/// The default fixed account used by the tests.
final Account _fixed = Account(
    serverUrl: 'https://planka.example.com',
    token: 'tok',
    userId: 'u1',
    displayName: 'Test');

/// The default account's cache key.
const String _defaultKey = 'https://planka.example.com#u1-projects';

/// A current account pinned to a fixed [Account].
class _FixedAccount extends CurrentAccountNotifier {
  _FixedAccount(this._account);
  final Account _account;
  @override
  Account build() => _account;
}

/// A current account the test can switch mid-flight, to simulate the user
/// changing accounts while a write is in flight.
class _MutableAccount extends CurrentAccountNotifier {
  /// The account [build] returns. Set before the provider is first read.
  Account? account;
  @override
  Account? build() => account;

  /// Switches the active account. Only valid once the provider has been read
  /// (the notifier initialized); a mid-flight account switch does exactly
  /// this.
  void switchTo(Account? account) {
    this.account = account;
    state = account;
  }
}

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/projects_index.json').readAsStringSync())
        as Map<String, dynamic>;

/// Serves the projects fixture on GET and records every mutation call.
class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');
  int getCalls = 0;
  final calls = <String>[];
  final patchBodies = <String, Object?>{};

  bool failGets = false;

  /// When true, the served fixture marks the first project favourited, so a
  /// post-mutation refresh can be told apart from the initial load.
  bool favorited = false;

  /// When set, [patch] awaits it before responding, so a test can hold a write
  /// in flight (e.g. to switch the active account mid-write).
  Completer<void>? patchGate;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    if (failGets) throw ApiException(503, 'server unavailable');
    final fixture = jsonDecode(jsonEncode(_fixture())) as Map<String, dynamic>;
    if (favorited) fixture['items'][0]['isFavorite'] = true;
    return Envelope.parse(fixture);
  }

  @override
  Future<Envelope> post(String path, Object? body) async {
    calls.add('POST $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    calls.add('PATCH $path');
    patchBodies[path] = body;
    final gate = patchGate;
    if (gate != null) await gate.future;
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> delete(String path) async {
    calls.add('DELETE $path');
    return Envelope.parse({'item': <String, dynamic>{}});
  }
}

void main() {
  /// Lets a provider rebuild settle. The UI reads state via watch, so tests
  /// drive a reload (invalidate/refresh) and then assert on the settled
  /// state rather than awaiting the provider's future, which Riverpod does
  /// not complete once a build has errored.
  Future<void> settle(ProviderContainer container) async {
    for (var i = 0;
        i < 200 && container.read(projectsProvider).isLoading;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await container.pump();
    }
  }

  /// Boots with a selected account (so the offline cache path is used) and
  /// an in-memory cache directory. [cacheDir] may be shared across containers
  /// to simulate a cold start over the same on-disk cache.
  Future<(ProviderContainer, ProjectsNotifier, _FakeApi)> boot({
    Directory? cacheDir,
    Account? account,
    bool initialLoad = true,
  }) async {
    final api = _FakeApi();
    final dir = cacheDir ??
        Directory.systemTemp.createTempSync('projects_crud_cache');
    if (cacheDir == null) addTearDown(() => dir.deleteSync(recursive: true));
    final active = account ?? _fixed;
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(() => _FixedAccount(active)),
      envelopeCacheProvider.overrideWithValue(EnvelopeCache(directory: dir)),
    ]);
    if (initialLoad) await container.read(projectsProvider.future);
    return (container, container.read(projectsProvider.notifier), api);
  }

  /// The envelope the on-disk offline cache currently holds for [key].
  Future<Envelope?> cached(ProviderContainer container, String key) =>
      container.read(envelopeCacheProvider).get(key);

  test('createProject posts then refetches the projects list', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);
    final getsBefore = api.getCalls;

    await notifier.createProject('New Project');

    expect(api.calls, ['POST /projects']);
    expect(api.getCalls, getsBefore + 1);
  });

  test('setProjectFavorite patches isFavorite then refetches', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);
    final getsBefore = api.getCalls;

    await notifier.setProjectFavorite('p1', favorite: true);

    expect(api.calls, ['PATCH /projects/p1']);
    expect(api.patchBodies['/projects/p1'], {'isFavorite': true});
    expect(api.getCalls, getsBefore + 1);
  });

  test('orderedProjects pulls favourites ahead, keeps server order', () {
    PlankaProject p(String id, {bool favorite = false}) =>
        PlankaProject(id: id, name: id, isFavorite: favorite);
    const nullFavorite = PlankaProject(id: 'x', name: 'x');
    final view = ProjectsView(projects: [
      p('a'),
      p('b', favorite: true),
      p('c'),
      p('d', favorite: true),
      nullFavorite,
    ], boards: const [], backgroundImages: const []);

    expect(view.orderedProjects.map((p) => p.id).toList(),
        ['b', 'd', 'a', 'c', 'x']);
  });

  test('a failed refresh after a successful mutation surfaces an error, '
      'never stale cached data', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    // The initial load succeeded, so the offline cache now holds a copy with
    // the pre-mutation state. The write succeeds; the refresh after it fails.
    api.failGets = true;
    // The mutation rejects with the refresh failure, so the caller can
    // surface it (guardMutation shows the snackbar).
    await expectLater(
        notifier.setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));

    expect(api.calls, ['PATCH /projects/p1']);

    final state = container.read(projectsProvider);
    expect(state.hasError, isTrue);
    // The mutation's own write succeeded, so the failure is the refresh's.
    expect(state.error, isA<ApiException>());
  });

  test('a successful mutation leaves the offline cache holding the '
      'post-mutation state', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    // Before the mutation the cache holds the initial load, unfavourited.
    expect((await cached(container, _defaultKey))!.items[0]['isFavorite'],
        isFalse);

    // The server now reports the project favourited, so the post-mutation
    // refresh is distinguishable from the initial load.
    api.favorited = true;
    await notifier.setProjectFavorite('p1', favorite: true);

    // The next offline start must be served the post-mutation state, not the
    // pre-mutation copy the cache held before the refresh.
    final cachedEnv = await cached(container, _defaultKey);
    expect(cachedEnv!.items[0]['isFavorite'], isTrue);

    // A successful mutation must not strand the account: with the server now
    // down, an ordinary reload still succeeds, serving the cached
    // post-mutation copy (no error, no revert to the pre-mutation value).
    api.failGets = true;
    container.invalidate(projectsProvider);
    await settle(container);
    final reloaded = container.read(projectsProvider);
    expect(reloaded.hasError, isFalse);
    expect(reloaded.value!.projects.first.isFavorite, isTrue);
  });

  test('a failed mutation refresh deletes the stale cache copy', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    // The initial load populated the cache with the pre-mutation copy.
    expect((await cached(container, _defaultKey))!.items[0]['isFavorite'],
        isFalse);

    api.failGets = true;
    await expectLater(
        notifier.setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));

    // The write landed but the confirming refresh failed, so the pre-mutation
    // copy must not remain available: the cache entry is deleted.
    expect(await cached(container, _defaultKey), isNull);
  });

  test('a cold start after a failed confirming refresh errors rather than '
      'serving the pre-mutation copy', () async {
    final api = _FakeApi();
    final cacheDir =
        Directory.systemTemp.createTempSync('projects_crud_cold');
    addTearDown(() => cacheDir.deleteSync(recursive: true));

    // First "session": load (populates the cache), then a mutation whose
    // confirming refresh fails (deletes the stale copy).
    final first = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(() => _FixedAccount(_fixed)),
      envelopeCacheProvider
          .overrideWithValue(EnvelopeCache(directory: cacheDir)),
    ]);
    await first.read(projectsProvider.future);
    api.failGets = true;
    await expectLater(
        first.read(projectsProvider.notifier)
            .setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));
    first.dispose();

    // "Cold start": a fresh container over the same on-disk cache, still
    // offline. It must not resurrect the pre-mutation copy — with the stale
    // entry gone and the server down, the load errors rather than serving
    // the old values.
    final second = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(() => _FixedAccount(_fixed)),
      envelopeCacheProvider
          .overrideWithValue(EnvelopeCache(directory: cacheDir)),
    ]);
    addTearDown(second.dispose);
    second.read(projectsProvider); // start the build
    await settle(second);
    final state = second.read(projectsProvider);
    expect(state.hasError, isTrue);
    // Not a silent revert: no pre-mutation value is presented as data.
    expect(state.value, isNull);
  });

  test('a failed write on one account leaves the other account\'s cache '
      'fallback intact', () async {
    final api = _FakeApi();
    final cacheDir =
        Directory.systemTemp.createTempSync('projects_crud_accounts');
    addTearDown(() => cacheDir.deleteSync(recursive: true));
    final accountA = Account(
        serverUrl: 'https://a.example.com',
        token: 'tok',
        userId: 'u1',
        displayName: 'A');
    final accountB = Account(
        serverUrl: 'https://b.example.com',
        token: 'tok',
        userId: 'u1',
        displayName: 'B');
    final keyA = '${accountA.id}-projects';
    final keyB = '${accountB.id}-projects';

    // Give both accounts a good cached copy.
    final cache = EnvelopeCache(directory: cacheDir);
    final good = Envelope.parse(_fixture());
    await cache.put(keyA, good);
    await cache.put(keyB, good);

    // A failed confirming refresh on account A deletes only A's key.
    final containerA = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(() => _FixedAccount(accountA)),
      envelopeCacheProvider
          .overrideWithValue(EnvelopeCache(directory: cacheDir)),
    ]);
    addTearDown(containerA.dispose);
    api.failGets = true;
    await expectLater(containerA.read(projectsProvider.notifier)
        .setProjectFavorite('p1', favorite: true), throwsA(isA<ApiException>()));

    // A's stale copy is gone; B's is untouched, so B can still fall back to
    // its last good copy while offline.
    expect(await cache.get(keyA), isNull);
    expect(await cache.get(keyB), isNotNull);
  });

  test('a write in flight across an account switch cleans up the write\'s '
      'account, not the newly active one', () async {
    final api = _FakeApi();
    final cacheDir =
        Directory.systemTemp.createTempSync('projects_crud_switch');
    addTearDown(() => cacheDir.deleteSync(recursive: true));
    final accountA = Account(
        serverUrl: 'https://a.example.com',
        token: 'tok',
        userId: 'u1',
        displayName: 'A');
    final accountB = Account(
        serverUrl: 'https://b.example.com',
        token: 'tok',
        userId: 'u1',
        displayName: 'B');
    final keyA = '${accountA.id}-projects';
    final keyB = '${accountB.id}-projects';
    final cache = EnvelopeCache(directory: cacheDir);
    final good = Envelope.parse(_fixture());
    // Both accounts start with a good cached copy.
    await cache.put(keyA, good);
    await cache.put(keyB, good);

    final mutable = _MutableAccount()..account = accountA;
    final container = ProviderContainer(overrides: [
      apiProvider.overrideWithValue(api),
      currentAccountProvider.overrideWith(() => mutable),
      envelopeCacheProvider
          .overrideWithValue(EnvelopeCache(directory: cacheDir)),
    ]);
    addTearDown(container.dispose);
    container.read(currentAccountProvider); // build the notifier
    await container.read(projectsProvider.future); // initial load as A

    // Hold A's write in flight, then switch the active account to B while it
    // is pending. The confirming refresh and cache cleanup must still target
    // A (the account the write was made against), never B.
    final gate = Completer<void>();
    api.patchGate = gate;
    final mutation = container
        .read(projectsProvider.notifier)
        .setProjectFavorite('p1', favorite: true);
    // Let the write reach the gate before switching accounts.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    mutable.switchTo(accountB);
    api.failGets = true; // A's confirming refresh now fails
    gate.complete();
    await expectLater(mutation, throwsA(isA<ApiException>()));

    // A's stale copy is gone (its confirming refresh failed); B's valid copy
    // survives — the account switch did not redirect the cleanup to B's key.
    expect(await cache.get(keyA), isNull);
    expect(await cache.get(keyB), isNotNull);
  });

  test('a still-offline retry after a failed mutation refresh stays in '
      'error, then recovers on a live fetch', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    api.failGets = true;
    await expectLater(
        notifier.setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));
    expect(container.read(projectsProvider).hasError, isTrue);

    // The error UI's Retry invalidates the provider. While the server is
    // still down the rebuild must not serve the cached pre-mutation copy.
    api.favorited = true;
    container.invalidate(projectsProvider);
    await settle(container);
    expect(container.read(projectsProvider).hasError, isTrue);

    // Once the server answers, the same retry path recovers with fresh data.
    api.failGets = false;
    container.invalidate(projectsProvider);
    await settle(container);
    final state = container.read(projectsProvider);
    expect(state.hasError, isFalse);
    expect(state.value!.projects.first.isFavorite, isTrue);
  });

  test('pull-to-refresh on a failed mutation refresh stays in error while '
      'offline', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    api.failGets = true;
    await expectLater(
        notifier.setProjectFavorite('p1', favorite: true),
        throwsA(isA<ApiException>()));
    expect(container.read(projectsProvider).hasError, isTrue);

    // The list's pull-to-refresh calls refresh(projectsProvider.future) with
    // the server still down: the rebuild must not revert to the cached
    // pre-mutation copy, so the state stays an error.
    api.favorited = true;
    final getsBefore = api.getCalls;
    container.refresh(projectsProvider.future);
    await settle(container);
    // The refresh actually re-ran a fetch (did not just keep the old error),
    // hit the downed server, and therefore stayed in error rather than
    // serving the cached pre-mutation copy.
    expect(api.getCalls, greaterThan(getsBefore));
    expect(container.read(projectsProvider).hasError, isTrue);
  });

  test('an ordinary list load still falls back to the offline cache',
      () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    api.failGets = true;
    container.invalidate(projectsProvider);

    // The fetch fails, but the last good copy is served from the cache.
    await expectLater(container.read(projectsProvider.future),
        completes);
    final state = container.read(projectsProvider);
    expect(state.hasError, isFalse);
    expect(state.value!.projects, isNotEmpty);
  });

  test('project and board mutations hit the expected endpoints', () async {
    final (container, notifier, api) = await boot();
    addTearDown(container.dispose);

    await notifier.renameProject('p1', 'Renamed');
    await notifier.setProjectGradient('p1', 'ocean-dive');
    await notifier.setProjectBackgroundImage('p1',
        filePath: 'test/fixtures/projects_index.json', name: 'bg.png');
    await notifier.clearProjectBackground('p1');
    await notifier.addProjectManager('p1', 'u1');
    await notifier.removeProjectManager('pm1');
    await notifier.deleteProject('p1');
    await notifier.createBoard('p1', 'Board');
    await notifier.renameBoard('b1', 'Renamed');
    await notifier.deleteBoard('b1');

    expect(api.calls, [
      'PATCH /projects/p1',
      'PATCH /projects/p1',
      'POST /projects/p1/background-images',
      'PATCH /projects/p1',
      'PATCH /projects/p1',
      'POST /projects/p1/project-managers',
      'DELETE /project-managers/pm1',
      'DELETE /projects/p1',
      'POST /projects/p1/boards',
      'PATCH /boards/b1',
      'DELETE /boards/b1',
    ]);
  });
}
