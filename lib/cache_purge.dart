/// A cache purge did not remove every target entry.
///
/// The cause is retained for programmatic diagnostics, but [toString] is
/// deliberately generic so filesystem details or credentials cannot reach a
/// user-visible error.
class CachePurgeException implements Exception {
  CachePurgeException(this.cacheName, this.cause, this.causeStackTrace);

  final String cacheName;
  final Object cause;
  final StackTrace causeStackTrace;

  @override
  String toString() => 'CachePurgeException($cacheName)';
}
