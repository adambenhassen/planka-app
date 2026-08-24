import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/api/planka_api.dart';
import 'package:planka_app/auth/accounts.dart';
import 'package:planka_app/auth/auth_providers.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/board_state.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/ui/custom_fields_manager_sheet.dart';
import 'package:planka_app/ui/projects_screen.dart';
import 'package:planka_app/ui/widgets/inline_add_field.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────

const _boardId = 'b1';
const _projectId = 'p1';

BoardState _boardState({bool instantiated = false}) => BoardState(
      board: const PlankaBoard(
          id: _boardId, projectId: _projectId, name: 'My Board'),
      lists: const [],
      cards: const {},
      customFieldGroups: [
        if (instantiated)
          const PlankaCustomFieldGroup(
              id: 'ig1',
              name: null,
              boardId: _boardId,
              baseCustomFieldGroupId: 't1',
              position: 16384),
      ],
    );

ProjectsView _view({
  List<PlankaBaseCustomFieldGroup> bases = const [
    PlankaBaseCustomFieldGroup(id: 't1', projectId: _projectId, name: 'Alpha'),
    PlankaBaseCustomFieldGroup(id: 't2', projectId: _projectId, name: 'Beta'),
  ],
  List<PlankaCustomField> fields = const [
    PlankaCustomField(
        id: 'f1',
        name: 'Story points',
        baseCustomFieldGroupId: 't1',
        position: 16384),
    PlankaCustomField(
        id: 'f2',
        name: 'Priority',
        baseCustomFieldGroupId: 't1',
        position: 32768,
        showOnFrontOfCard: true),
  ],
}) =>
    ProjectsView(
      projects: const [PlankaProject(id: _projectId, name: 'Proj')],
      boards: const [],
      backgroundImages: const [],
      baseCustomFieldGroups: bases,
      customFields: fields,
    );

final _emptyView = ProjectsView(
  projects: const [PlankaProject(id: _projectId, name: 'Proj')],
  boards: const [],
  backgroundImages: const [],
);

// ── Fakes ─────────────────────────────────────────────────────────────────

class _AccNotifier extends CurrentAccountNotifier {
  @override
  Account build() =>
      Account(serverUrl: 'http://x', token: 'tok', userId: 'me', displayName: 'Me');
}

class _FakeProjectsNotifier extends ProjectsNotifier {
  _FakeProjectsNotifier(this._view, {this.failWrites = false});
  final ProjectsView _view;

  /// Rejects every write the way a non-manager is refused: the server answers
  /// project-level writes with a 404 there.
  final bool failWrites;

  final calls = <(String, Object?)>[];

  @override
  Future<ProjectsView> build() async => _view;

  Future<void> _record(String op, Object? arg) async {
    calls.add((op, arg));
    if (failWrites) throw ApiException(404, 'projectNotFound');
  }

  @override
  Future<void> createTemplate(String projectId, String name) async {
    await _record('createTemplate', (projectId, name));
  }

  @override
  Future<void> renameTemplate(String id, String name) async {
    await _record('renameTemplate', (id, name));
  }

  @override
  Future<void> deleteTemplate(String id) => _record('deleteTemplate', id);

  @override
  Future<void> createTemplateField(String templateId, String name) async {
    await _record('createTemplateField', (templateId, name));
  }

  @override
  Future<void> renameTemplateField(String id, String name) async {
    await _record('renameTemplateField', (id, name));
  }

  @override
  Future<void> toggleTemplateFieldFrontOfCard(String id, bool show) async {
    await _record('toggleFront', (id, show));
  }

  @override
  Future<void> moveTemplateFieldUp(String id) =>
      _record('fieldUp', id);

  @override
  Future<void> moveTemplateFieldDown(String id) =>
      _record('fieldDown', id);

  @override
  Future<void> deleteTemplateField(String id) =>
      _record('deleteField', id);
}

/// Never resolves until completed — holds the templates section in its
/// loading state so the spinner branch can be asserted.
/// Never resolves until completed — holds the templates section in its
/// loading state so the spinner branch can be asserted.
class _DelayedProjectsNotifier extends ProjectsNotifier {
  _DelayedProjectsNotifier(this.completer);
  final Completer<ProjectsView> completer;
  @override
  Future<ProjectsView> build() => completer.future;
}

/// View swappable mid-test, so a record can vanish between rendering and a
/// write — the deleted-from-another-client race.
class _MutableProjectsNotifier extends ProjectsNotifier {
  _MutableProjectsNotifier(ProjectsView view) : _view = view;
  ProjectsView _view;

  set view(ProjectsView v) => _view = v;

  @override
  Future<ProjectsView> build() async => _view;

  @override
  Future<void> renameTemplate(String id, String name) async {
    throw ApiException(404, 'projectNotFound');
  }
}

/// Always fails to load — the templates section's error branch.
class _ErrorProjectsNotifier extends ProjectsNotifier {
  @override
  Future<ProjectsView> build() async => throw Exception('down');
}

