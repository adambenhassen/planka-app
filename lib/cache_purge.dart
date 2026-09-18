import 'security_redaction.dart';

/// A cache purge did not remove every target entry.
///
/// The cause is retained only as a redacted summary. Keeping the original
/// exception here would let a filesystem or transport error retain a token
/// after the purge crossed a security boundary.
class CachePurgeException implements Exception {
  CachePurgeException(
    String cacheName,
    Object cause,
    StackTrace causeStackTrace,
  ) : cacheName = _safeName(cacheName),
      cause = redactDiagnostic(cause),
      causeStackTrace = StackTrace.fromString(
        redactDiagnostic(causeStackTrace),
      );

  final String cacheName;
  final String cause;
  final StackTrace causeStackTrace;

  @override
  String toString() => 'CachePurgeException($cacheName)';

  static String _safeName(String value) => switch (value) {
    'account' || 'envelopes' || 'media' => value,
    _ => 'cache',
  };
}

/// A cache backend failed. The backend exception is intentionally not retained
/// because it may contain a URL, header, or credential.
class CacheOperationException implements Exception {
  CacheOperationException(String operation)
    : operation = switch (operation) {
        'getSingleFile' ||
        'getFile' ||
        'getFileStream' ||
        'downloadFile' ||
        'getFileFromCache' ||
        'getFileFromMemory' ||
        'putFile' ||
        'putFileStream' ||
        'removeFile' ||
        'emptyCache' ||
        'dispose' ||
        'fileService' => operation,
        _ => 'cache',
      };

  final String operation;

  @override
  String toString() => 'CacheOperationException($operation)';
}
