import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_providers.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Rehydrate the persisted session before the first frame so a returning user
  // lands on their boards instead of the login screen.
  await container.read(currentAccountProvider.notifier).restore();
  runApp(UncontrolledProviderScope(
    container: container,
    child: const PlankaApp(),
  ));
}

class PlankaApp extends ConsumerWidget {
  const PlankaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Planka',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
