import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Keys Linkzly writes into every SDK event, plus the reserved `__` prefix.
/// A property using one is still sent; the SDK only warns.
const Set<String> _reservedKeys = <String>{
  'parser_version',
  'provider_name',
  'provider_slug',
  'referrer_domain',
  'attribution_signal',
  'attribution_confidence',
  'traffic_channel',
  'bot_score',
  'bot_name',
  'bot_reason',
  'device_data',
};

void _debugWarn(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Marks a value that can't be sent.
class _Unsendable {
  const _Unsendable(this.reason);
  final String reason;
}

/// Turns event properties into values the message codec and the wire
/// contract accept (spec section 6). Never throws.
///
/// - DateTime: ISO 8601 UTC text with 3 ms digits and `Z`; microseconds cut.
/// - Top-level null: key left out.
/// - Top-level NaN, Infinity or unsupported value: dropped, one warning.
/// - Inside a list or map: null stays null; an unsendable value becomes null.
/// - Reserved keys: warning, still sent.
Map<String, Object?> encodeEventProperties(
  String eventName,
  Map<String, Object?> properties, {
  void Function(String message)? warn,
}) {
  final void Function(String) log = warn ?? _debugWarn;
  final Map<String, Object?> out = <String, Object?>{};

  properties.forEach((String key, Object? value) {
    if (value == null) return;
    Object? encoded;
    try {
      encoded = _encode(value, nested: false, ancestors: <Object>[]);
    } catch (_) {
      encoded = const _Unsendable('could not be read');
    }
    if (encoded is _Unsendable) {
      log(
        'Linkzly: event "$eventName" property "$key" ${encoded.reason}; '
        'dropped, the event is still sent.',
      );
      return;
    }
    if (key.startsWith('__') || _reservedKeys.contains(key)) {
      log(
        'Linkzly: event "$eventName" property "$key" uses a name reserved '
        'by Linkzly; it is still sent.',
      );
    }
    out[key] = encoded;
  });
  return out;
}

Object? _encode(
  Object? value, {
  required bool nested,
  required List<Object> ancestors,
}) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (value.isFinite) return value;
    return nested ? null : const _Unsendable('is NaN or Infinity');
  }
  if (value is DateTime) return _isoUtc(value);
  // Binary data is not a property value (a typed list is also a List).
  if (value is TypedData) {
    return nested ? null : const _Unsendable('is binary data');
  }
  if (value is List || value is Map) {
    // A list or map that contains itself would never end.
    if (ancestors.any((Object a) => identical(a, value))) return null;
    ancestors.add(value);
    try {
      if (value is List) {
        return value
            .map(
              (Object? item) =>
                  _encode(item, nested: true, ancestors: ancestors),
            )
            .toList();
      }
      final Map<String, Object?> map = <String, Object?>{};
      (value as Map<Object?, Object?>).forEach((Object? k, Object? v) {
        map[k is String ? k : '$k'] = _encode(
          v,
          nested: true,
          ancestors: ancestors,
        );
      });
      return map;
    } finally {
      ancestors.removeLast();
    }
  }
  return nested
      ? null
      : _Unsendable('has a type that can\'t be sent (${value.runtimeType})');
}

/// ISO 8601 in UTC with exactly 3 ms digits, e.g. 2026-10-27T10:15:30.123Z.
/// Cuts microseconds toward the earlier millisecond, also before 1970.
String _isoUtc(DateTime value) {
  final int micros = value.microsecondsSinceEpoch;
  // Dart's % is never negative here, so this floors.
  final int millis = (micros - micros % 1000) ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch(
    millis,
    isUtc: true,
  ).toIso8601String();
}
