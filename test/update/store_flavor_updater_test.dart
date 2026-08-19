@TestOn('vm')
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/update/update_service.dart';

/// Run separately, because the flag is compile-time:
///
/// ```
/// flutter test --dart-define=ENABLE_IN_APP_UPDATER=false \
///   test/update/store_flavor_updater_test.dart
/// ```
///
/// Under the default (sideload) build this file is a no-op — see
/// `update_service_test.dart` for the default-on assertion.
void main() {
  test('store build resolves no update without touching PackageInfo', () async {
    if (kInAppUpdaterEnabled) {
      markTestSkipped('needs --dart-define=ENABLE_IN_APP_UPDATER=false');
      return;
    }
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // No PackageInfo or platform-channel mock is set up: the guard has to
    // return before either is reached, which is what keeps the updater out of
    // a store build rather than merely hiding its UI.
    expect(await container.read(updateCheckProvider.future), isNull);
  });
}
