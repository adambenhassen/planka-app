import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

BoardState _seed() =>
    BoardState.fromEnvelope(Envelope.parse(_json('board_show_custom_fields')))
        .withBaseCustomFields(
            Envelope.parse(_json('project_show_custom_fields')));

String _cardId() =>
    ((_json('board_show_custom_fields')['included']
        as Map)['cards'] as List).first['id'] as String;

/// Serves the custom-field board and its project, counting the project reads
/// so a board without a based group can be shown to make no extra request.
/// With [failProject] the project read is rejected, the degraded case where
/// the board envelope is cached but the project one never was.
class _FakeApi extends PlankaApi {
  _FakeApi({required this.boardFixture, this.failProject = false})
      : super('http://x', 'tok');
  final String boardFixture;
  final bool failProject;
  int projectCalls = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    if (path.startsWith('/projects/')) {
      projectCalls++;
      if (failProject) throw ApiException(503, 'offline');
      return Envelope.parse(_json('project_show_custom_fields'));
    }
    return Envelope.parse(_json(boardFixture));
  }
}

/// The real load path (board fetch plus the project fetch a based group
/// needs), without the socket a test has no server for.
class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() => load();
}

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() => Account(
      serverUrl: 'http://x',
      token: 'tok',
      userId: 'u1',
      displayName: 'U');
}

Future<(ProviderContainer, BoardState, _FakeApi)> _boot(String boardFixture,
    {bool failProject = false}) async {
  final api =
      _FakeApi(boardFixture: boardFixture, failProject: failProject);
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(api),
    // A signed-in account, so the load takes the same cache-backed path
    // production does rather than a test-only shortcut.
    currentAccountProvider.overrideWith(_AccNotifier.new),
    boardProvider.overrideWith2(_SocketlessNotifier.new),
  ]);
  final boardId = _json(boardFixture)['item']['id'] as String;
  final state = await container.read(boardProvider(boardId).future);
  return (container, state, api);
}

void main() {
  test('parses the three custom field collections off the board envelope', () {
    final s = BoardState.fromEnvelope(
        Envelope.parse(_json('board_show_custom_fields')));

    expect(s.customFieldGroups.map((g) => g.name), contains('BG'));
    expect(s.customFields.map((f) => f.name), contains('F'));
    expect(s.customFieldValues.map((v) => v.content), contains('hello'));
  });

  test('shows board groups before card groups, each in position order', () {
    final groups = _seed().customFieldGroupsOf(_cardId());

    // Board: the based group (16384) then BG (32768); card: CG.
    expect(_seed().customFieldGroupName(groups[0]), 'Base');
    expect(groups[1].name, 'BG');
    expect(groups[2].name, 'CG');
    expect(groups, hasLength(3));
  });

  test('lists a group\'s fields in position order', () {
    final s = _seed();
    final bg = s.customFieldGroups.firstWhere((g) => g.name == 'BG');

    expect(s.customFieldsOf(bg).map((f) => f.name), ['F', 'Front', 'Empty']);
  });

  test('an instantiated group takes its name and fields from the base group',
      () {
    final s = _seed();
    final based =
        s.customFieldGroups.firstWhere((g) => g.baseCustomFieldGroupId != null);

    expect(s.customFieldGroupName(based), 'Base');
    expect(s.customFieldsOf(based).map((f) => f.name), ['BF']);
    expect(s.customFieldValueOf(_cardId(), based.id, s.customFieldsOf(based).first.id)?.content,
        'based');
  });

  test('folding the project in twice does not duplicate its fields', () {
    // A group instantiated while the board is open sends the app back to the
    // project, on a state that already holds base fields.
    final s = _seed()
        .withBaseCustomFields(Envelope.parse(_json('project_show_custom_fields')));
    final based =
        s.customFieldGroups.firstWhere((g) => g.baseCustomFieldGroupId != null);

    expect(s.customFieldsOf(based).map((f) => f.name), ['BF']);
    expect(s.needsBaseCustomFields, isFalse);
  });

  test('reads a value by (group, field), and null when none is set', () {
    final s = _seed();
    final cardId = _cardId();
    final bg = s.customFieldGroups.firstWhere((g) => g.name == 'BG');
    final f = s.customFieldsOf(bg).firstWhere((x) => x.name == 'F');
    final empty = s.customFieldsOf(bg).firstWhere((x) => x.name == 'Empty');

    expect(s.customFieldValueOf(cardId, bg.id, f.id)?.content, 'hello');
    expect(s.customFieldValueOf(cardId, bg.id, empty.id), isNull);
  });

  test('front-of-card takes only flagged fields that hold a value', () {
    final front = _seed().frontOfCardCustomFieldsOf(_cardId());

    // Front is flagged and set; Empty is flagged but unset; F and CF and BF
    // hold values but are not flagged.
    expect(front.map((e) => (e.$1.name, e.$2.content)), [('Front', 'on front')]);
  });

  test('a board with no custom fields exposes none', () {
    final s = BoardState.fromEnvelope(Envelope.parse(_json('board_show')));
    final cardId =
        ((_json('board_show')['included'] as Map)['cards'] as List).first['id']
            as String;

    expect(s.customFieldGroupsOf(cardId), isEmpty);
    expect(s.frontOfCardCustomFieldsOf(cardId), isEmpty);
  });

  test('loading a board with a based group fetches the project once', () async {
    final (container, state, api) = await _boot('board_show_custom_fields');
    addTearDown(container.dispose);

    expect(api.projectCalls, 1);
    final based =
        state.customFieldGroups.firstWhere((g) => g.baseCustomFieldGroupId != null);
    expect(state.customFieldGroupName(based), 'Base');
  });

  test('loading a board with no custom fields skips the project fetch',
      () async {
    final (container, _, api) = await _boot('board_show');
    addTearDown(container.dispose);

    expect(api.projectCalls, 0);
  });

  test('a rejected project read still loads the board', () async {
    final (container, state, api) = await _boot('board_show_custom_fields',
        failProject: true);
    addTearDown(container.dispose);

    expect(api.projectCalls, 1);
    expect(state.cards, isNotEmpty, reason: 'the board itself still loads');
  });

  test('a group left with no name and no fields is not shown', () async {
    final (container, state, _) = await _boot('board_show_custom_fields',
        failProject: true);
    addTearDown(container.dispose);

    // The instantiated group resolved to nothing, so it would render as an
    // untitled empty block. The groups that did resolve are unaffected.
    final shown = state.customFieldGroupsOf(_cardId());
    expect(shown.map((g) => g.name), ['BG', 'CG']);
  });
}
