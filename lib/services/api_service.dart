
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'audit_log_service.dart';

class ApiService {
  static final Map<String, dynamic> _getCache = {};
  static final Map<String, Future<dynamic>> _pendingGets = {};
  static int _cacheGeneration = 0;

  // IMPORTANT:
  // Verify this URL against your latest Google Apps Script deployment.
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycby8WDNL-Mvy34P04vw_zbkexLjE8OjqDIXVlP7HYS6Bq6R_v8SEqhLPx3sL0Q89YdvetQ/exec';

  static const Map<String, String> _postHeaders = {
    'Content-Type': 'text/plain;charset=utf-8',
  };

  static void clearCache() {
    _cacheGeneration++;
    _getCache.clear();
    _pendingGets.clear();
  }

  // POST using a CORS-safelisted content type.
  // The browser follows Apps Script redirects automatically.
  static Future<http.Response> _postAppsScript(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    return http.post(
      uri,
      headers: headers,
      body: body,
    );
  }

  // ---------------- Authentication ----------------

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {'action': 'login'},
      );

      final response = await _postAppsScript(
        uri,
        _postHeaders,
        jsonEncode({
          'phone': phone,
          'pin': pin,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'status': 'error',
          'message': 'Server Error: ${response.statusCode}',
        };
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {
          'status': 'error',
          'message': 'সার্ভারের উত্তর সঠিক নয়।',
        };
      }

      if (decoded['status'] == 'success') {
        final user = Map<String, dynamic>.from(
          decoded['user'] as Map,
        );

        final token = (decoded['token'] ?? '').toString();

        if (token.isEmpty) {
          return {
            'status': 'error',
            'message': 'সার্ভার লগইন টোকেন দেয়নি।',
          };
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('authToken', token);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString(
          'userPhone',
          (user['phone'] ?? phone).toString(),
        );
        await prefs.setString(
          'userRole',
          (user['role'] ?? 'Member').toString(),
        );
        await prefs.setString(
          'userName',
          (user['name'] ?? 'User').toString(),
        );

        clearCache();
      }

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'লগইন করা যায়নি: $e',
      };
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('authToken');
    await prefs.remove('isLoggedIn');
    await prefs.remove('userPhone');
    await prefs.remove('userRole');
    await prefs.remove('userName');

    clearCache();
  }

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // ---------------- GET Requests ----------------

  static Future<dynamic> _getData(String action) async {
    if (_getCache.containsKey(action)) {
      return _getCache[action];
    }

    final pending = _pendingGets[action];

    if (pending != null) {
      return pending;
    }

    final requestGeneration = _cacheGeneration;
    final request = _fetchData(action);

    _pendingGets[action] = request;

    try {
      final result = await request;

      if (requestGeneration == _cacheGeneration &&
          !(result is Map && result['status'] == 'error')) {
        _getCache[action] = result;
      }

      return result;
    } finally {
      if (identical(_pendingGets[action], request)) {
        _pendingGets.remove(action);
      }
    }
  }

  static Future<dynamic> _fetchData(String action) async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'status': 'error',
          'message': 'লগইন সেশন নেই। আবার লগইন করুন।',
        };
      }

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': action,
          'token': token,
        },
      );

      final response = await http.get(uri);

      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        return {
          'status': 'error',
          'message': 'Apps Script Web App access/deployment সমস্যা।',
        };
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['status'] == 'error') {
          return {
            'status': 'error',
            'message': decoded['message'] ?? 'Request rejected',
          };
        }

        return decoded;
      }

      return {
        'status': 'error',
        'message': 'Server Error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Internet/API Issue: $e',
      };
    }
  }

  // ---------------- POST Requests ----------------

  static Future<Map<String, dynamic>> _postData(
    String action,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _token();

      if (token == null || token.isEmpty) {
        return {
          'status': 'error',
          'message': 'লগইন সেশন নেই। আবার লগইন করুন।',
        };
      }

      final payload = Map<String, dynamic>.from(body)
        ..['token'] = token;

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {'action': action},
      );

      final response = await _postAppsScript(
        uri,
        _postHeaders,
        jsonEncode(payload),
      );

      if (response.body.contains('<!DOCTYPE html>') ||
          response.body.contains('<html>')) {
        await AuditLogService.record(
          action: action,
          details: 'Apps Script HTML/permission response',
          status: 'error',
        );

        return {
          'status': 'error',
          'message': 'Apps Script access/deployment সমস্যা।',
        };
      }

      if (response.statusCode != 200) {
        await AuditLogService.record(
          action: action,
          details: 'HTTP ${response.statusCode}',
          status: 'error',
        );

        return {
          'status': 'error',
          'message': 'Server Error: ${response.statusCode}',
        };
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return {
          'status': 'error',
          'message': 'সার্ভারের উত্তর সঠিক নয়।',
        };
      }

      final result = Map<String, dynamic>.from(decoded);

      if (result['status'] == 'success') {
        clearCache();

        await AuditLogService.record(
          action: action,
          details: 'Google Sheets API operation completed',
        );
      } else {
        await AuditLogService.record(
          action: action,
          details: result['message']?.toString() ?? 'Request rejected',
          status: 'error',
        );
      }

      return result;
    } catch (e) {
      await AuditLogService.record(
        action: action,
        details: 'Network/API exception: $e',
        status: 'error',
      );

      return {
        'status': 'error',
        'message': 'Internet/API Issue: $e',
      };
    }
  }

  // ---------------- Members ----------------

  static Future<dynamic> getAllMembers() =>
      _getData('getAllMembers');

  static Future<Map<String, dynamic>> addMember({
    required String name,
    required String phone,
    required String email,
    required String pin,
    required String role,
    required String designation,
  }) =>
      _postData('addMember', {
        'name': name,
        'phone': phone,
        'email': email,
        'pin': pin,
        'role': role,
        'designation': designation,
      });

  static Future<Map<String, dynamic>> updateRole({
    required String phone,
    required String newRole,
  }) =>
      _postData('updateRole', {
        'phone': phone,
        'newRole': newRole,
      });

  static Future<Map<String, dynamic>> updateDesignation({
    required String phone,
    required String designation,
  }) =>
      _postData('updateDesignation', {
        'phone': phone,
        'designation': designation,
      });

  static Future<Map<String, dynamic>> updatePin({
    required String phone,
    required String newPin,
  }) =>
      _postData('updatePin', {
        'phone': phone,
        'newPin': newPin,
      });

  static Future<Map<String, dynamic>> updateProfilePic({
    required String phone,
    required String base64,
  }) =>
      _postData('updateProfilePic', {
        'phone': phone,
        'base64': base64,
      });

  // ---------------- Transactions ----------------

  static Future<dynamic> getTransactions() =>
      _getData('getTransactions');

  static Future<Map<String, dynamic>> addTransaction({
    required String type,
    required String amount,
    required String note,
    required String memberName,
    required String status,
    required String date,
    required String paymentMethod,
  }) =>
      _postData('addTransaction', {
        'type': type,
        'amount': amount,
        'note': note,
        'memberName': memberName,
        'status': status,
        'date': date,
        'paymentMethod': paymentMethod,
      });

  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String rowIndex,
    required String status,
  }) =>
      _postData('updateTransactionStatus', {
        'rowIndex': rowIndex,
        'status': status,
      });

  static Future<Map<String, dynamic>> generateAutoDue() =>
      _postData('generateAutoDue', {});

  // ---------------- Investments ----------------

  static Future<dynamic> getInvestments() =>
      _getData('getInvestments');

  static Future<Map<String, dynamic>> addInvestment({
    required String sector,
    required String projectName,
    required String investAmount,
    required String startDate,
    required String endDate,
    required String profitAmount,
  }) =>
      _postData('addInvestment', {
        'sector': sector,
        'projectName': projectName,
        'investAmount': investAmount,
        'startDate': startDate,
        'endDate': endDate,
        'profitAmount': profitAmount,
      });

  static Future<Map<String, dynamic>> completeInvestment({
    required String rowIndex,
    required String profitAmount,
    required String completionDate,
    required String note,
  }) =>
      _postData('completeInvestment', {
        'rowIndex': rowIndex,
        'profitAmount': profitAmount,
        'completionDate': completionDate,
        'note': note,
      });

  static Future<Map<String, dynamic>> deleteInvestment({
    required String rowIndex,
  }) =>
      _postData('deleteInvestment', {'rowIndex': rowIndex});

  // ---------------- Installment Module ----------------

  static Future<dynamic> getInstallmentData() =>
      _getData('getInstallmentData');

  static Future<Map<String, dynamic>> saveInstallmentContract(
    Map<String, dynamic> data,
  ) =>
      _postData('installmentSaveContract', data);

  static Future<Map<String, dynamic>> deleteInstallmentContract({
    required String contractId,
    required String actorPhone,
  }) =>
      _postData('installmentDeleteContract', {
        'contractId': contractId,
        'actorPhone': actorPhone,
      });

  static Future<Map<String, dynamic>> addInstallmentPayment(
    Map<String, dynamic> data,
  ) =>
      _postData('installmentAddPayment', data);

  static Future<Map<String, dynamic>> deleteInstallmentPayment({
    required String paymentId,
    required String actorPhone,
  }) =>
      _postData('installmentDeletePayment', {
        'paymentId': paymentId,
        'actorPhone': actorPhone,
      });

  static Future<Map<String, dynamic>> saveInstallmentExpense(
    Map<String, dynamic> data,
  ) =>
      _postData('installmentSaveExpense', data);

  static Future<Map<String, dynamic>> deleteInstallmentExpense({
    required String expenseId,
    required String actorPhone,
  }) =>
      _postData('installmentDeleteExpense', {
        'expenseId': expenseId,
        'actorPhone': actorPhone,
      });

  static Future<Map<String, dynamic>> saveInstallmentProduct(
    Map<String, dynamic> data,
  ) =>
      _postData('installmentSaveProduct', data);

  static Future<Map<String, dynamic>> deleteInstallmentProduct({
    required String productId,
    required String actorPhone,
  }) =>
      _postData('installmentDeleteProduct', {
        'productId': productId,
        'actorPhone': actorPhone,
      });

  // ---------------- Meetings & Constitution ----------------

  static Future<dynamic> getMeetings() =>
      _getData('getMeetings');

  static Future<Map<String, dynamic>> addMeeting({
    required String date,
    required String title,
    required String description,
  }) =>
      _postData('addMeeting', {
        'date': date,
        'title': title,
        'description': description,
      });

  static Future<dynamic> getConstitution() =>
      _getData('getConstitution');

  static Future<Map<String, dynamic>> addConstitution({
    required String title,
    required String content,
  }) =>
      _postData('addConstitution', {
        'title': title,
        'content': content,
      });

  static Future<dynamic> getLateFees() =>
      _getData('getLateFees');
}
