import 'package:cloud_firestore/cloud_firestore.dart';

/// Defensive data parsing utility to ensure compatibility with Cloud Firestore types
/// (like [Timestamp]), standard JSON strings, integers, and dynamic nested maps.
class DataParser {
  const DataParser._();

  /// Parse dynamic date values safely.
  /// Supports: [DateTime], [Timestamp], ISO-8601 [String], and millisecond [int].
  static DateTime parseDateTime(dynamic val, {DateTime? fallback}) {
    if (val == null) return fallback ?? DateTime.now();
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      return DateTime.tryParse(val) ?? fallback ?? DateTime.now();
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return fallback ?? DateTime.now();
  }

  /// Parse nullable DateTime safely.
  static DateTime? parseNullableDateTime(dynamic val) {
    if (val == null) return null;
    return parseDateTime(val);
  }

  /// Safely convert any map (including `_Map<Object?, Object?>`) into `Map<String, dynamic>`.
  static Map<String, dynamic> parseMap(dynamic val) {
    if (val == null) return <String, dynamic>{};
    if (val is Map<String, dynamic>) return val;
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  /// Safely parse list of items with fallback on element errors.
  static List<T> parseList<T>(
    dynamic val,
    T Function(Map<String, dynamic> map) mapper,
  ) {
    if (val == null || val is! List) return <T>[];
    final result = <T>[];
    for (final item in val) {
      if (item is Map) {
        try {
          result.add(mapper(parseMap(item)));
        } catch (_) {
          // Skip corrupted individual element defensively
        }
      }
    }
    return result;
  }

  /// Safely parse list of strings.
  static List<String> parseStringList(dynamic val) {
    if (val == null || val is! List) return <String>[];
    return val.map((e) => e.toString()).toList();
  }
}
