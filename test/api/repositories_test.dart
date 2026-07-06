import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/api/repositories.dart';

void main() {
  late HttpServer server;
  late PlankaRepo repo;
  late String method;
  late String path;
  Map<String, dynamic>? body;

  setUp(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      method = req.method;
      path = req.uri.toString();
      final raw = await utf8.decoder.bind(req).join();
      body = raw.isEmpty || !raw.startsWith('{')
          ? null
          : jsonDecode(raw) as Map<String, dynamic>;
      req.response.headers.contentType = ContentType.json;
      req.response.write('{"item":{"id":"1"}}');
      await req.response.close();
    });
    repo = PlankaRepo(PlankaApi('http://127.0.0.1:${server.port}', 'tok'));
  });

  tearDown(() => server.close());

  test('repo methods hit exact endpoints', () async {
    final cases = <(Future<Object?> Function(), String, String, Map<String, dynamic>?)>[
      (() => repo.projects(), 'GET', '/api/projects', null),
      (() => repo.board('b1'), 'GET', '/api/boards/b1', null),
      (
        () => repo.createList('b1', name: 'L', position: 16384),
        'POST',
        '/api/boards/b1/lists',
        {'type': 'active', 'name': 'L', 'position': 16384}
      ),
      (() => repo.updateList('l1', {'name': 'X'}), 'PATCH', '/api/lists/l1', {'name': 'X'}),
      (() => repo.deleteList('l1'), 'DELETE', '/api/lists/l1', null),
      (
        () => repo.createCard('l1', name: 'C', position: 16384),
        'POST',
        '/api/lists/l1/cards',
        {'type': 'project', 'name': 'C', 'position': 16384}
      ),
      (
        () => repo.updateCard('c1', {'listId': 'l2', 'position': 8192}),
        'PATCH',
        '/api/cards/c1',
        {'listId': 'l2', 'position': 8192}
      ),
      (() => repo.deleteCard('c1'), 'DELETE', '/api/cards/c1', null),
      (() => repo.cardsOfList('l1'), 'GET', '/api/lists/l1/cards', null),
      (() => repo.comments('c1'), 'GET', '/api/cards/c1/comments', null),
      (() => repo.createComment('c1', text: 'hi'), 'POST', '/api/cards/c1/comments', {'text': 'hi'}),
      (() => repo.updateComment('m1', text: 'yo'), 'PATCH', '/api/comments/m1', {'text': 'yo'}),
      (() => repo.deleteComment('m1'), 'DELETE', '/api/comments/m1', null),
      (
        () => repo.createLabel('b1', name: 'bug', color: 'berry-red', position: 16384),
        'POST',
        '/api/boards/b1/labels',
        {'name': 'bug', 'color': 'berry-red', 'position': 16384}
      ),
      (() => repo.updateLabel('lb1', {'name': 'x'}), 'PATCH', '/api/labels/lb1', {'name': 'x'}),
      (() => repo.deleteLabel('lb1'), 'DELETE', '/api/labels/lb1', null),
      (() => repo.addCardLabel('c1', 'lb1'), 'POST', '/api/cards/c1/card-labels', {'labelId': 'lb1'}),
      (() => repo.removeCardLabel('c1', 'lb1'), 'DELETE', '/api/cards/c1/card-labels/labelId:lb1', null),
      (() => repo.addCardMember('c1', 'u1'), 'POST', '/api/cards/c1/card-memberships', {'userId': 'u1'}),
      (() => repo.removeCardMember('c1', 'u1'), 'DELETE', '/api/cards/c1/card-memberships/userId:u1', null),
      (
        () => repo.createTaskList('c1', name: 'TL', position: 16384),
        'POST',
        '/api/cards/c1/task-lists',
        {'name': 'TL', 'position': 16384}
      ),
      (() => repo.updateTaskList('t1', {'name': 'x'}), 'PATCH', '/api/task-lists/t1', {'name': 'x'}),
      (() => repo.deleteTaskList('t1'), 'DELETE', '/api/task-lists/t1', null),
      (
        () => repo.createTask('t1', name: 'T', position: 16384),
        'POST',
        '/api/task-lists/t1/tasks',
        {'name': 'T', 'position': 16384}
      ),
      (() => repo.updateTask('k1', {'isCompleted': true}), 'PATCH', '/api/tasks/k1', {'isCompleted': true}),
      (() => repo.deleteTask('k1'), 'DELETE', '/api/tasks/k1', null),
      (() => repo.deleteAttachment('a1'), 'DELETE', '/api/attachments/a1', null),
      (() => repo.notifications(), 'GET', '/api/notifications', null),
      (() => repo.markNotificationRead('n1'), 'PATCH', '/api/notifications/n1', {'isRead': true}),
      (() => repo.markAllNotificationsRead(), 'POST', '/api/notifications/read-all', null),
      (() => repo.me(), 'GET', '/api/users/me', null),
    ];

    for (final (call, expMethod, expPath, expBody) in cases) {
      body = null;
      await call();
      expect(method, expMethod, reason: expPath);
      expect(path, expPath);
      expect(body, expBody, reason: expPath);
    }
  });

  test('uploadAttachment posts multipart to attachments endpoint', () async {
    final tmp = File('${Directory.systemTemp.path}/planka_upload_test.txt')
      ..writeAsStringSync('data');
    await repo.uploadAttachment('c1', filePath: tmp.path, name: 'f.txt');
    expect(method, 'POST');
    expect(path, '/api/cards/c1/attachments');
    tmp.deleteSync();
  });
}
