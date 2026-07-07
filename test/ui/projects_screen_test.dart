import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planka_app/api/envelope.dart';
import 'package:planka_app/api/models.dart';
import 'package:planka_app/state/projects_state.dart';
import 'package:planka_app/ui/projects_screen.dart';

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
      overrides: [projectsProvider.overrideWith((ref) async => view)],
      child: MaterialApp.router(routerConfig: router),
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
}
