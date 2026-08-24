import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/envelope.dart';

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
