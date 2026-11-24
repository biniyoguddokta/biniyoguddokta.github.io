import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_model.dart';
import 'api_service.dart';
import 'loss_project_service.dart';

class ReportApiException implements Exception {
  const ReportApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ReportService {
  ReportService._();
  static const Duration _timeout = Duration(seconds: 40);
  static SomitiReportData? _cache;

  static Future<SomitiReportData> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString('authToken') ?? '').trim();
    if (token.isEmpty) throw const ReportApiException('লগইন সেশন পাওয়া যায়নি। আবার লগইন করুন।');

    final uri = Uri.parse(ApiService.baseUrl).replace(queryParameters: {
      'action': 'getCompleteReports',
      'token': token,
    });
    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw ReportApiException('সার্ভার ত্রুটি: HTTP ${response.statusCode}');
      }
      final body = response.body.trim();
      if (body.isEmpty || body.contains('<!DOCTYPE html>') || body.toLowerCase().contains('<html')) {
        throw const ReportApiException('Apps Script JSON response দেয়নি। Code.gs deploy হয়েছে কি না যাচাই করুন।');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) throw const ReportApiException('রিপোর্টের response format সঠিক নয়।');
      final json = Map<String, dynamic>.from(decoded);
      if (json['status'] == 'error') {
        throw ReportApiException((json['message'] ?? 'রিপোর্ট লোড করা যায়নি।').toString());
      }
      final localLoss = await LossProjectService.load();
      final result = SomitiReportData.fromJson(json, localLossProjects: localLoss);
      _cache = result;
      return result;
    } on TimeoutException {
      throw const ReportApiException('সার্ভারের উত্তর পেতে বেশি সময় লাগছে। আবার চেষ্টা করুন।');
    } on ReportApiException {
      rethrow;
    } catch (e) {
      throw ReportApiException('রিপোর্ট লোড করতে সমস্যা হয়েছে: $e');
    }
  }

  static void clearCache() => _cache = null;
}
