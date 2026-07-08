import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

double? _toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
int _toInt(dynamic v) => (v as num).toInt();

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
    // Planka background: type is null | 'gradient' | 'image'. For 'gradient' the
    // name resolves to a gradient; for 'image', backgroundImageId points at a
    // PlankaBackgroundImage in the response's `included.backgroundImages`.
    String? backgroundType,
    String? backgroundGradient,
    String? backgroundImageId,
  }) = _PlankaProject;
  factory PlankaProject.fromJson(Map<String, dynamic> json) =>
      _$PlankaProjectFromJson(json);
}

@freezed
abstract class PlankaBackgroundImage with _$PlankaBackgroundImage {
  const factory PlankaBackgroundImage({
    required String id,
    String? url,
    Map<String, dynamic>? thumbnailUrls,
  }) = _PlankaBackgroundImage;
  factory PlankaBackgroundImage.fromJson(Map<String, dynamic> json) =>
      _$PlankaBackgroundImageFromJson(json);
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
    bool? isSubscribed,
    PlankaStopwatch? stopwatch,
    DateTime? createdAt,
  }) = _PlankaCard;
  factory PlankaCard.fromJson(Map<String, dynamic> json) =>
      _$PlankaCardFromJson(json);
}

/// Planka's card stopwatch: running while [startedAt] is set, paused when it is
/// null; [total] is the accumulated seconds up to the last pause.
@freezed
abstract class PlankaStopwatch with _$PlankaStopwatch {
  const factory PlankaStopwatch({
    DateTime? startedAt,
    @JsonKey(fromJson: _toInt) required int total,
  }) = _PlankaStopwatch;
  factory PlankaStopwatch.fromJson(Map<String, dynamic> json) =>
      _$PlankaStopwatchFromJson(json);
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
abstract class PlankaCardLabel with _$PlankaCardLabel {
  const factory PlankaCardLabel({
    required String id,
    required String cardId,
    required String labelId,
  }) = _PlankaCardLabel;
  factory PlankaCardLabel.fromJson(Map<String, dynamic> json) =>
      _$PlankaCardLabelFromJson(json);
}

@freezed
abstract class PlankaCardMembership with _$PlankaCardMembership {
  const factory PlankaCardMembership({
    required String id,
    required String cardId,
    required String userId,
  }) = _PlankaCardMembership;
  factory PlankaCardMembership.fromJson(Map<String, dynamic> json) =>
      _$PlankaCardMembershipFromJson(json);
}

@freezed
abstract class PlankaProjectManager with _$PlankaProjectManager {
  const factory PlankaProjectManager({
    required String id,
    required String projectId,
    required String userId,
  }) = _PlankaProjectManager;
  factory PlankaProjectManager.fromJson(Map<String, dynamic> json) =>
      _$PlankaProjectManagerFromJson(json);
}

@freezed
abstract class PlankaBoardMembership with _$PlankaBoardMembership {
  const factory PlankaBoardMembership({
    required String id,
    required String boardId,
    required String userId,
    required String role,
  }) = _PlankaBoardMembership;
  factory PlankaBoardMembership.fromJson(Map<String, dynamic> json) =>
      _$PlankaBoardMembershipFromJson(json);
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

/// Typed access to Planka's `data.thumbnailUrls` map, the one seam for reading
/// image-attachment thumbnails so the untyped dig lives in a single place.
extension PlankaAttachmentThumbnails on PlankaAttachment {
  Map? get _thumbs {
    final t = data?['thumbnailUrls'];
    return t is Map ? t : null;
  }

  /// Larger-first URL for card covers, where the image fills the tile width.
  String? get coverThumbnailUrl =>
      (_thumbs?['outside720'] ?? _thumbs?['outside360']) as String?;

  /// Smaller-first URL for the 48px attachment-list leading thumbnail.
  String? get listThumbnailUrl =>
      (_thumbs?['outside360'] ?? _thumbs?['outside720']) as String?;
}

/// Server-recorded card activity kinds. [unknown] is a forward-compat fallback
/// so a new server action type parses and shows a generic entry.
enum PlankaActionType {
  @JsonValue('createCard')
  createCard,
  @JsonValue('moveCard')
  moveCard,
  @JsonValue('addMemberToCard')
  addMemberToCard,
  @JsonValue('removeMemberFromCard')
  removeMemberFromCard,
  @JsonValue('completeTask')
  completeTask,
  @JsonValue('uncompleteTask')
  uncompleteTask,
  unknown,
}

@freezed
abstract class PlankaAction with _$PlankaAction {
  const factory PlankaAction({
    required String id,
    required String cardId,
    @JsonKey(unknownEnumValue: PlankaActionType.unknown)
    required PlankaActionType type,
    String? userId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) = _PlankaAction;
  factory PlankaAction.fromJson(Map<String, dynamic> json) =>
      _$PlankaActionFromJson(json);
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
