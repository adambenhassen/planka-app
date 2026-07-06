import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

void main() => runApp(const ProviderScope(child: PlankaApp()));

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
