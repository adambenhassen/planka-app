import 'package:dio/dio.dart';

import 'envelope.dart';
import 'planka_api.dart';

class PlankaRepo {
  PlankaRepo(this.api);
  final PlankaApi api;

  Future<Envelope> projects() => api.get('/projects');

  /// One project. Unlike the board response this carries the project's base
  /// custom field groups and their fields.
  Future<Envelope> project(String id) => api.get('/projects/$id');
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

  Future<Envelope> createBoardCustomFieldGroup(String boardId,
          {required String name, required double position}) =>
      api.post('/boards/$boardId/custom-field-groups',
          {'name': name, 'position': position});
  Future<Envelope> createCardCustomFieldGroup(String cardId,
          {required String name, required double position}) =>
      api.post('/cards/$cardId/custom-field-groups',
          {'name': name, 'position': position});
  Future<Envelope> updateCustomFieldGroup(String id, Map<String, dynamic> patch) =>
      api.patch('/custom-field-groups/$id', patch);
  Future<Envelope> deleteCustomFieldGroup(String id) =>
      api.delete('/custom-field-groups/$id');

  Future<Envelope> createBaseCustomFieldGroup(String projectId,
          {required String name}) =>
      api.post('/projects/$projectId/base-custom-field-groups', {'name': name});
  Future<Envelope> updateBaseCustomFieldGroup(
          String id, Map<String, dynamic> patch) =>
      api.patch('/base-custom-field-groups/$id', patch);
  Future<Envelope> deleteBaseCustomFieldGroup(String id) =>
      api.delete('/base-custom-field-groups/$id');

  /// Instantiates a project template onto a board: the create endpoint takes
  /// either a name or a base group id, plus the position.
  Future<Envelope> createBoardCustomFieldGroupFromTemplate(String boardId,
          {required String baseCustomFieldGroupId, required double position}) =>
      api.post('/boards/$boardId/custom-field-groups',
          {'baseCustomFieldGroupId': baseCustomFieldGroupId, 'position': position});

  /// Fields on a template live under the base group, not under a board group.
  Future<Envelope> createBaseCustomField(String baseGroupId,
          {required String name, required double position}) =>
      api.post('/base-custom-field-groups/$baseGroupId/custom-fields',
          {'name': name, 'position': position});

  Future<Envelope> createCustomField(String groupId,
          {required String name, required double position}) =>
      api.post('/custom-field-groups/$groupId/custom-fields',
          {'name': name, 'position': position});
  Future<Envelope> updateCustomField(String id, Map<String, dynamic> patch) =>
      api.patch('/custom-fields/$id', patch);
  Future<Envelope> deleteCustomField(String id) =>
      api.delete('/custom-fields/$id');

  /// A card's value for one custom field is addressed by the (group, field)
  /// pair rather than by an id of its own — it may not exist yet.
  String _customFieldValuePath(String cardId, String groupId, String fieldId) =>
      '/cards/$cardId/custom-field-values'
      '/customFieldGroupId:$groupId:customFieldId:$fieldId';

  /// Creates or updates the value — one endpoint for both. The server stores no
  /// empty value, so clearing one goes through [deleteCustomFieldValue].
  Future<Envelope> setCustomFieldValue(String cardId,
          {required String groupId,
          required String fieldId,
          required String content}) =>
      api.patch(
          _customFieldValuePath(cardId, groupId, fieldId), {'content': content});
  Future<Envelope> deleteCustomFieldValue(String cardId,
          {required String groupId, required String fieldId}) =>
      api.delete(_customFieldValuePath(cardId, groupId, fieldId));

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

  Future<Envelope> updateUser(String id, Map<String, dynamic> patch) =>
      api.patch('/users/$id', patch);
  Future<Envelope> updateUserEmail(String id,
          {required String email, String? currentPassword}) =>
      api.patch('/users/$id/email',
          {'email': email, 'currentPassword': ?currentPassword});
  Future<Envelope> updateUserPassword(String id,
          {required String password, String? currentPassword}) =>
      api.patch('/users/$id/password', {
        'password': password,
        'currentPassword': ?currentPassword,
      });
  Future<Envelope> updateUserUsername(String id,
          {String? username, String? currentPassword}) =>
      api.patch('/users/$id/username', {
        'username': ?username,
        'currentPassword': ?currentPassword,
      });
  Future<Envelope> uploadUserAvatar(String id,
          {required String filePath, required String name}) async =>
      api.post(
          '/users/$id/avatar',
          FormData.fromMap(
              {'file': await MultipartFile.fromFile(filePath, filename: name)}));
  Future<Envelope> createUser(Map<String, dynamic> body) =>
      api.post('/users', body);
  Future<Envelope> deleteUser(String id) => api.delete('/users/$id');
}
