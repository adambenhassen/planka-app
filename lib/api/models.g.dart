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
    _PlankaProject(
      id: json['id'] as String,
      name: json['name'] as String,
      backgroundType: json['backgroundType'] as String?,
      backgroundGradient: json['backgroundGradient'] as String?,
      backgroundImageId: json['backgroundImageId'] as String?,
    );

Map<String, dynamic> _$PlankaProjectToJson(_PlankaProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'backgroundType': instance.backgroundType,
      'backgroundGradient': instance.backgroundGradient,
      'backgroundImageId': instance.backgroundImageId,
    };

_PlankaBackgroundImage _$PlankaBackgroundImageFromJson(
  Map<String, dynamic> json,
) => _PlankaBackgroundImage(
  id: json['id'] as String,
  url: json['url'] as String?,
  thumbnailUrls: json['thumbnailUrls'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PlankaBackgroundImageToJson(
  _PlankaBackgroundImage instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'thumbnailUrls': instance.thumbnailUrls,
};

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
  type: $enumDecode(
    _$PlankaListTypeEnumMap,
    json['type'],
    unknownValue: PlankaListType.unknown,
  ),
  name: json['name'] as String?,
  position: _toDouble(json['position']),
);

Map<String, dynamic> _$PlankaListToJson(_PlankaList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'type': _$PlankaListTypeEnumMap[instance.type]!,
      'name': instance.name,
      'position': instance.position,
    };

const _$PlankaListTypeEnumMap = {
  PlankaListType.active: 'active',
  PlankaListType.closed: 'closed',
  PlankaListType.archive: 'archive',
  PlankaListType.trash: 'trash',
  PlankaListType.unknown: 'unknown',
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
  isSubscribed: json['isSubscribed'] as bool?,
  stopwatch: json['stopwatch'] == null
      ? null
      : PlankaStopwatch.fromJson(json['stopwatch'] as Map<String, dynamic>),
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
      'isSubscribed': instance.isSubscribed,
      'stopwatch': instance.stopwatch,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_PlankaStopwatch _$PlankaStopwatchFromJson(Map<String, dynamic> json) =>
    _PlankaStopwatch(
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      total: _toInt(json['total']),
    );

Map<String, dynamic> _$PlankaStopwatchToJson(_PlankaStopwatch instance) =>
    <String, dynamic>{
      'startedAt': instance.startedAt?.toIso8601String(),
      'total': instance.total,
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

_PlankaCardLabel _$PlankaCardLabelFromJson(Map<String, dynamic> json) =>
    _PlankaCardLabel(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      labelId: json['labelId'] as String,
    );

Map<String, dynamic> _$PlankaCardLabelToJson(_PlankaCardLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'labelId': instance.labelId,
    };

_PlankaCardMembership _$PlankaCardMembershipFromJson(
  Map<String, dynamic> json,
) => _PlankaCardMembership(
  id: json['id'] as String,
  cardId: json['cardId'] as String,
  userId: json['userId'] as String,
);

Map<String, dynamic> _$PlankaCardMembershipToJson(
  _PlankaCardMembership instance,
) => <String, dynamic>{
  'id': instance.id,
  'cardId': instance.cardId,
  'userId': instance.userId,
};

_PlankaProjectManager _$PlankaProjectManagerFromJson(
  Map<String, dynamic> json,
) => _PlankaProjectManager(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  userId: json['userId'] as String,
);

Map<String, dynamic> _$PlankaProjectManagerToJson(
  _PlankaProjectManager instance,
) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'userId': instance.userId,
};

_PlankaBoardMembership _$PlankaBoardMembershipFromJson(
  Map<String, dynamic> json,
) => _PlankaBoardMembership(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  userId: json['userId'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$PlankaBoardMembershipToJson(
  _PlankaBoardMembership instance,
) => <String, dynamic>{
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

_PlankaAction _$PlankaActionFromJson(Map<String, dynamic> json) =>
    _PlankaAction(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      type: $enumDecode(
        _$PlankaActionTypeEnumMap,
        json['type'],
        unknownValue: PlankaActionType.unknown,
      ),
      userId: json['userId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PlankaActionToJson(_PlankaAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'type': _$PlankaActionTypeEnumMap[instance.type]!,
      'userId': instance.userId,
      'data': instance.data,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$PlankaActionTypeEnumMap = {
  PlankaActionType.createCard: 'createCard',
  PlankaActionType.moveCard: 'moveCard',
  PlankaActionType.addMemberToCard: 'addMemberToCard',
  PlankaActionType.removeMemberFromCard: 'removeMemberFromCard',
  PlankaActionType.completeTask: 'completeTask',
  PlankaActionType.uncompleteTask: 'uncompleteTask',
  PlankaActionType.unknown: 'unknown',
};

_PlankaNotification _$PlankaNotificationFromJson(Map<String, dynamic> json) =>
    _PlankaNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(
        _$PlankaNotificationTypeEnumMap,
        json['type'],
        unknownValue: PlankaNotificationType.unknown,
      ),
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
      'type': _$PlankaNotificationTypeEnumMap[instance.type]!,
      'isRead': instance.isRead,
      'cardId': instance.cardId,
      'data': instance.data,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$PlankaNotificationTypeEnumMap = {
  PlankaNotificationType.commentCard: 'commentCard',
  PlankaNotificationType.moveCard: 'moveCard',
  PlankaNotificationType.addMemberToCard: 'addMemberToCard',
  PlankaNotificationType.mentionInComment: 'mentionInComment',
  PlankaNotificationType.unknown: 'unknown',
};
