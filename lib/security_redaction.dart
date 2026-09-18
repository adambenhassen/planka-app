import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final Set<String> _secrets = <String>{};

/// Adds a credential to the process-local redaction set.
///
/// Credentials still exist where the protocol needs them, such as an HTTP
/// header. This set only protects strings that cross diagnostic, cache, or UI
/// boundaries.
void registerSecret(String? secret) {
  if (secret == null || secret.isEmpty) return;
  _secrets.add(secret);
}

/// Removes registered credentials and common reversible representations from a
/// string before it reaches a diagnostic or user-visible boundary.
String redactDiagnostic(Object? value) {
  var result = '$value';
  final variants = _secretVariants();
  final ordered = variants.where((variant) => variant.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final variant in ordered) {
    if (variant.length >= 4) {
      result = result.replaceAll(variant, '[REDACTED]');
      continue;
    }
    // A short credential still needs redaction, but replacing it inside every
    // word would corrupt unrelated metadata such as the JSON key "item".
    result = result.replaceAll(
      RegExp('(?<![A-Za-z0-9])${RegExp.escape(variant)}(?![A-Za-z0-9])'),
      '[REDACTED]',
    );
  }
  // Cover an unregistered server-side canary at a diagnostic boundary. Real
  // credentials are registered at account/API construction, while this guard
  // protects malformed or synthetic exceptions that arrive before that step.
  result = result.replaceAll(
    RegExp(
      r'\b(?:secret|token|access[-_ ]?token|refresh[-_ ]?token|pending[-_ ]?token|jwt|bearer|credential|password|authorization|cookie)[-_/:= ]+[A-Za-z0-9._~+/=-]{4,}',
      caseSensitive: false,
    ),
    '[REDACTED]',
  );
  return result;
}

/// Returns a URL safe to persist as cache metadata.
///
/// Authenticated media uses its cookie header for credentials. Dropping the
/// query and fragment prevents a credential accidentally placed in either
/// location from becoming a durable cache input. Origin and path are retained.
String cacheSafeUrl(String value) {
  final parsed = Uri.tryParse(value);
  if (parsed == null) return redactDiagnostic(value);
  return redactDiagnostic(
    parsed.replace(userInfo: '', query: '', fragment: '').toString(),
  );
}

/// Returns a safe identity input that keeps non-secret query variants.
String cacheIdentityUrl(String value) {
  final parsed = Uri.tryParse(value);
  if (parsed == null) return redactDiagnostic(value);
  return redactDiagnostic(
    parsed.replace(userInfo: '', fragment: '').toString(),
  );
}

/// Prevents a registered credential accidentally being persisted as a cache
/// payload. Normal media is binary and is returned unchanged.
Uint8List redactCacheBytes(Uint8List bytes) {
  final decoded = utf8.decode(bytes, allowMalformed: true);
  final redacted = redactDiagnostic(decoded);
  if (redacted == decoded) return bytes;
  return Uint8List.fromList(utf8.encode(redacted));
}

Set<String> _secretVariants() {
  final variants = <String>{};
  for (final secret in _secrets) {
    variants.add(secret);
    variants.add(Uri.encodeComponent(secret));
    if (secret.length >= 8) {
      final bytes = utf8.encode(secret);
      final standardBase64 = base64.encode(bytes);
      final urlBase64 = base64Url.encode(bytes);
      variants.add(standardBase64);
      variants.add(standardBase64.replaceAll('=', ''));
      variants.add(urlBase64);
      variants.add(urlBase64.replaceAll('=', ''));
      variants.add(sha256.convert(bytes).toString());
    }
  }
  return variants;
}

int _indexOfBytes(List<int> bytes, List<int> needle, int start) {
  if (needle.isEmpty) return start;
  for (var index = start; index <= bytes.length - needle.length; index++) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (bytes[index + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return index;
  }
  return -1;
}

int _safeSplit(List<int> bytes, int candidate, Set<String> variants) {
  var split = candidate;
  for (final variant in variants) {
    final encoded = utf8.encode(variant);
    var index = _indexOfBytes(bytes, encoded, 0);
    while (index >= 0) {
      final end = index + encoded.length;
      if (index < split && end > split) split = index;
      index = _indexOfBytes(bytes, encoded, index + 1);
    }
  }
  return split;
}

/// Redacts a byte stream while retaining only a bounded suffix between input
/// chunks. The suffix prevents a credential split across network chunks from
/// being emitted before the complete value can be recognized.
Stream<List<int>> redactCacheStream(Stream<List<int>> source) async* {
  final variants = _secretVariants();
  var longestVariant = 0;
  for (final variant in variants) {
    final length = utf8.encode(variant).length;
    if (length > longestVariant) longestVariant = length;
  }
  final window = longestVariant + 64 > 256 ? longestVariant + 64 : 256;
  final pending = <int>[];

  await for (final chunk in source) {
    pending.addAll(chunk);
    if (pending.length <= window) continue;
    final split = _safeSplit(pending, pending.length - window, variants);
    if (split == 0) continue;
    yield redactCacheBytes(Uint8List.fromList(pending.sublist(0, split)));
    pending.removeRange(0, split);
  }
  if (pending.isNotEmpty) {
    yield redactCacheBytes(Uint8List.fromList(pending));
  }
}
