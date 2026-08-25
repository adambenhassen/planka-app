import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/planka_socket.dart';
import 'package:planka_app/api/repositories.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/state/board_state.dart';

PlankaList list(String id, PlankaListType type) =>
    PlankaList(id: id, boardId: 'b1', type: type, name: id);

PlankaCard card(String id, String listId, {bool? isClosed}) => PlankaCard(
  id: id,
  boardId: 'b1',
  listId: listId,
  type: 'project',
  name: id,
  isClosed: isClosed,
);

PlankaTask task({
  bool completed = false,
  String? linkedCardId,
  String? assigneeUserId,
}) => PlankaTask(
  id: 't1',
  taskListId: 'tl1',
  name: 'Do it',
  isCompleted: completed,
  linkedCardId: linkedCardId,
  assigneeUserId: assigneeUserId,
);

/// Active l1 and closed l2; open card c1 sits in l1, closed card c2 in l2.
BoardState state({List<PlankaTask>? tasks, Map<String, PlankaCard>? cards}) {
  final allCards =
      cards ?? {'c1': card('c1', 'l1'), 'c2': card('c2', 'l2', isClosed: true)};
  return BoardState(
    board: PlankaBoard(id: 'b1', projectId: 'p1', name: 'B'),
    lists: [
      list('l1', PlankaListType.active),
      list('l2', PlankaListType.closed),
    ],
    cards: allCards,
    tasks: tasks ?? const [],
  );
}

void main() {
  group('isTaskCompleted', () {
    test('an unlinked item keeps its own flag either way', () {
      final s = state();
      expect(s.isTaskCompleted(task(completed: true)), isTrue);
      expect(s.isTaskCompleted(task(completed: false)), isFalse);
    });

    test('a linked item follows the linked closed card', () {
      final s = state(tasks: [task(linkedCardId: 'c2')]);
      expect(s.isTaskCompleted(s.tasks.first), isTrue);
    });

    test('a linked item is not completed while the card stays open', () {
      final s = state(tasks: [task(linkedCardId: 'c1', completed: true)]);
      expect(s.isTaskCompleted(s.tasks.first), isFalse);
    });

    test('derives from the list type when isClosed is absent', () {
      final s = state(
        cards: {'c3': card('c3', 'l2')},
        tasks: [task(linkedCardId: 'c3')],
      );
      expect(s.isTaskCompleted(s.tasks.first), isTrue);
    });

    test('falls back to the own flag for a linked card not on this board', () {
      final s = state(
        tasks: [task(linkedCardId: 'elsewhere', completed: true)],
      );
      expect(s.isTaskCompleted(s.tasks.first), isTrue);
    });
  });

  group('realtime', () {
    test('moving the linked card into the closed list completes the item', () {
      // isClosed is a persisted column defaulting to false, so a real open
      // card arrives as false, never null.
      final s = state(
        cards: {'c1': card('c1', 'l1', isClosed: false)},
        tasks: [task(linkedCardId: 'c1')],
      );
      expect(s.isTaskCompleted(s.tasks.first), isFalse);

      final moved = applyEvent(
        s,
        SocketEvent.parse('cardUpdate', {
          'item': {'id': 'c1', 'listId': 'l2'},
        }),
      );
      expect(moved.isTaskCompleted(moved.tasks.first), isTrue);

      final back = applyEvent(
        moved,
        SocketEvent.parse('cardUpdate', {
          'item': {'id': 'c1', 'listId': 'l1'},
        }),
      );
      expect(back.isTaskCompleted(back.tasks.first), isFalse);
    });

    test('a partial taskUpdate keeps assignee and link fields', () {
      final s = state(
        tasks: [task(linkedCardId: 'c2', assigneeUserId: 'u9')],
      );
      // A reposition broadcasts just {id, position}.
      final next = applyEvent(
        s,
        SocketEvent.parse('taskUpdate', {
          'item': {'id': 't1', 'position': 5.0},
        }),
      );
      expect(next.tasks.first.linkedCardId, 'c2');
      expect(next.tasks.first.assigneeUserId, 'u9');
    });
  });

  group('setTaskAssignee', () {
    late _FakeApi api;
    late ProviderContainer container;
    late BoardNotifier notifier;

    setUp(() async {
      api = _FakeApi();
      container = ProviderContainer(
        overrides: [
          apiProvider.overrideWithValue(api),
          boardProvider.overrideWith2((arg) => _SocketlessNotifier(arg)),
        ],
      );
      await container.read(boardProvider('b1').future);
      notifier = container.read(boardProvider('b1').notifier);
    });

    tearDown(() => container.dispose());

    test('assigns optimistically and PATCHes the id', () async {
      await notifier.setTaskAssignee('t1', 'u9');
      expect(api.patchPaths, ['/tasks/t1']);
      expect(api.patchBodies.single, {'assigneeUserId': 'u9'});
      expect(
        container.read(boardProvider('b1')).value!.tasks.first.assigneeUserId,
        'u9',
      );
    });

    test('unassign sends a null assignee', () async {
      await notifier.setTaskAssignee('t1', null);
      expect(api.patchBodies.single, {'assigneeUserId': null});
    });
  });
}

class _FakeApi extends PlankaApi {
  _FakeApi() : super('http://x', 'tok');
  final List<String> patchPaths = [];
  final List<Map<String, dynamic>> patchBodies = [];

  @override
  Future<Envelope> get(String path, {Map<String, dynamic>? query}) async =>
      Envelope.parse({
        'item': {'id': 'b1', 'projectId': 'p1', 'name': 'B'},
        'included': {
          'lists': [
            {'id': 'l1', 'boardId': 'b1', 'type': 'active'},
            {'id': 'l2', 'boardId': 'b1', 'type': 'closed'},
          ],
          'cards': [
            {
              'id': 'c1',
              'boardId': 'b1',
              'listId': 'l1',
              'type': 'project',
              'name': 'c1',
            },
          ],
          'taskLists': [
            {'id': 'tl1', 'cardId': 'c1', 'name': 'Checklist'},
          ],
          'tasks': [
            {
              'id': 't1',
              'taskListId': 'tl1',
              'name': 'Do it',
              'isCompleted': false,
              'linkedCardId': null,
              'assigneeUserId': null,
            },
          ],
        },
      });

  @override
  Future<Envelope> patch(String path, Object? body) async {
    patchPaths.add(path);
    patchBodies.add((body as Map).cast<String, dynamic>());
    return Envelope.parse({'item': body});
  }
}

class _SocketlessNotifier extends BoardNotifier {
  _SocketlessNotifier(super.boardId);
  @override
  Future<BoardState> build() async => BoardState.fromEnvelope(
    await PlankaRepo(ref.read(apiProvider)).board(boardId),
  );
}
