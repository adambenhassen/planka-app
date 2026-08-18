import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_providers.dart';
import 'l10n/gen/app_localizations.dart';
import 'router.dart';
import 'ui/theme/app_theme.dart';

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
      // Follows the system locale; English is the only complete locale, so
      // Flutter's default resolution falls back to it for anything else.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
