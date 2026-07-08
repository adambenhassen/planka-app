import 'package:dio/dio.dart';

import 'envelope.dart';
import 'planka_api.dart';

class PlankaRepo {
  PlankaRepo(this.api);
  final PlankaApi api;

  Future<Envelope> projects() => api.get('/projects');
  Future<Envelope> createProject(String name) =>
      api.post('/projects', {'type': 'private', 'name': name});
  Future<Envelope> updateProject(String id, Map<String, dynamic> patch) =>
      api.patch('/projects/$id', patch);
  Future<Envelope> deleteProject(String id) => api.delete('/projects/$id');
  Future<Envelope> addProjectManager(String projectId, String userId) =>
      api.post('/projects/$projectId/project-managers', {'userId': userId});
  Future<Envelope> removeProjectManager(String id) =>
      api.delete('/project-managers/$id');
  Future<Envelope> uploadProjectBackgroundImage(String projectId,
          {required String filePath, required String name}) async =>
      api.post(
          '/projects/$projectId/background-images',
          FormData.fromMap(
              {'file': await MultipartFile.fromFile(filePath, filename: name)}));

  Future<Envelope> board(String id) => api.get('/boards/$id');
  Future<Envelope> createBoard(String projectId,
          {required String name, required double position}) =>
      api.post('/projects/$projectId/boards',
          {'name': name, 'position': position});
  Future<Envelope> updateBoard(String id, Map<String, dynamic> patch) =>
      api.patch('/boards/$id', patch);
  Future<Envelope> deleteBoard(String id) => api.delete('/boards/$id');

  Future<Envelope> addBoardMember(String boardId,
          {required String userId, required String role}) =>
      api.post(
          '/boards/$boardId/board-memberships', {'userId': userId, 'role': role});
  Future<Envelope> updateBoardMembership(String id, Map<String, dynamic> patch) =>
      api.patch('/board-memberships/$id', patch);
  Future<Envelope> removeBoardMembership(String id) =>
      api.delete('/board-memberships/$id');

  Future<Envelope> users() => api.get('/users');
  Future<Envelope> cardActions(String cardId, {String? beforeId}) =>
      api.get('/cards/$cardId/actions',
          query: beforeId == null ? null : {'beforeId': beforeId});

  Future<Envelope> createList(String boardId,
          {required String name, required double position}) =>
      api.post('/boards/$boardId/lists',
          {'type': 'active', 'name': name, 'position': position});
  Future<Envelope> updateList(String id, Map<String, dynamic> patch) =>
      api.patch('/lists/$id', patch);
  Future<Envelope> deleteList(String id) => api.delete('/lists/$id');
  Future<Envelope> sortList(String id,
          {required String fieldName, String? order}) =>
      api.post('/lists/$id/sort',
          {'fieldName': fieldName, 'order': ?order});

  Future<Envelope> createCard(String listId,
          {required String name, required double position}) =>
      api.post('/lists/$listId/cards',
          {'type': 'project', 'name': name, 'position': position});
  Future<Envelope> updateCard(String id, Map<String, dynamic> patch) =>
      api.patch('/cards/$id', patch);
  Future<Envelope> duplicateCard(String id, {required double position}) =>
      api.post('/cards/$id/duplicate', {'position': position});
  Future<Envelope> deleteCard(String id) => api.delete('/cards/$id');
  Future<Envelope> cardsOfList(String listId) => api.get('/lists/$listId/cards');

  Future<Envelope> comments(String cardId) => api.get('/cards/$cardId/comments');
  Future<Envelope> createComment(String cardId, {required String text}) =>
      api.post('/cards/$cardId/comments', {'text': text});
  Future<Envelope> updateComment(String id, {required String text}) =>
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

  Future<Envelope> uploadAttachment(String cardId,
          {required String filePath, required String name}) async =>
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
  Future<Envelope> markAllNotificationsRead() =>
      api.post('/notifications/read-all', null);

  Future<Envelope> me() => api.get('/users/me');
}
