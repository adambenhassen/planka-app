import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/l10n/gen/app_localizations.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/ui/privacy_policy.dart';
import 'package:planka_app/ui/projects_screen.dart';

class _FakeProjectsNotifier extends ProjectsNotifier {
  _FakeProjectsNotifier(this.view);
  final ProjectsView view;
  final favoriteCalls = <(String, bool)>[];
  @override
  Future<ProjectsView> build() async => view;
  @override
  Future<void> setProjectFavorite(String id, {required bool favorite}) async {
    favoriteCalls.add((id, favorite));
  }
}

void main() {
  testWidgets('renders projects and boards; tap navigates', (tester) async {
    final env = Envelope.parse(jsonDecode(
            File('test/fixtures/projects_index.json').readAsStringSync())
        as Map<String, dynamic>);
    final view = ProjectsView(
      projects: env.items.map(PlankaProject.fromJson).toList(),
      boards: env.included.boards,
      backgroundImages: env.included.backgroundImages,
    );
    String? navigatedTo;
    final router = GoRouter(initialLocation: '/projects', routes: [
      GoRoute(path: '/projects', builder: (_, _) => const ProjectsScreen()),
      GoRoute(
          path: '/boards/:boardId',
          builder: (_, state) {
            navigatedTo = state.pathParameters['boardId'];
            return const Scaffold(body: Text('BOARD'));
          }),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('NOTIF'))),
    ]);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        projectsProvider.overrideWith(() => _FakeProjectsNotifier(view))
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fixture Project'), findsWidgets);
    final boardTile = find.text('Fixture Board').first;
    expect(boardTile, findsOneWidget);
    await tester.tap(boardTile);
    await tester.pumpAndSettle();
    expect(find.text('BOARD'), findsOneWidget);
    expect(navigatedTo, isNotNull);
  });

  Widget wrap(_FakeProjectsNotifier notifier,
          {PrivacyPolicyLauncher? privacyPolicyLauncher}) =>
      ProviderScope(
        overrides: [projectsProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(initialLocation: '/projects', routes: [
            GoRoute(
                path: '/projects',
                builder: (_, _) => ProjectsScreen(
                    privacyPolicyLauncher: privacyPolicyLauncher)),
            GoRoute(
                path: '/notifications',
                builder: (_, _) => const Scaffold(body: Text('NOTIF'))),
          ]),
        ),
      );

  testWidgets('favourite project sorts first and shows a star', (tester) async {
    final view = ProjectsView(
      projects: [
        const PlankaProject(id: 'p1', name: 'Plain'),
        const PlankaProject(id: 'p2', name: 'Starred', isFavorite: true),
        const PlankaProject(
            id: 'p3', name: 'Described', description: 'Some words'),
      ],
      boards: const [],
      backgroundImages: const [],
    );
    final notifier = _FakeProjectsNotifier(view);
    await tester.pumpWidget(wrap(notifier));
    await tester.pumpAndSettle();

    // Favourites first, then the rest in their given order.
    final nameOrder = ['Starred', 'Plain', 'Described'];
    final positions = {
      for (final name in nameOrder)
        name: tester.getTopLeft(find.text(name)).dy,
    };
    expect(positions.values.toList()..sort(), positions.values.toList());
    expect(positions['Starred'], lessThan(positions['Plain']!));
    expect(positions['Plain'], lessThan(positions['Described']!));

    // The favourite carries a filled star, the others do not.
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    // Descriptions show under the project name.
    expect(find.text('Some words'), findsOneWidget);
  });

  testWidgets('tapping the star toggles the favourite flag', (tester) async {
    final view = ProjectsView(
      projects: [
        const PlankaProject(id: 'p1', name: 'Plain'),
        const PlankaProject(id: 'p2', name: 'Starred', isFavorite: true),
      ],
      boards: const [],
      backgroundImages: const [],
    );
    final notifier = _FakeProjectsNotifier(view);
    await tester.pumpWidget(wrap(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pumpAndSettle();

    expect(notifier.favoriteCalls, [('p1', true), ('p2', false)]);
  });

  testWidgets('account menu exposes the privacy policy', (tester) async {
    final view = ProjectsView(
      projects: const [],
      boards: const [],
      backgroundImages: const [],
    );
    Uri? openedUri;
    await tester.pumpWidget(
      wrap(
        _FakeProjectsNotifier(view),
        privacyPolicyLauncher: (uri, _) async {
          openedUri = uri;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();
    expect(openedUri, Uri.parse(privacyPolicyUrl));
  });
}
