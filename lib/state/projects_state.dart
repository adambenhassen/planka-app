import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/envelope.dart';
import '../api/models.dart';
import '../api/planka_socket.dart';
import '../api/repositories.dart';
import '../auth/auth_providers.dart';
import 'envelope_cache.dart';
import 'positions.dart';
import 'user_socket.dart';

/// The projects list plus the boards nested under them, translated out of the
/// raw API envelope so the UI consumes domain types rather than dynamic maps.
class ProjectsView {
  final List<PlankaProject> projects;
  final List<PlankaBoard> boards;
  final List<PlankaBackgroundImage> backgroundImages;
  final List<PlankaProjectManager> managers;
  final List<PlankaUser> users;

  /// The projects' custom field templates and the fields on them. Only the
  /// projects response carries these.
  final List<PlankaBaseCustomFieldGroup> baseCustomFieldGroups;
  final List<PlankaCustomField> customFields;
  const ProjectsView({
    required this.projects,
    required this.boards,
    required this.backgroundImages,
    this.managers = const [],
    this.users = const [],
    this.baseCustomFieldGroups = const [],
    this.customFields = const [],
  });

  List<PlankaProjectManager> managersOf(String projectId) =>
      managers.where((m) => m.projectId == projectId).toList();

  /// Projects with favourites pulled ahead of the rest. Server order is kept
  /// within each group, so a user with no favourites sees exactly the order
  /// the server sent.
  List<PlankaProject> get orderedProjects {
    final favorites = <PlankaProject>[];
    final rest = <PlankaProject>[];
    for (final p in projects) {
      ((p.isFavorite ?? false) ? favorites : rest).add(p);
    }
    return [...favorites, ...rest];
  }

  /// A project's templates in server order. A base group carries no position,
  /// so there is no order to change — the list is never re-sorted.
  List<PlankaBaseCustomFieldGroup> baseGroupsOf(String projectId) =>
      baseCustomFieldGroups.where((b) => b.projectId == projectId).toList();

  /// The fields a template holds, in the server's position order.
  List<PlankaCustomField> fieldsOfBaseGroup(String baseGroupId) =>
      customFields
          .where((f) => f.baseCustomFieldGroupId == baseGroupId)
          .toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

  ProjectsView copyWith({
    List<PlankaProject>? projects,
    List<PlankaBoard>? boards,
    List<PlankaBackgroundImage>? backgroundImages,
    List<PlankaProjectManager>? managers,
    List<PlankaUser>? users,
    List<PlankaBaseCustomFieldGroup>? baseCustomFieldGroups,
    List<PlankaCustomField>? customFields,
  }) =>
      ProjectsView(
        projects: projects ?? this.projects,
        boards: boards ?? this.boards,
        backgroundImages: backgroundImages ?? this.backgroundImages,
        managers: managers ?? this.managers,
        users: users ?? this.users,
        baseCustomFieldGroups:
            baseCustomFieldGroups ?? this.baseCustomFieldGroups,
        customFields: customFields ?? this.customFields,
      );
}

/// Events delivered on the signed-in user's room that can change the projects
/// response or the user list. The room is shared with open boards, so the
/// state consumers each filter this same stream to their own surface.
const kProjectsUserRoomEvents = {
  'projectCreate',
  'projectUpdate',
  'projectDelete',
  'boardCreate',
  'boardUpdate',
  'boardDelete',
  'projectManagerCreate',
  'projectManagerDelete',
  'backgroundImageCreate',
  'backgroundImageDelete',
  'userCreate',
  'userUpdate',
  'userDelete',
  'baseCustomFieldGroupCreate',
  'baseCustomFieldGroupUpdate',
  'baseCustomFieldGroupDelete',
  'customFieldCreate',
  'customFieldUpdate',
  'customFieldDelete',
};

