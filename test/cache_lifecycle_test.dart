import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/cache_lifecycle.dart';

void main() {
  test(
    'removal closes new leases and drains admitted key operations',
    () async {
      const accountId = 'https://planka.example#user';
      final lifecycle = AccountCacheLifecycle();
      final lease = lifecycle.acquireForKey('$accountId-projects');
      var removalDone = false;

      final removal = lifecycle.beginRemoval(accountId).then((_) {
        removalDone = true;
      });
      await Future<void>.delayed(Duration.zero);

      expect(removalDone, isFalse);
      expect(
        () => lifecycle.acquireForKey('$accountId-projects'),
        throwsA(isA<AccountCacheClosedException>()),
      );
      expect(
        () => lifecycle.acquire(accountId),
        throwsA(isA<AccountCacheClosedException>()),
      );

      lease.release();
      await removal;
      expect(removalDone, isTrue);
    },
  );

  test(
    'an unrelated account remains open while another account drains',
    () async {
      const accountA = 'https://planka.example#user';
      const accountB = 'https://planka.example#user2';
      final lifecycle = AccountCacheLifecycle();

      final removal = lifecycle.beginRemoval(accountA);
      final leaseB = lifecycle.acquire(accountB);
      leaseB.release();
      await removal;

      final secondLeaseB = lifecycle.acquire(accountB);
      secondLeaseB.release();
    },
  );

  test('resource keys keep hyphenated user ids bound to the full account', () {
    const accountId = 'https://planka.example#user-1234-5678';
    final lifecycle = AccountCacheLifecycle();

    expect(
      lifecycle.accountIdForKey('$accountId-board-42'),
      accountId,
    );
    expect(
      lifecycle.accountIdForKey('$accountId-projects'),
      accountId,
    );
  });
}