class _FakeBoardNotifier extends BoardNotifier {
  _FakeBoardNotifier(super.boardId, this._state);
  final BoardState _state;
  final calls = <(String, Object?)>[];
  @override
  Future<BoardState> build() async => _state;
  @override
  Future<void> instantiateTemplateOnBoard(String baseCustomFieldGroupId) =>
      _record('instantiate', baseCustomFieldGroupId);
  Future<void> _record(String op, Object? arg) async =>
      calls.add((op, arg));
}

// ── Helpers ───────────────────────────────────────────────────────────────

late _FakeProjectsNotifier _projects;
_FakeBoardNotifier? _board;

/// Page 2, entered the way the projects screen enters it.
Widget _templatesApp(ProjectsView view, {bool failWrites = false}) {
  return ProviderScope(
    overrides: [
      currentAccountProvider.overrideWith(() => _AccNotifier()),
      projectsProvider.overrideWith(() {
        _projects = _FakeProjectsNotifier(view, failWrites: failWrites);
        return _projects;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CustomFieldsManagerSheet(projectId: _projectId),
      ),
    ),
  );
}

/// Page 1 from a board, with the templates section fed by [view].
Widget _boardApp(
  BoardState state,
  ProjectsView view, {
  bool instantiated = false,
}) {
  final boardNotifier =
      _FakeBoardNotifier(_boardId, _boardState(instantiated: instantiated));
  _board = boardNotifier;
  return ProviderScope(
    overrides: [
      currentAccountProvider.overrideWith(() => _AccNotifier()),
      projectsProvider.overrideWith(() {
        _projects = _FakeProjectsNotifier(view);
        return _projects;
      }),
      boardProvider.overrideWith2((arg) => boardNotifier),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CustomFieldsManagerSheet(boardId: _boardId),
      ),
    ),
  );
}


