import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LossProjectService {
  static const String _key = 'loss_project_records_v1';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(rows));
  }

  static double number(dynamic value) => double.tryParse((value ?? '0').toString().replaceAll(',', '')) ?? 0;

  static double netLoss(List<Map<String, dynamic>> rows) => rows.fold<double>(
    0, (sum, row) => sum + (number(row['totalLoss']) - number(row['recoveredAmount'])).clamp(0, double.infinity).toDouble());
}
