import 'models.dart';

class Included {
  final Map<String, dynamic> _raw;
  Included(Map<String, dynamic>? raw) : _raw = raw ?? const {};

  List<T> _list<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      ((_raw[key] as List?) ?? const [])
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  // Parsed once on first access, then cached — accessors are cheap to re-read.
  late final List<PlankaUser> users = _list('users', PlankaUser.fromJson);
  late final List<PlankaProject> projects =
      _list('projects', PlankaProject.fromJson);
  late final List<PlankaBoard> boards = _list('boards', PlankaBoard.fromJson);
  late final List<PlankaBackgroundImage> backgroundImages =
      _list('backgroundImages', PlankaBackgroundImage.fromJson);
  late final List<PlankaList> lists = _list('lists', PlankaList.fromJson);
  late final List<PlankaCard> cards = _list('cards', PlankaCard.fromJson);
  late final List<PlankaLabel> labels = _list('labels', PlankaLabel.fromJson);
  late final List<PlankaCardLabel> cardLabels =
      _list('cardLabels', PlankaCardLabel.fromJson);
  late final List<PlankaCardMembership> cardMemberships =
      _list('cardMemberships', PlankaCardMembership.fromJson);
  late final List<PlankaBoardMembership> boardMemberships =
      _list('boardMemberships', PlankaBoardMembership.fromJson);
  late final List<PlankaTaskList> taskLists =
      _list('taskLists', PlankaTaskList.fromJson);
  late final List<PlankaTask> tasks = _list('tasks', PlankaTask.fromJson);
  late final List<PlankaComment> comments =
      _list('comments', PlankaComment.fromJson);
  late final List<PlankaAttachment> attachments =
      _list('attachments', PlankaAttachment.fromJson);
  late final List<PlankaNotification> notifications =
      _list('notifications', PlankaNotification.fromJson);
  late final List<PlankaAction> actions = _list('actions', PlankaAction.fromJson);
  late final List<PlankaProjectManager> projectManagers =
      _list('projectManagers', PlankaProjectManager.fromJson);
}

class Envelope {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> items;
  final Included included;

  /// The unparsed response body, kept so a response can be persisted verbatim
  /// (offline cache) and rehydrated later via [parse].
  final Map<String, dynamic> raw;

  Envelope({
    required this.item,
    required this.items,
    required this.included,
    this.raw = const {},
  });

  /// Self password-change responses carry the replacement token as a scalar
  /// inside `included` ({item, included: {accessToken}}). Null when absent.
  String? get accessToken {
    final t = (raw['included'] as Map?)?['accessToken'];
    return t is String ? t : null;
  }

  static Envelope parse(Map<String, dynamic> json) => Envelope(
        item: (json['item'] as Map?)?.cast<String, dynamic>() ?? const {},
        items: ((json['items'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
        included: Included((json['included'] as Map?)?.cast<String, dynamic>()),
        raw: json,
      );
}
