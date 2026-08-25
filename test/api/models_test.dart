import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('parses board show envelope', () {
    final env = Envelope.parse(fixture('board_show'));
    expect(env.item['id'], isA<String>());
    expect(env.included.lists, isNotEmpty);
    expect(env.included.lists.first.name, 'To Do');
    expect(env.included.cards.first.position, greaterThan(0));
    expect(env.included.cards.first.isClosed, isFalse);
    expect(env.included.taskLists, isNotEmpty);
    expect(env.included.tasks, isNotEmpty);
    expect(env.included.tasks.first.linkedCardId, isNull);
    expect(env.included.tasks.first.assigneeUserId, isNull);
    expect(env.included.taskLists.first.showOnFrontOfCard, isTrue);
    expect(env.included.taskLists.first.hideCompletedTasks, isFalse);
    expect(env.included.labels.first.color, isNotEmpty);
  });

  test('task assignee and linked-card fields parse when set', () {
    final env = Envelope.parse({
      'item': {'id': 'b1'},
      'included': {
        'tasks': [
          {
            'id': 't1',
            'taskListId': 'tl1',
            'name': 'Do it',
            'isCompleted': true,
            'assigneeUserId': 'u9',
            'linkedCardId': 'c9',
          },
        ],
        'cards': [
          {
            'id': 'c9',
            'boardId': 'b1',
            'listId': 'l1',
            'type': 'project',
            'name': 'Linked',
            'isClosed': true,
          },
        ],
      },
    });
    expect(env.included.tasks.single.assigneeUserId, 'u9');
    expect(env.included.tasks.single.linkedCardId, 'c9');
    expect(env.included.cards.single.isClosed, isTrue);
  });

  test('task list display flags parse and survive a round trip', () {
    const tl = PlankaTaskList(
      id: 'tl1',
      cardId: 'c1',
      name: 'Checklist',
      showOnFrontOfCard: true,
      hideCompletedTasks: true,
    );
    expect(tl.toJson()['showOnFrontOfCard'], isTrue);
    expect(tl.toJson()['hideCompletedTasks'], isTrue);
    expect(PlankaTaskList.fromJson(tl.toJson()), tl);

    // Planka's model defaults showOnFrontOfCard to true, so an absent key
    // means on-front; only a present false hides the list.
    final absent = PlankaTaskList.fromJson({
      'id': 'tl2',
      'cardId': 'c1',
      'name': 'Bare',
    });
    expect(absent.showOnFrontOfCard, isTrue);
    expect(absent.hideCompletedTasks, isNull);
    expect(PlankaTaskList.fromJson(absent.toJson()), absent);

    final hidden = PlankaTaskList.fromJson({
      'id': 'tl3',
      'cardId': 'c1',
      'name': 'Hidden',
      'showOnFrontOfCard': false,
    });
    expect(hidden.showOnFrontOfCard, isFalse);
    expect(PlankaTaskList.fromJson(hidden.toJson()), hidden);

    // hideCompletedTasks has no model default; an absent key stays null.
    final bare = PlankaTaskList(id: 'tl4', cardId: 'c1', name: 'Bare');
    expect(bare.showOnFrontOfCard, isTrue);
    expect(bare.hideCompletedTasks, isNull);
    expect(PlankaTaskList.fromJson(bare.toJson()), bare);
  });

  test('parses projects index', () {
    final env = Envelope.parse(fixture('projects_index'));
    expect(env.items, isNotEmpty);
  });

  test('login item is raw jwt string', () {
    final json = fixture('login');
    expect(json['item'], isA<String>());
  });

  test('accessToken reads included.accessToken, null when absent', () {
    final env = Envelope.parse({
      'item': {'id': 'u1'},
      'included': {'accessToken': 'jwt'},
    });
    expect(env.accessToken, 'jwt');
    expect(
      Envelope.parse({
        'item': {'id': 'u1'},
      }).accessToken,
      null,
    );
  });
}