Future<void> _submitInlineAdd(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).last, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _projects = _FakeProjectsNotifier(_emptyView);
    _board = null;
  });

  group('templates page (page 2), opened directly', () {
    testWidgets('lists each template with its field count', (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('2 fields'), findsOneWidget);
      expect(find.text('0 fields'), findsOneWidget);
    });

    testWidgets('no fields page behind it: no back arrow, no sections',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('Board'), findsNothing);
      expect(find.text('Project templates'), findsNothing);
    });

    testWidgets('an empty project shows the empty-state line and add row',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_emptyView));
      await tester.pumpAndSettle();

      expect(find.text('This project has no field templates yet.'),
          findsOneWidget);
      expect(find.widgetWithText(InlineAddField, 'Add template'),
          findsOneWidget);
    });

    testWidgets('create template fires createTemplate', (tester) async {
      await tester.pumpWidget(_templatesApp(_emptyView));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add template'));
      await tester.pumpAndSettle();
      await _submitInlineAdd(tester, 'Sizes');

      expect(
          _projects.calls.where((c) => c.$1 == 'createTemplate'), hasLength(1));
    });

    testWidgets('template menu offers rename and delete, never reorder',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Move up'), findsNothing);
      expect(find.text('Move down'), findsNothing);
    });

    testWidgets('rename template fires renameTemplate', (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Renamed');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_projects.calls.where((c) => c.$1 == 'renameTemplate'),
          hasLength(1));
    });

    testWidgets(
        'delete confirmation names the template, states the cascade scope, '
        'and no board count', (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete template?'), findsOneWidget);
      expect(find.textContaining('"Alpha"'), findsOneWidget);
      // The scope must be named in these words, and no number of boards may
      // be stated: the projects payload cannot compute one.
      expect(
          find.textContaining('every board in this project that uses it'),
          findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d+ boards')), findsNothing);
    });

    testWidgets('cancel fires nothing; confirm fires deleteTemplate',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(_projects.calls.where((c) => c.$1 == 'deleteTemplate'), isEmpty);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(_projects.calls.where((c) => c.$1 == 'deleteTemplate'),
          hasLength(1));
    });

    testWidgets('template fields support rename, front toggle and reorder',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      // Field rows sit under their template: first more_vert is Alpha's menu,
      // then f1's, then f2's.
      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      expect(_projects.calls.where((c) => c.$1 == 'fieldDown'), hasLength(1));

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Renamed field');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(_projects.calls.where((c) => c.$1 == 'renameTemplateField'),
          hasLength(1));

      // f2 carries showOnFrontOfCard: true; its menu is index 2.
      await tester.tap(find.byIcon(Icons.more_vert).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          CheckedPopupMenuItem<String>, 'Show on front of card'));
      await tester.pumpAndSettle();
      expect(_projects.calls.where((c) => c.$1 == 'toggleFront'),
          hasLength(1));
    });

    testWidgets('delete a template field confirms first, names the field',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete field?'), findsOneWidget);
      expect(find.textContaining('"Story points"'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_projects.calls.where((c) => c.$1 == 'deleteField'), isEmpty);
    });

    testWidgets('add field row exists on each template', (tester) async {
      await tester.pumpWidget(_templatesApp(_view()));
      await tester.pumpAndSettle();

      // One per template: Alpha and Beta.
      expect(
          find.widgetWithText(InlineAddField, 'Add field'), findsNWidgets(2));
    });

    testWidgets('404 on a template write says manager-only, not missing',
        (tester) async {
      await tester.pumpWidget(_templatesApp(_emptyView, failWrites: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add template'));
      await tester.pumpAndSettle();
      await _submitInlineAdd(tester, 'Sizes');

      expect(find.text('Only project managers can change field templates.'),
          findsOneWidget);
    });

    testWidgets('deleting a one-field template reads the singular count',
        (tester) async {
      final single = _view(
        bases: const [
          PlankaBaseCustomFieldGroup(id: 't9', projectId: _projectId, name: 'Solo'),
        ],
        fields: const [
          PlankaCustomField(
              id: 'sf1',
              name: 'Only field',
              baseCustomFieldGroupId: 't9',
              position: 16384),
        ],
      );
      await tester.pumpWidget(_templatesApp(single));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'its 1 field,')), findsOneWidget);
      expect(find.textContaining('its 1 fields'), findsNothing);
    });

    testWidgets('404 on renaming a template still in the view says '
        'manager-only', (tester) async {
      final fake = _MutableProjectsNotifier(_view());
      await tester.pumpWidget(UncontrolledProviderScope(
        container: ProviderContainer(overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier()),
          projectsProvider.overrideWith(() => fake),
        ]),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: CustomFieldsManagerSheet(projectId: _projectId),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Renamed');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Only project managers can change field templates.'),
          findsOneWidget);
    });
  });

  group('templates section on page 1', () {
    testWidgets('lists templates with field count and Add to board',
        (tester) async {
      await tester.pumpWidget(_boardApp(_boardState(), _view()));
      await tester.pumpAndSettle();

      expect(find.text('Project templates'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('2 fields'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Add to board'), findsNWidgets(2));
    });

    testWidgets('Add to board fires instantiateTemplateOnBoard',
        (tester) async {
      await tester.pumpWidget(_boardApp(_boardState(), _view()));
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(TextButton, 'Add to board').first);
      await tester.pumpAndSettle();

      expect(_board!.calls.where((c) => c.$1 == 'instantiate'), hasLength(1));
    });

    testWidgets('an instantiated template reads Added, not Add to board',
        (tester) async {
      await tester.pumpWidget(_boardApp(_boardState(), _view(),
          instantiated: true));
      await tester.pumpAndSettle();

      expect(find.text('Added'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Add to board'), findsOneWidget);
    });

    testWidgets('Manage templates pushes page 2 inside the sheet; back '
        'returns', (tester) async {
      await tester.pumpWidget(_boardApp(_boardState(), _view()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage templates'));
      await tester.pumpAndSettle();

      // Page 2 content and the back affordance are both present.
      expect(find.text('Add template'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Board'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('templates fetch failing leaves that section broken and the '
        'rest of the sheet working', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier()),
          projectsProvider.overrideWith(_ErrorProjectsNotifier.new),
          boardProvider.overrideWith2(
              (arg) => _FakeBoardNotifier(arg, _boardState())),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: CustomFieldsManagerSheet(boardId: _boardId),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load project templates"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // The rest of the sheet is unaffected.
      expect(find.textContaining('No custom fields on this board yet'),
          findsOneWidget);
      expect(find.widgetWithText(InlineAddField, 'Add group'), findsOneWidget);
    });

    testWidgets('while the projects payload loads, the section shows a '
        'spinner and the rest of the sheet stays interactive',
        (tester) async {
      final completer = Completer<ProjectsView>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier()),
          projectsProvider.overrideWith(() => _DelayedProjectsNotifier(completer)),
          boardProvider.overrideWith2(
              (arg) => _FakeBoardNotifier(arg, _boardState())),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: CustomFieldsManagerSheet(boardId: _boardId),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Not blocking the rest of the sheet:
      expect(find.widgetWithText(InlineAddField, 'Add group'), findsOneWidget);

      completer.complete(_view());
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
    });
  });

  group('projects screen entry point', () {
    testWidgets('project menu Custom fields opens the sheet on its templates '
        'page', (tester) async {
      _projects = _FakeProjectsNotifier(_view());
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentAccountProvider.overrideWith(() => _AccNotifier()),
          projectsProvider
              .overrideWith(() => _FakeProjectsNotifier(_view())),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProjectsScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom fields'));
      await tester.pumpAndSettle();

      // Straight onto page 2: template management, no back arrow.
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Add template'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('Board'), findsNothing);
    });
  });

  group('templateRecordInView', () {
    final view = _view();

    test('the project the sheet is scoped to', () {
      expect(templateRecordInView(view, projectId: _projectId), isTrue);
      expect(templateRecordInView(view, projectId: 'other'), isFalse);
    });

    test('templates still held vs deleted from elsewhere', () {
      expect(templateRecordInView(view, templateId: 't1'), isTrue);
      expect(templateRecordInView(view, templateId: 't9'), isFalse);
    });

    test('fields still held vs deleted from elsewhere', () {
      expect(templateRecordInView(view, fieldId: 'f1'), isTrue);
      expect(templateRecordInView(view, fieldId: 'fx'), isFalse);
    });

    test('a missing projects payload never claims the manager refusal', () {
      expect(templateRecordInView(null, templateId: 't1'), isFalse);
    });
  });
}
