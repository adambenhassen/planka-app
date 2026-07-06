import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

double? _toDouble(dynamic v) => v == null ? null : (v as num).toDouble();

/// Planka's fixed set of board-list types. [unknown] is a forward-compat
/// fallback for any value a newer server introduces, so parsing never throws.
enum PlankaListType {
  @JsonValue('active')
  active,
  @JsonValue('closed')
  closed,
  @JsonValue('archive')
  archive,
  @JsonValue('trash')
  trash,
  unknown,
}

/// Notification kinds the UI renders distinctly. [unknown] is a forward-compat
/// fallback so a new server notification type parses and shows a default icon.
enum PlankaNotificationType {
  @JsonValue('commentCard')
  commentCard,
  @JsonValue('moveCard')
  moveCard,
  @JsonValue('addMemberToCard')
  addMemberToCard,
  @JsonValue('mentionInComment')
  mentionInComment,
  unknown,
}

@freezed
abstract class PlankaUser with _$PlankaUser {
  const factory PlankaUser({
    required String id,
    required String name,
    String? username,
    String? email,
    Map<String, dynamic>? avatar,
  }) = _PlankaUser;
  factory PlankaUser.fromJson(Map<String, dynamic> json) =>
      _$PlankaUserFromJson(json);
}

@freezed
abstract class PlankaProject with _$PlankaProject {
  const factory PlankaProject({
    required String id,
    required String name,
  }) = _PlankaProject;
  factory PlankaProject.fromJson(Map<String, dynamic> json) =>
      _$PlankaProjectFromJson(json);
}

@freezed
abstract class PlankaBoard with _$PlankaBoard {
  const factory PlankaBoard({
    required String id,
    required String projectId,
    required String name,
    @JsonKey(fromJson: _toDouble) double? position,
  }) = _PlankaBoard;
  factory PlankaBoard.fromJson(Map<String, dynamic> json) =>
      _$PlankaBoardFromJson(json);
}

@freezed
abstract class PlankaList with _$PlankaList {
  const factory PlankaList({
    required String id,
    required String boardId,
    @JsonKey(unknownEnumValue: PlankaListType.unknown)
    required PlankaListType type,
    String? name,
    @JsonKey(fromJson: _toDouble) double? position,
  }) = _PlankaList;
  factory PlankaList.fromJson(Map<String, dynamic> json) =>
      _$PlankaListFromJson(json);
}

@freezed
abstract class PlankaCard with _$PlankaCard {
  const factory PlankaCard({
    required String id,
    required String boardId,
    required String listId,
    required String type, // project | story
    required String name,
    @JsonKey(fromJson: _toDouble) double? position,
    String? description,
    DateTime? dueDate,
    bool? isDueCompleted,
    String? coverAttachmentId,
    DateTime? createdAt,
  }) = _PlankaCard;
  factory PlankaCard.fromJson(Map<String, dynamic> json) =>
      _$PlankaCardFromJson(json);
}

@freezed
abstract class PlankaLabel with _$PlankaLabel {
  const factory PlankaLabel({
    required String id,
    required String boardId,
    required String color,
    String? name,
    @JsonKey(fromJson: _toDouble) double? position,
  }) = _PlankaLabel;
  factory PlankaLabel.fromJson(Map<String, dynamic> json) =>
      _$PlankaLabelFromJson(json);
}

@freezed
abstract class CardLabel with _$CardLabel {
  const factory CardLabel({
    required String id,
    required String cardId,
    required String labelId,
  }) = _CardLabel;
  factory CardLabel.fromJson(Map<String, dynamic> json) =>
      _$CardLabelFromJson(json);
}

@freezed
abstract class CardMembership with _$CardMembership {
  const factory CardMembership({
    required String id,
    required String cardId,
    required String userId,
  }) = _CardMembership;
  factory CardMembership.fromJson(Map<String, dynamic> json) =>
      _$CardMembershipFromJson(json);
}

@freezed
abstract class BoardMembership with _$BoardMembership {
  const factory BoardMembership({
    required String id,
    required String boardId,
    required String userId,
    required String role,
  }) = _BoardMembership;
  factory BoardMembership.fromJson(Map<String, dynamic> json) =>
      _$BoardMembershipFromJson(json);
}

@freezed
abstract class PlankaTaskList with _$PlankaTaskList {
  const factory PlankaTaskList({
    required String id,
    required String cardId,
    required String name,
    @JsonKey(fromJson: _toDouble) double? position,
  }) = _PlankaTaskList;
  factory PlankaTaskList.fromJson(Map<String, dynamic> json) =>
      _$PlankaTaskListFromJson(json);
}

@freezed
abstract class PlankaTask with _$PlankaTask {
  const factory PlankaTask({
    required String id,
    required String taskListId,
    required String name,
    required bool isCompleted,
    @JsonKey(fromJson: _toDouble) double? position,
  }) = _PlankaTask;
  factory PlankaTask.fromJson(Map<String, dynamic> json) =>
      _$PlankaTaskFromJson(json);
}

@freezed
abstract class PlankaComment with _$PlankaComment {
  const factory PlankaComment({
    required String id,
    required String cardId,
    required String userId,
    required String text,
    DateTime? createdAt,
  }) = _PlankaComment;
  factory PlankaComment.fromJson(Map<String, dynamic> json) =>
      _$PlankaCommentFromJson(json);
}

@freezed
abstract class PlankaAttachment with _$PlankaAttachment {
  const factory PlankaAttachment({
    required String id,
    required String cardId,
    required String type,
    required String name,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) = _PlankaAttachment;
  factory PlankaAttachment.fromJson(Map<String, dynamic> json) =>
      _$PlankaAttachmentFromJson(json);
}

@freezed
abstract class PlankaNotification with _$PlankaNotification {
  const factory PlankaNotification({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: PlankaNotificationType.unknown)
    required PlankaNotificationType type,
    required bool isRead,
    String? cardId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) = _PlankaNotification;
  factory PlankaNotification.fromJson(Map<String, dynamic> json) =>
      _$PlankaNotificationFromJson(json);
}