List<T> _upsertProjectRow<T>(
    List<T> rows, T row, String Function(T row) idOf) {
  final index = rows.indexWhere((existing) => idOf(existing) == idOf(row));
  if (index < 0) return [...rows, row];
  final next = [...rows];
  next[index] = row;
  return next;
}

PlankaProject? _projectFromEvent(ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.projects.where((p) => p.id == id).firstOrNull;
  return PlankaProject.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaBoard? _boardFromEvent(ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.boards.where((b) => b.id == id).firstOrNull;
  return PlankaBoard.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaProjectManager? _managerFromEvent(
    ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.managers.where((m) => m.id == id).firstOrNull;
  return PlankaProjectManager.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaBackgroundImage? _backgroundImageFromEvent(
    ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing =
      view.backgroundImages.where((image) => image.id == id).firstOrNull;
  return PlankaBackgroundImage.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaUser? _userFromEvent(ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.users.where((u) => u.id == id).firstOrNull;
  return PlankaUser.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaBaseCustomFieldGroup? _baseGroupFromEvent(
    ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.baseCustomFieldGroups
      .where((group) => group.id == id)
      .firstOrNull;
  return PlankaBaseCustomFieldGroup.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

PlankaCustomField? _customFieldFromEvent(
    ProjectsView view, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! String) return null;
  final existing = view.customFields.where((field) => field.id == id).firstOrNull;
  return PlankaCustomField.fromJson({
    if (existing != null) ...existing.toJson(),
    ...item,
  });
}

/// Folds one user-room event into the currently visible projects response.
/// Unknown creates are deliberately ignored: a user-room event is not proof
/// that the signed-in account can read the referenced project. The notifier
/// follows every event with a fresh projects request, which is authoritative.
ProjectsView applyProjectsEvent(ProjectsView view, SocketEvent event) {
  final item = event.data.item;
  final id = item['id'];
  switch (event.name) {
    case 'projectCreate':
      // A create payload alone cannot prove that this account can read the
      // project. The notifier's fresh GET adds it only when the server does.
      return view;
    case 'projectUpdate':
      if (id is! String || !view.projects.any((p) => p.id == id)) return view;
      final project = _projectFromEvent(view, item);
      return project == null
          ? view
          : view.copyWith(
              projects: _upsertProjectRow(view.projects, project, (p) => p.id));
    case 'projectDelete':
      if (id is! String) return view;
      final project = view.projects.where((p) => p.id == id).firstOrNull;
      if (project == null) return view;
      final removedBaseIds = view.baseCustomFieldGroups
          .where((group) => group.projectId == id)
          .map((group) => group.id)
          .toSet();
      return view.copyWith(
        projects: view.projects.where((p) => p.id != id).toList(),
        boards: view.boards.where((board) => board.projectId != id).toList(),
        managers:
            view.managers.where((manager) => manager.projectId != id).toList(),
        backgroundImages: project.backgroundImageId == null
            ? view.backgroundImages
            : view.backgroundImages
                .where((image) => image.id != project.backgroundImageId)
                .toList(),
        baseCustomFieldGroups: view.baseCustomFieldGroups
            .where((group) => group.projectId != id)
            .toList(),
        customFields: view.customFields
            .where((field) =>
                field.baseCustomFieldGroupId == null ||
                !removedBaseIds.contains(field.baseCustomFieldGroupId))
            .toList(),
      );
    case 'boardCreate':
      final projectId = item['projectId'];
      if (projectId is! String ||
          !view.projects.any((project) => project.id == projectId)) {
        return view;
      }
      final board = _boardFromEvent(view, item);
      return board == null
          ? view
          : view.copyWith(boards: _upsertProjectRow(view.boards, board, (b) => b.id));
    case 'boardUpdate':
      if (id is! String) return view;
      final existing = view.boards.where((board) => board.id == id).firstOrNull;
      if (existing == null) return view;
      final projectId = item['projectId'] ?? existing.projectId;
      if (projectId is! String ||
          !view.projects.any((project) => project.id == projectId)) {
        return view;
      }
      final board = _boardFromEvent(view, item);
      return board == null
          ? view
          : view.copyWith(boards: _upsertProjectRow(view.boards, board, (b) => b.id));
    case 'boardDelete':
      if (id is! String) return view;
      return view.copyWith(
          boards: view.boards.where((board) => board.id != id).toList());
    case 'projectManagerCreate':
      final projectId = item['projectId'];
      if (projectId is! String ||
          !view.projects.any((project) => project.id == projectId)) {
        return view;
      }
      final manager = _managerFromEvent(view, item);
      return manager == null
          ? view
          : view.copyWith(
              managers: _upsertProjectRow(view.managers, manager, (m) => m.id));
    case 'projectManagerDelete':
      if (id is! String) return view;
      return view.copyWith(managers: view.managers
          .where((manager) => manager.id != id)
          .toList());
    case 'backgroundImageCreate':
      final projectId = item['projectId'];
      final knownImage = view.backgroundImages.any((image) => image.id == id);
      if (!knownImage &&
          (projectId is! String ||
              !view.projects.any((project) => project.id == projectId))) {
        return view;
      }
      final image = _backgroundImageFromEvent(view, item);
      return image == null
          ? view
          : view.copyWith(
              backgroundImages:
                  _upsertProjectRow(view.backgroundImages, image, (i) => i.id));
    case 'backgroundImageDelete':
      if (id is! String) return view;
      return view.copyWith(backgroundImages: view.backgroundImages
          .where((image) => image.id != id)
          .toList());
    case 'userUpdate':
      if (id is! String || !view.users.any((user) => user.id == id)) return view;
      final user = _userFromEvent(view, item);
      return user == null
          ? view
          : view.copyWith(users: _upsertProjectRow(view.users, user, (u) => u.id));
    case 'userDelete':
      if (id is! String) return view;
      return view.copyWith(
          users: view.users.where((user) => user.id != id).toList());
    case 'baseCustomFieldGroupCreate' || 'baseCustomFieldGroupUpdate':
      final projectId = item['projectId'];
      final existing = view.baseCustomFieldGroups
          .where((group) => group.id == id)
          .firstOrNull;
      final knownProject = existing?.projectId ?? projectId;
      if (knownProject is! String ||
          !view.projects.any((project) => project.id == knownProject)) {
        return view;
      }
      final group = _baseGroupFromEvent(view, item);
      return group == null
          ? view
          : view.copyWith(baseCustomFieldGroups: _upsertProjectRow(
              view.baseCustomFieldGroups, group, (g) => g.id));
    case 'baseCustomFieldGroupDelete':
      if (id is! String) return view;
      final group = view.baseCustomFieldGroups
          .where((candidate) => candidate.id == id)
          .firstOrNull;
      if (group == null) return view;
      return view.copyWith(
        baseCustomFieldGroups: view.baseCustomFieldGroups
            .where((candidate) => candidate.id != id)
            .toList(),
        customFields: view.customFields
            .where((field) => field.baseCustomFieldGroupId != id)
            .toList(),
      );
    case 'customFieldCreate' || 'customFieldUpdate':
      final existing = view.customFields
          .where((field) => field.id == id)
          .firstOrNull;
      final baseId = item['baseCustomFieldGroupId'] ??
          existing?.baseCustomFieldGroupId;
      if (baseId is! String ||
          !view.baseCustomFieldGroups.any((group) => group.id == baseId)) {
        return view;
      }
      final field = _customFieldFromEvent(view, item);
      return field == null
          ? view
          : view.copyWith(
              customFields: _upsertProjectRow(view.customFields, field, (f) => f.id));
    case 'customFieldDelete':
      if (id is! String) return view;
      return view.copyWith(customFields: view.customFields
          .where((field) => field.id != id)
          .toList());
    default:
      return view;
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, ProjectsView>(ProjectsNotifier.new);

class ProjectsNotifier extends AsyncNotifier<ProjectsView> {
  PlankaRepo get _repo => PlankaRepo(ref.read(apiProvider));

  StreamSubscription<SocketEvent>? _userEventsSub;
  StreamSubscription<bool>? _userConnectedSub;
  var _ready = false;
  int? _resyncSession;
  var _resyncRequested = false;
  var _eventVersion = 0;
  var _session = 0;

  @override
  Future<ProjectsView> build() async {
    // Re-fetch when the active account (and thus the API client) changes.
    ref.watch(apiProvider);
    final userEvents = ref.watch(userEventsProvider);
    final userConnected = ref.watch(userConnectedProvider);
    final session = ++_session;
    _ready = false;
    _resyncRequested = false;
    _eventVersion = 0;
    _userEventsSub?.cancel();
    _userConnectedSub?.cancel();
    _userEventsSub = userEvents.listen(
      (event) => _onUserEvent(session, event),
      onError: (Object error) => _onUserRoomError(session, error),
    );
    _userConnectedSub = userConnected.listen(
      (connected) {
        if (connected) {
          _eventVersion++;
          _queueResync(session);
        }
      },
    );
    ref.onDispose(() {
      _userEventsSub?.cancel();
      _userConnectedSub?.cancel();
    });

    try {
      var version = _eventVersion;
      final loaded = await _fetch();
      var view = loaded;
      // Events can arrive after the listener is attached but before the initial
      // REST response completes. Fold no stale snapshot into state: reconcile
      // from the server until the response covers the latest event edge.
      while (version != _eventVersion) {
        version = _eventVersion;
        view = await _fetch(fresh: true);
      }
      if (session != _session) return view;
      _resyncRequested = false;
      return view;
    } finally {
      if (session == _session) _ready = true;
    }
  }

  /// Ordinary list load: serve the last good copy when the network is down
  /// (offline read cache). This is the only path that may fall back to the
  /// cache, and it is safe because a failed confirming refresh has already
  /// deleted the stale copy (see [_mutate]) — so there is no pre-mutation
  /// value left to serve. A cold start over the same cache directory takes
  /// this same path and therefore never resurrects a reverted list.
  Future<ProjectsView> _fetch({bool fresh = false}) async {
    final accountId = ref.read(currentAccountProvider)?.id;
    // Initial loads may use the offline cache; reconciliation must bypass it.
    final env = fresh
        ? await _freshProjects(accountId)
        : accountId == null
            ? await _repo.projects()
            : await ref
                .read(envelopeCacheProvider)
                .fetchOrCached('$accountId-projects', _repo.projects);
    return _view(env);
  }

  ProjectsView _view(Envelope env) => ProjectsView(
        projects: env.items.map(PlankaProject.fromJson).toList(),
        boards: env.included.boards,
        backgroundImages: env.included.backgroundImages,
        managers: env.included.projectManagers,
        users: env.included.users,
        baseCustomFieldGroups: env.included.baseCustomFieldGroups,
        customFields: env.included.customFields,
      );

  Future<Envelope> _freshProjects(String? accountId) async {
    final env = await _repo.projects();
    if (accountId != null) {
      await ref
          .read(envelopeCacheProvider)
          .put('$accountId-projects', env);
    }
    return env;
  }

  void _onUserEvent(int session, SocketEvent event) {
    if (session != _session ||
        !kProjectsUserRoomEvents.contains(event.name)) {
      return;
    }
    _eventVersion++;
    final current = state.value;
    if (current != null) {
      final next = applyProjectsEvent(current, event);
      if (!identical(next, current)) state = AsyncData(next);
    }
    _queueResync(session);
  }

  void _onUserRoomError(int session, Object error) {
    if (session != _session) return;
    debugPrint('projects user room error: $error');
    _eventVersion++;
    _queueResync(session);
  }

  void _queueResync(int session) {
    if (session != _session) return;
    _resyncRequested = true;
    if (_ready && _resyncSession == null) unawaited(_drainResync(session));
  }

  /// Serializes fresh responses and discards one that crossed a newer event.
  /// Without the version check, a slow GET could resurrect a deleted row.
  Future<void> _drainResync(int session) async {
    if (session != _session || !_ready || _resyncSession != null) return;
    _resyncSession = session;
    try {
      while (session == _session && _resyncRequested) {
        _resyncRequested = false;
        final version = _eventVersion;
        try {
          final view = await _fetch(fresh: true);
          if (session != _session) return;
          if (version != _eventVersion) {
            _resyncRequested = true;
            continue;
          }
          state = AsyncData(view);
        } on Object catch (error, stackTrace) {
          debugPrint('projects realtime resync failed: $error\n$stackTrace');
        }
      }
    } finally {
      if (_resyncSession == session) _resyncSession = null;
      if (_ready && _resyncRequested && _resyncSession == null) {
        unawaited(_drainResync(_session));
      }
    }
  }

  // ponytail: no optimistic updates here — project/board CRUD is rare, so each
  // mutation awaits the server then refetches the (small) projects payload.
  //
  // The write callback receives the repo captured at the start of the
  // mutation: no code inside a mutation may reach for the ambient client
  // after the write has started, so a mid-write account switch can never send
  // a follow-up request through the new account's client.
  Future<void> _mutate(Future<Object?> Function(PlankaRepo) call) async {
    // Capture the account and its API client before the write: the write,
    // the confirming refresh and any cache cleanup must all act on the
    // account the write targeted, not whichever account is active when the
    // write happens to return. If the user switches accounts mid-write,
    // acting on the new account would delete its valid cache entry while the
    // old account's stale copy survives.
    final account = ref.read(currentAccountProvider);
    final accountId = account?.id;
    final repo = PlankaRepo(ref.read(apiProvider));
    final cache = ref.read(envelopeCacheProvider);
    // A mutation may only publish to state while this notifier still
    // represents the account it captured. Riverpod preserves the notifier
    // across an account-switch rebuild (it is not disposed), so without this
    // check a write captured against A would land A's result — or A's
    // refresh error — on the screen B is now reading. Decided from
    // mounted-and-still-current state, not from what throws.
    bool stillCurrent() =>
        ref.mounted && ref.read(currentAccountProvider)?.id == accountId;
    await call(repo);
    try {
      // The confirming refresh must hit the server, never the cache: the
      // cached copy is the pre-mutation state. On success it is replaced with
      // the post-mutation result (fetchAndCache), so the next offline start
      // sees the new values.
      final env = accountId == null
          ? await repo.projects()
          : await cache.fetchAndCache('$accountId-projects', repo.projects);
      if (stillCurrent()) state = AsyncData(_view(env));
    } catch (e, s) {
      // The write landed but the confirming refresh failed. The cached copy
      // is the pre-mutation state; delete it so no later load — retry,
      // pull-to-refresh, or a cold start that never saw the mutation — can
      // serve it as fresh truth. The next load must reach the server, so
      // while it is down the list stays an error instead of reverting. This
      // is about the account that was written to, so it runs regardless of
      // whether that account is still on screen.
      if (accountId != null) await cache.delete('$accountId-projects');
      // Same guard as the success path: do not publish the captured account's
      // error onto a different account's screen. The mutation's own future
      // still rejects with the real refresh error below, either way.
      if (stillCurrent()) state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> createProject(String name) =>
      _mutate((repo) => repo.createProject(name));

  Future<void> renameProject(String id, String name) =>
      _mutate((repo) => repo.updateProject(id, {'name': name}));

  Future<void> deleteProject(String id) =>
      _mutate((repo) => repo.deleteProject(id));

  Future<void> setProjectFavorite(String id, {required bool favorite}) =>
      _mutate((repo) => repo.updateProject(id, {'isFavorite': favorite}));

  Future<void> createBoard(String projectId, String name) => _mutate((repo) {
        final last = (state.value?.boards ?? const [])
            .where((b) => b.projectId == projectId)
            .lastOrNull
            ?.position;
        return repo.createBoard(projectId,
            name: name,
            position: last == null ? kPositionGap : last + kPositionGap);
      });

  Future<void> addProjectManager(String projectId, String userId) =>
      _mutate((repo) => repo.addProjectManager(projectId, userId));

  Future<void> removeProjectManager(String id) =>
      _mutate((repo) => repo.removeProjectManager(id));

  Future<void> setProjectGradient(String id, String gradient) =>
      _mutate((repo) => repo.updateProject(
          id, {'backgroundType': 'gradient', 'backgroundGradient': gradient}));

  Future<void> setProjectBackgroundImage(String id,
          {required String filePath, required String name}) =>
      _mutate((repo) async {
        await repo.uploadProjectBackgroundImage(id,
            filePath: filePath, name: name);
        return repo.updateProject(id, {'backgroundType': 'image'});
      });

  Future<void> clearProjectBackground(String id) =>
      _mutate((repo) => repo.updateProject(id, {'backgroundType': null}));

  Future<void> renameBoard(String id, String name) =>
      _mutate((repo) => repo.updateBoard(id, {'name': name}));

  Future<void> deleteBoard(String id) => _mutate((repo) => repo.deleteBoard(id));

  // --------------- Custom field template mutations ---------------
  // Each awaits the server then refetches the projects payload, like every
  // other mutation above. Deletes fire only after the sheet's confirmation
  // has resolved true — nothing here is ever sent optimistically.

  Future<void> createTemplate(String projectId, String name) =>
      _mutate((repo) => repo.createBaseCustomFieldGroup(projectId, name: name));

  Future<void> renameTemplate(String id, String name) =>
      _mutate((repo) => repo.updateBaseCustomFieldGroup(id, {'name': name}));

  Future<void> deleteTemplate(String id) =>
      _mutate((repo) => repo.deleteBaseCustomFieldGroup(id));

  Future<void> createTemplateField(String templateId, String name) {
    final last = state.value?.fieldsOfBaseGroup(templateId).lastOrNull?.position;
    return _mutate((repo) => repo.createBaseCustomField(templateId,
        name: name, position: positionBetween(last, null)));
  }

  Future<void> renameTemplateField(String id, String name) =>
      _mutate((repo) => repo.updateCustomField(id, {'name': name}));

  Future<void> toggleTemplateFieldFrontOfCard(String id, bool show) =>
      _mutate((repo) => repo.updateCustomField(id, {'showOnFrontOfCard': show}));

  Future<void> deleteTemplateField(String id) =>
      _mutate((repo) => repo.deleteCustomField(id));

  Future<void> moveTemplateFieldUp(String id) =>
      _moveTemplateField(id, up: true);

  Future<void> moveTemplateFieldDown(String id) =>
      _moveTemplateField(id, up: false);

  Future<void> _moveTemplateField(String id, {required bool up}) async {
    final view = state.value;
    final field = view?.customFields.where((f) => f.id == id).firstOrNull;
    final templateId = field?.baseCustomFieldGroupId;
    if (view == null || field == null || templateId == null) return;
    final peers = view.fieldsOfBaseGroup(templateId);
    final idx = peers.indexWhere((f) => f.id == id);
    if (idx < 0) return;
    final double? position;
    if (up) {
      if (idx == 0) return;
      position = positionBetween(
          idx > 1 ? peers[idx - 2].position : null, peers[idx - 1].position);
    } else {
      if (idx >= peers.length - 1) return;
      position = positionBetween(peers[idx + 1].position,
          idx + 2 < peers.length ? peers[idx + 2].position : null);
    }
    await _mutate(
        (repo) => repo.updateCustomField(id, {'position': position}));
  }
}
