// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlankaUser _$PlankaUserFromJson(Map<String, dynamic> json) => _PlankaUser(
  id: json['id'] as String,
  name: json['name'] as String,
  username: json['username'] as String?,
  email: json['email'] as String?,
  avatar: json['avatar'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PlankaUserToJson(_PlankaUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'avatar': instance.avatar,
    };

_PlankaProject _$PlankaProjectFromJson(Map<String, dynamic> json) =>
    _PlankaProject(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$PlankaProjectToJson(_PlankaProject instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_PlankaBoard _$PlankaBoardFromJson(Map<String, dynamic> json) => _PlankaBoard(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  name: json['name'] as String,
  position: _toDouble(json['position']),
);

Map<String, dynamic> _$PlankaBoardToJson(_PlankaBoard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'position': instance.position,
    };

_PlankaList _$PlankaListFromJson(Map<String, dynamic> json) => _PlankaList(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  type: json['type'] as String,
  name: json['name'] as String?,
  position: _toDouble(json['position']),
);

Map<String, dynamic> _$PlankaListToJson(_PlankaList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'type': instance.type,
      'name': instance.name,
      'position': instance.position,
    };

_PlankaCard _$PlankaCardFromJson(Map<String, dynamic> json) => _PlankaCard(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  listId: json['listId'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
  position: _toDouble(json['position']),
  description: json['description'] as String?,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  isDueCompleted: json['isDueCompleted'] as bool?,
  coverAttachmentId: json['coverAttachmentId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PlankaCardToJson(_PlankaCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'listId': instance.listId,
      'type': instance.type,
      'name': instance.name,
      'position': instance.position,
      'description': instance.description,
      'dueDate': instance.dueDate?.toIso8601String(),
      'isDueCompleted': instance.isDueCompleted,
      'coverAttachmentId': instance.coverAttachmentId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_PlankaLabel _$PlankaLabelFromJson(Map<String, dynamic> json) => _PlankaLabel(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  color: json['color'] as String,
  name: json['name'] as String?,
  position: _toDouble(json['position']),
);

Map<String, dynamic> _$PlankaLabelToJson(_PlankaLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'color': instance.color,
      'name': instance.name,
      'position': instance.position,
    };

_CardLabel _$CardLabelFromJson(Map<String, dynamic> json) => _CardLabel(
  id: json['id'] as String,
  cardId: json['cardId'] as String,
  labelId: json['labelId'] as String,
);

Map<String, dynamic> _$CardLabelToJson(_CardLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'labelId': instance.labelId,
    };

_CardMembership _$CardMembershipFromJson(Map<String, dynamic> json) =>
    _CardMembership(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$CardMembershipToJson(_CardMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'userId': instance.userId,
    };

_BoardMembership _$BoardMembershipFromJson(Map<String, dynamic> json) =>
    _BoardMembership(
      id: json['id'] as String,
      boardId: json['boardId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$BoardMembershipToJson(_BoardMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'userId': instance.userId,
      'role': instance.role,
    };

_PlankaTaskList _$PlankaTaskListFromJson(Map<String, dynamic> json) =>
    _PlankaTaskList(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      name: json['name'] as String,
      position: _toDouble(json['position']),
    );

Map<String, dynamic> _$PlankaTaskListToJson(_PlankaTaskList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'name': instance.name,
      'position': instance.position,
    };

_PlankaTask _$PlankaTaskFromJson(Map<String, dynamic> json) => _PlankaTask(
  id: json['id'] as String,
  taskListId: json['taskListId'] as String,
  name: json['name'] as String,
  isCompleted: json['isCompleted'] as bool,
  position: _toDouble(json['position']),
);

Map<String, dynamic> _$PlankaTaskToJson(_PlankaTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskListId': instance.taskListId,
      'name': instance.name,
      'isCompleted': instance.isCompleted,
      'position': instance.position,
    };

_PlankaComment _$PlankaCommentFromJson(Map<String, dynamic> json) =>
    _PlankaComment(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PlankaCommentToJson(_PlankaComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'userId': instance.userId,
      'text': instance.text,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_PlankaAttachment _$PlankaAttachmentFromJson(Map<String, dynamic> json) =>
    _PlankaAttachment(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PlankaAttachmentToJson(_PlankaAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'type': instance.type,
      'name': instance.name,
      'data': instance.data,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_PlankaNotification _$PlankaNotificationFromJson(Map<String, dynamic> json) =>
    _PlankaNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      cardId: json['cardId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PlankaNotificationToJson(_PlankaNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'isRead': instance.isRead,
      'cardId': instance.cardId,
      'data': instance.data,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
