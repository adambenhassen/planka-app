import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planka_app/ui/login_screen.dart';
import 'package:planka_app/ui/theme/app_theme.dart';

void main() {
  testWidgets('login screen golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 800));
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    ));
    // Decode the logo asset — golden tests skip async image loading otherwise.
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(LoginScreen));
      await precacheImage(const AssetImage('assets/icon/icon.png'), ctx);
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });
}
