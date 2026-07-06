import 'package:dio/dio.dart';

import 'envelope.dart';
import 'planka_api.dart';

class PlankaRepo {
  PlankaRepo(this.api);
  final PlankaApi api;

  Future<Envelope> projects() => api.get('/projects');
  Future<Envelope> board(String id) => api.get('/boards/$id');

  Future<Envelope> createList(String boardId,
          {required String name, required double position}) =>
      api.post('/boards/$boardId/lists',
          {'type': 'active', 'name': name, 'position': position});
  Future<Envelope> updateList(String id, Map<String, dynamic> patch) =>
      api.patch('/lists/$id', patch);
  Future<Envelope> deleteList(String id) => api.delete('/lists/$id');

  Future<Envelope> createCard(String listId,
          {required String name, required double position}) =>
      api.post('/lists/$listId/cards',
          {'type': 'project', 'name': name, 'position': position});
  Future<Envelope> updateCard(String id, Map<String, dynamic> patch) =>
      api.patch('/cards/$id', patch);
  Future<Envelope> deleteCard(String id) => api.delete('/cards/$id');
  Future<Envelope> cardsOfList(String listId) => api.get('/lists/$listId/cards');

  Future<Envelope> comments(String cardId) => api.get('/cards/$cardId/comments');
  Future<Envelope> createComment(String cardId, String text) =>
      api.post('/cards/$cardId/comments', {'text': text});
  Future<Envelope> updateComment(String id, String text) =>
      api.patch('/comments/$id', {'text': text});
  Future<Envelope> deleteComment(String id) => api.delete('/comments/$id');

  Future<Envelope> createLabel(String boardId,
          {String? name, required String color, required double position}) =>
      api.post('/boards/$boardId/labels',
          {'name': name, 'color': color, 'position': position});
  Future<Envelope> updateLabel(String id, Map<String, dynamic> patch) =>
      api.patch('/labels/$id', patch);
  Future<Envelope> deleteLabel(String id) => api.delete('/labels/$id');

  Future<Envelope> addCardLabel(String cardId, String labelId) =>
      api.post('/cards/$cardId/card-labels', {'labelId': labelId});
  Future<Envelope> removeCardLabel(String cardId, String labelId) =>
      api.delete('/cards/$cardId/card-labels/labelId:$labelId');

  Future<Envelope> addCardMember(String cardId, String userId) =>
      api.post('/cards/$cardId/card-memberships', {'userId': userId});
  Future<Envelope> removeCardMember(String cardId, String userId) =>
      api.delete('/cards/$cardId/card-memberships/userId:$userId');

  Future<Envelope> createTaskList(String cardId,
          {required String name, required double position}) =>
      api.post('/cards/$cardId/task-lists', {'name': name, 'position': position});
  Future<Envelope> updateTaskList(String id, Map<String, dynamic> patch) =>
      api.patch('/task-lists/$id', patch);
  Future<Envelope> deleteTaskList(String id) => api.delete('/task-lists/$id');

  Future<Envelope> createTask(String taskListId,
          {required String name, required double position}) =>
      api.post('/task-lists/$taskListId/tasks',
          {'name': name, 'position': position});
  Future<Envelope> updateTask(String id, Map<String, dynamic> patch) =>
      api.patch('/tasks/$id', patch);
  Future<Envelope> deleteTask(String id) => api.delete('/tasks/$id');

  Future<Envelope> uploadAttachment(
          String cardId, String filePath, String name) async =>
      api.post(
          '/cards/$cardId/attachments',
          FormData.fromMap({
            'type': 'file',
            'name': name,
            'file': await MultipartFile.fromFile(filePath, filename: name),
          }));
  Future<Envelope> deleteAttachment(String id) => api.delete('/attachments/$id');

  Future<Envelope> notifications() => api.get('/notifications');
  Future<Envelope> markNotificationRead(String id) =>
      api.patch('/notifications/$id', {'isRead': true});
  Future<Envelope> readAllNotifications() =>
      api.post('/notifications/read-all', null);

  Future<Envelope> me() => api.get('/users/me');
}
