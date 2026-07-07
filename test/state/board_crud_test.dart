import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/board_show.json').readAsStringSync())
        as Map<String, dynamic>;

/// Serves the untouched board on GET; echoes PATCH/POST bodies; returns an
/// empty item on DELETE. Set [fail] to drive the heal-on-failure path.
class _FakeApi extends PlankaApi {
  _FakeApi({this.fail = false}) : super('http://x', 'tok');
  final bool fail;
  int getCalls = 0;

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async {
    getCalls++;
    return Envelope.parse(_fixture());
  }

  @override
  Future<Envelope> patch(String path, Object? body) async {
    if (fail) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': (body as Map).cast<String, dynamic>()});
  }

  @override
  Future<Envelope> delete(String path) async {
    if (fail) throw ApiException(500, 'rejected');
    return Envelope.parse({'item': <String, dynamic>{}});
  }

  @override
  Future<Envelope> post(String path, Object? body) async =>
      Envelope.parse({'item': <String, dynamic>{}});
}

/// Real BoardNotifier logic seeded from the fixture, no live socket. [seed]
/// lets a test inject extra rows (e.g. a comment the fixture lacks).
class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId, {this.seed});
  final BoardState Function(BoardState)? seed;
  @override
  Future<BoardState> build() async {
    final base = BoardState.fromEnvelope(Envelope.parse(_fixture()));
    return seed?.call(base) ?? base;
  }
}

Future<(ProviderContainer, BoardNotifier, String)> boot({
  bool fail = false,
  BoardState Function(BoardState)? seed,
}) async {
  final container = ProviderContainer(overrides: [
    apiProvider.overrideWithValue(_FakeApi(fail: fail)),
    boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg, seed: seed)),
  ]);
  final boardId = _fixture()['item']['id'] as String;
  await container.read(boardProvider(boardId).future);
  return (container, container.read(boardProvider(boardId).notifier), boardId);
}

void main() {
  test('archiveCard moves the card into the archive-type list', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final s0 = container.read(boardProvider(boardId)).value!;
    final cardId = s0.cards.values.first.id;
    final archiveId =
        s0.lists.firstWhere((l) => l.type == PlankaListType.archive).id;

    await notifier.archiveCard(cardId);

    final s1 = container.read(boardProvider(boardId)).value!;
    expect(s1.cards[cardId]!.listId, archiveId);
  });

  test('renameList patches the list name optimistically', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final listId =
        container.read(boardProvider(boardId)).value!.columns.first.id;

    await notifier.renameList(listId, 'Renamed');

    final s = container.read(boardProvider(boardId)).value!;
    expect(s.lists.firstWhere((l) => l.id == listId).name, 'Renamed');
  });

  test('deleteList removes the list and its cards', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final s0 = container.read(boardProvider(boardId)).value!;
    final listId = s0.cards.values.first.listId;
    expect(s0.cardsOf(listId), isNotEmpty,
        reason: 'precondition: list has cards');

    await notifier.deleteList(listId);

    final s1 = container.read(boardProvider(boardId)).value!;
    expect(s1.lists.any((l) => l.id == listId), isFalse);
    expect(s1.cards.values.any((c) => c.listId == listId), isFalse,
        reason: 'cascade drops the deleted list\'s cards');
  });

  test('deleteList heals list AND cards back on failure, then rethrows',
      () async {
    final (container, notifier, boardId) = await boot(fail: true);
    addTearDown(container.dispose);
    final s0 = container.read(boardProvider(boardId)).value!;
    final listId = s0.cards.values.first.listId;
    final cardCount = s0.cardsOf(listId).length;
    final api = container.read(apiProvider) as _FakeApi;
    final getsBefore = api.getCalls;

    await expectLater(
        notifier.deleteList(listId), throwsA(isA<ApiException>()));

    final s1 = container.read(boardProvider(boardId)).value!;
    expect(s1.lists.any((l) => l.id == listId), isTrue,
        reason: 'failed delete heals the list back from server truth');
    expect(s1.cardsOf(listId).length, cardCount,
        reason: 'cascade-removed cards are restored by the refetch too');
    expect(api.getCalls, greaterThan(getsBefore),
        reason: 'failure triggers a refetch');
  });

  test('editLabel patches name and color optimistically', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final labelId =
        container.read(boardProvider(boardId)).value!.labels.first.id;

    await notifier.editLabel(labelId, name: 'Urgent', color: 'berry-red');

    final label = container
        .read(boardProvider(boardId))
        .value!
        .labels
        .firstWhere((l) => l.id == labelId);
    expect(label.name, 'Urgent');
    expect(label.color, 'berry-red');
  });

  test('deleteLabel removes the label and its card-label links', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final labelId =
        container.read(boardProvider(boardId)).value!.labels.first.id;

    await notifier.deleteLabel(labelId);

    final s = container.read(boardProvider(boardId)).value!;
    expect(s.labels.any((l) => l.id == labelId), isFalse);
    expect(s.cardLabels.any((cl) => cl.labelId == labelId), isFalse);
  });

  test('renameTaskList patches the checklist name', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final id = container.read(boardProvider(boardId)).value!.taskLists.first.id;

    await notifier.renameTaskList(id, 'Checklist A');

    expect(
        container
            .read(boardProvider(boardId))
            .value!
            .taskLists
            .firstWhere((t) => t.id == id)
            .name,
        'Checklist A');
  });

  test('deleteTaskList removes the checklist and its tasks', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final id = container.read(boardProvider(boardId)).value!.taskLists.first.id;

    await notifier.deleteTaskList(id);

    final s = container.read(boardProvider(boardId)).value!;
    expect(s.taskLists.any((t) => t.id == id), isFalse);
    expect(s.tasks.any((t) => t.taskListId == id), isFalse);
  });

  test('renameTask patches the task name', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final id = container.read(boardProvider(boardId)).value!.tasks.first.id;

    await notifier.renameTask(id, 'Do the thing');

    expect(
        container
            .read(boardProvider(boardId))
            .value!
            .tasks
            .firstWhere((t) => t.id == id)
            .name,
        'Do the thing');
  });

  test('deleteTask removes the task', () async {
    final (container, notifier, boardId) = await boot();
    addTearDown(container.dispose);
    final id = container.read(boardProvider(boardId)).value!.tasks.first.id;

    await notifier.deleteTask(id);

    expect(
        container.read(boardProvider(boardId)).value!.tasks
            .any((t) => t.id == id),
        isFalse);
  });

  test('editComment patches the comment text', () async {
    final (container, notifier, boardId) = await boot(
      seed: (s) {
        final card = s.cards.values.first;
        return s.copyWith(comments: [
          PlankaComment.fromJson({
            'id': 'c-seed',
            'cardId': card.id,
            'userId': 'u1',
            'text': 'original',
          }),
        ]);
      },
    );
    addTearDown(container.dispose);

    await notifier.editComment('c-seed', 'edited');

    expect(
        container.read(boardProvider(boardId)).value!.comments
            .firstWhere((c) => c.id == 'c-seed').text,
        'edited');
  });
}
