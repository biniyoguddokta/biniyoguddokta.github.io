import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local activity history. This is useful for operational review but is
/// not a tamper-proof/server-authoritative financial audit trail.
class AuditLogService {
  AuditLogService._();
  static const String _key = 'somiti_audit_events_v1';
  static const int _maxEntries = 1000;

  static Future<void> record({
    required String action,
    required String details,
    String status = 'success',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await read();
      entries.insert(0, {
        'id': '${DateTime.now().microsecondsSinceEpoch}_${action.hashCode}',
        'at': DateTime.now().toIso8601String(),
        'actor': prefs.getString('userName') ?? 'Unknown user',
        'actorPhone': prefs.getString('userPhone') ?? '',
        'action': action,
        'details': details,
        'status': status,
      });
      if (entries.length > _maxEntries) entries.removeRange(_maxEntries, entries.length);
      await prefs.setString(_key, jsonEncode(entries));
      // Keep the legacy key readable for older screens/exports.
      await prefs.setStringList('local_audit', entries.map((e) => '${e['at']} • ${e['actor']} • ${e['action']} • ${e['details']}').toList());
    } catch (_) {
      // Logging must never prevent a user operation from completing.
    }
  }

  static Future<List<Map<String, dynamic>>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final legacy = prefs.getStringList('local_audit') ?? [];
      return legacy.map((line) => <String, dynamic>{
        'at': '', 'actor': '', 'action': 'Legacy activity', 'details': line,
        'status': 'unknown', 'actorPhone': '',
      }).toList();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> restore(List<dynamic> values) async {
    final safe = values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(_maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(safe));
    await prefs.setStringList('local_audit', safe.map((e) => '${e['at'] ?? ''} • ${e['actor'] ?? ''} • ${e['action'] ?? ''} • ${e['details'] ?? ''}').toList());
  }
}
