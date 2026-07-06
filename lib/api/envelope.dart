import 'models.dart';

class Included {
  final Map<String, dynamic> _raw;
  Included(Map<String, dynamic>? raw) : _raw = raw ?? const {};

  List<T> _list<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      ((_raw[key] as List?) ?? const [])
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  List<PlankaUser> get users => _list('users', PlankaUser.fromJson);
  List<PlankaProject> get projects => _list('projects', PlankaProject.fromJson);
  List<PlankaBoard> get boards => _list('boards', PlankaBoard.fromJson);
  List<PlankaList> get lists => _list('lists', PlankaList.fromJson);
  List<PlankaCard> get cards => _list('cards', PlankaCard.fromJson);
  List<PlankaLabel> get labels => _list('labels', PlankaLabel.fromJson);
  List<CardLabel> get cardLabels => _list('cardLabels', CardLabel.fromJson);
  List<CardMembership> get cardMemberships =>
      _list('cardMemberships', CardMembership.fromJson);
  List<BoardMembership> get boardMemberships =>
      _list('boardMemberships', BoardMembership.fromJson);
  List<PlankaTaskList> get taskLists =>
      _list('taskLists', PlankaTaskList.fromJson);
  List<PlankaTask> get tasks => _list('tasks', PlankaTask.fromJson);
  List<PlankaComment> get comments => _list('comments', PlankaComment.fromJson);
  List<PlankaAttachment> get attachments =>
      _list('attachments', PlankaAttachment.fromJson);
  List<PlankaNotification> get notifications =>
      _list('notifications', PlankaNotification.fromJson);
}

class Envelope {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> items;
  final Included included;
  Envelope({required this.item, required this.items, required this.included});

  static Envelope parse(Map<String, dynamic> json) => Envelope(
        item: (json['item'] as Map?)?.cast<String, dynamic>() ?? const {},
        items: ((json['items'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        included: Included((json['included'] as Map?)?.cast<String, dynamic>()),
      );
}
