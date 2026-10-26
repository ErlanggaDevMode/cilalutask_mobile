/// Represents the synchronization state between local client and Cloud Firestore.
enum SyncStatus {
  /// All operational data is successfully saved and synchronized with Cloud Firestore.
  synced,

  /// Actively transmitting or fetching data to/from Cloud Firestore.
  syncing,

  /// Working offline; changes are saved locally to disk cache and will be synchronized when online.
  offline,

  /// A synchronization failure occurred (e.g., permission denied or network fault).
  error,
}

/// Standardized classification of data error codes.
enum DataErrorCode {
  /// Blocked by Cloud Firestore Security Rules (e.g., cross-company access or unauthorized role).
  permissionDenied,

  /// Network is down or Cloud Firestore server timed out / is unreachable.
  networkUnavailable,

  /// The requested document or company does not exist.
  notFound,

  /// The provided payload violates validation (e.g., forbidden password fields).
  invalidData,

  /// Unclassified or internal exception.
  unknown,
}

/// Typed exception for data layer errors providing clear user-facing messages.
class DataException implements Exception {
  final String message;
  final DataErrorCode code;
  final dynamic originalError;

  const DataException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => 'DataException($code): $message';
}
