import 'dart:convert';

double numToDouble(dynamic v) => (v as num).toDouble();

double? numToDoubleNullable(dynamic v) =>
    v == null ? null : (v as num).toDouble();

List<String> parsePermissions(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return List<String>.from(raw);
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
  }
  return [];
}
