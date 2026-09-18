import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planka_app/security_redaction.dart';

void main() {
  test(
    'short registered secrets redact as values without corrupting words',
    () {
      registerSecret('t');

      expect(redactDiagnostic('item'), 'item');
      expect(redactDiagnostic('token=t'), 'token=[REDACTED]');
    },
  );

  test('redacts a token crossing a large emission boundary', () async {
    const token = 'boundary-canary-value-123456';
    registerSecret(token);
    final bytes =
        await redactCacheStream(
          Stream.value(<int>[
            ...utf8.encode(token),
            ...List.filled(257 - token.length, 0x2e),
          ]),
        ).fold<List<int>>([], (all, chunk) {
          all.addAll(chunk);
          return all;
        });

    expect(utf8.decode(bytes), isNot(contains(token)));
  });

  test('redacts a token crossing multiple large emission boundaries', () async {
    const token = 'multi-boundary-canary-value-123456';
    final encodedToken = utf8.encode(token);
    registerSecret(token);
    final bytes =
        await redactCacheStream(
          Stream.fromIterable([
            <int>[
              ...List.filled(740, 0x2e),
              ...encodedToken,
              ...List.filled(1000 - 740 - encodedToken.length, 0x2e),
            ],
            <int>[
              ...List.filled(740, 0x2e),
              ...encodedToken,
              ...List.filled(1000 - 740 - encodedToken.length, 0x2e),
            ],
          ]),
        ).fold<List<int>>([], (all, chunk) {
          all.addAll(chunk);
          return all;
        });

    expect(utf8.decode(bytes), isNot(contains(token)));
  });
}
