import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_model.dart';
import 'api_service.dart';
import 'loss_project_service.dart';
import 'stock_service.dart';

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

    try {
      final uri = Uri.parse(ApiService.baseUrl).replace(queryParameters: {
        'action': 'getCompleteReports', 'token': token,
      });
      Map<String, dynamic>? aggregate;
      try {
        final response = await http.get(uri).timeout(_timeout);
        if (response.statusCode == 200 && response.body.trim().isNotEmpty &&
            !response.body.contains('<!DOCTYPE html>') && !response.body.toLowerCase().contains('<html')) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['status'] != 'error' &&
              (decoded.containsKey('members') || decoded.containsKey('transactions') || decoded.containsKey('investments'))) {
            aggregate = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {
        // Older Apps Script deployments may not expose getCompleteReports.
      }

      dynamic safe(Future<dynamic> Function() request) async {
        try { return await request(); } catch (_) { return null; }
      }
      if (aggregate == null) {
        final results = await Future.wait<dynamic>([
          safe(() => ApiService.getAllMembers()),
          safe(() => ApiService.getTransactions()),
          safe(() => ApiService.getInvestments()),
          safe(() => ApiService.getInstallmentData()),
          safe(() => StockService.loadAll(forceRefresh: forceRefresh)),
        ]).timeout(_timeout);
        final stock = results[4];
        aggregate = {
          'members': results[0] is List ? results[0] : <dynamic>[],
          'transactions': results[1] is List ? results[1] : <dynamic>[],
          'investments': results[2] is List ? results[2] : <dynamic>[],
          'installments': results[3] is Map && results[3]['error'] == null ? results[3] : <String, dynamic>{},
          'stock': stock == null ? <String, dynamic>{} : {
            'items': stock.items.map((e) => e.toJson()).toList(),
            'transactions': stock.transactions.map((e) => e.toJson()).toList(),
            'expenses': stock.expenses.map((e) => e.toJson()).toList(),
          },
          'generatedAt': DateTime.now().toIso8601String(),
          'salary': {'connected': false, 'message': 'Salary module-এর রিপোর্ট API সংযুক্ত নয়।'},
        };
        final hasCoreData = results.take(3).any((v) => v is List);
        if (!hasCoreData) throw const ReportApiException('সদস্য, লেনদেন বা বিনিয়োগের তথ্য সার্ভার থেকে পাওয়া যায়নি।');
      }
      final localLoss = await LossProjectService.load();
      final result = SomitiReportData.fromJson(aggregate, localLossProjects: localLoss);
      _cache = result;
      return result;
    } on TimeoutException {
      throw const ReportApiException('সার্ভারের উত্তর পেতে বেশি সময় লাগছে। আবার চেষ্টা করুন।');
    } on ReportApiException { rethrow; }
    catch (e) { throw ReportApiException('রিপোর্ট লোড করতে সমস্যা হয়েছে: $e'); }
  }

  static void clearCache() => _cache = null;
}
