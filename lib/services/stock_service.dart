import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stock_model.dart';
import 'api_service.dart';

/// Google Sheets / Apps Script bridge for the Stock Business module.
///
/// Backend contract:
/// GET  ?action=stockGetData&token=...
/// POST ?action=stockSaveItem|stockSaveTransaction|stockSavePayment|
///      stockSaveExpense|stockSaveLocation|stockSaveParty|stockSaveMovement|
///      stockSaveAdjustment|stockSaveReservation
/// POST ?action=stockDeleteRecord  {entityType, id}
/// POST ?action=stockApproveAdjustment {id, approvalStatus, reason}
///
/// `stockGetData` must return:
/// {status:"success", data:{items:[], transactions:[], payments:[],
/// expenses:[], locations:[], parties:[], movements:[], adjustments:[],
/// auditLogs:[], reservations:[]}}
///
/// The Apps Script backend must validate the session token and role on every
/// action, use LockService for writes, and append audit rows server-side.
class StockService {
  StockService._();

  static const Duration _timeout = Duration(seconds: 35);
  static const String _getAction = 'stockGetData';

  static Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      throw const StockApiException('লগইন সেশন নেই। আবার লগইন করুন।');
    }
    return token;
  }

  static Uri _actionUri(String action, {String? token}) {
    final base = Uri.parse(ApiService.baseUrl);
    return base.replace(queryParameters: {
      ...base.queryParameters,
      'action': action,
      if (token != null) 'token': token,
    });
  }

  static Future<http.Response> _postRedirectSafe(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..followRedirects = false
        ..headers.addAll(headers)
        ..body = body;
      final streamed = await client.send(request).timeout(_timeout);
      var response = await http.Response.fromStream(streamed);
      if ([301, 302, 303].contains(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) {
          throw const StockApiException(
            'Apps Script redirect URL পাওয়া যায়নি।',
          );
        }
        final redirected = uri.resolve(location);
        if (redirected.scheme != 'https' ||
            !(redirected.host == 'script.googleusercontent.com' ||
                redirected.host.endsWith('.googleusercontent.com'))) {
          throw const StockApiException(
            'Apps Script থেকে অস্বাভাবিক redirect পাওয়া গেছে।',
          );
        }
        response = await client.get(redirected).timeout(_timeout);
      }
      return response;
    } finally {
      client.close();
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw StockApiException('Server Error: ${response.statusCode}');
    }
    final body = response.body.trim();
    if (body.isEmpty || body.contains('<!DOCTYPE html>') ||
        body.contains('<html')) {
      throw const StockApiException(
        'Apps Script Web App access/deployment সমস্যা। JSON response পাওয়া যায়নি।',
      );
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const StockApiException('সার্ভারের JSON response সঠিক নয়।');
    }
    if (decoded is! Map) {
      throw const StockApiException('সার্ভারের response format সঠিক নয়।');
    }
    final result = Map<String, dynamic>.from(decoded);
    if (result['status'] == 'error') {
      throw StockApiException(
        (result['message'] ?? 'Stock API request rejected').toString(),
      );
    }
    if (result['status'] != 'success') {
      throw StockApiException(
        (result['message'] ?? 'Stock API success status পাওয়া যায়নি।')
            .toString(),
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> _get(String action) async {
    final token = await _requireToken();
    final response = await http
        .get(_actionUri(action, token: token))
        .timeout(_timeout);
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final token = await _requireToken();
    final body = Map<String, dynamic>.from(payload)..['token'] = token;
    final response = await _postRedirectSafe(
      _actionUri(action),
      const {'Content-Type': 'application/json'},
      jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  static Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final value = response['data'] ?? response['result'] ?? response;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const StockApiException('Stock data object পাওয়া যায়নি।');
  }

  static List<dynamic> _list(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return const [];
    if (value is List) return value;
    throw StockApiException('Stock data "$key" তালিকা নয়।');
  }

  /// Loads all Stock sheets in one round trip.
  static Future<StockData> loadAll({bool forceRefresh = false}) async {
    final response = await _get(_getAction);
    final data = _dataMap(response);
    return StockData(
      items: _list(data, 'items')
          .map((e) => StockItem.fromJson(_asMap(e))).toList(),
      transactions: _list(data, 'transactions')
          .map((e) => StockTransaction.fromJson(_asMap(e))).toList(),
      payments: _list(data, 'payments')
          .map((e) => StockPayment.fromJson(_asMap(e))).toList(),
      expenses: _list(data, 'expenses')
          .map((e) => StockExpense.fromJson(_asMap(e))).toList(),
      locations: _list(data, 'locations')
          .map((e) => StockLocation.fromJson(_asMap(e))).toList(),
      parties: _list(data, 'parties')
          .map((e) => StockParty.fromJson(_asMap(e))).toList(),
      movements: _list(data, 'movements')
          .map((e) => StockMovement.fromJson(_asMap(e))).toList(),
      adjustments: _list(data, 'adjustments')
          .map((e) => StockAdjustment.fromJson(_asMap(e))).toList(),
      auditLogs: _list(data, 'auditLogs')
          .map((e) => StockAuditLog.fromJson(_asMap(e))).toList(),
      reservations: _list(data, 'reservations')
          .map((e) => StockReservation.fromJson(_asMap(e))).toList(),
      lastSyncedAt: DateTime.now(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const StockApiException('Stock record object সঠিক নয়।');
  }

  static Future<Map<String, dynamic>> _save(
    String action,
    String entityType,
    String id,
    Map<String, dynamic> data,
  ) =>
      _post(action, {
        'entityType': entityType,
        'id': id,
        'record': data,
      });

  static Future<Map<String, dynamic>> saveItem(StockItem item) =>
      _save('stockSaveItem', 'item', item.id, item.toJson());

  static Future<Map<String, dynamic>> saveTransaction(
    StockTransaction transaction,
  ) =>
      _save('stockSaveTransaction', 'transaction', transaction.id,
          transaction.toJson());

  static Future<Map<String, dynamic>> savePayment(StockPayment payment) =>
      _save('stockSavePayment', 'payment', payment.id, payment.toJson());

  static Future<Map<String, dynamic>> saveExpense(StockExpense expense) =>
      _save('stockSaveExpense', 'expense', expense.id, expense.toJson());

  static Future<Map<String, dynamic>> saveLocation(StockLocation location) =>
      _save('stockSaveLocation', 'location', location.id, location.toJson());

  static Future<Map<String, dynamic>> saveParty(StockParty party) =>
      _save('stockSaveParty', 'party', party.id, party.toJson());

  static Future<Map<String, dynamic>> saveMovement(StockMovement movement) =>
      _save('stockSaveMovement', 'movement', movement.id, movement.toJson());

  static Future<Map<String, dynamic>> saveAdjustment(
    StockAdjustment adjustment,
  ) =>
      _save('stockSaveAdjustment', 'adjustment', adjustment.id,
          adjustment.toJson());

  static Future<Map<String, dynamic>> saveReservation(
    StockReservation reservation,
  ) =>
      _save('stockSaveReservation', 'reservation', reservation.id,
          reservation.toJson());

  /// Deletion should be implemented as a backend soft-delete/archive.
  static Future<Map<String, dynamic>> archiveRecord({
    required String entityType,
    required String id,
    required String reason,
  }) =>
      _post('stockDeleteRecord', {
        'entityType': entityType,
        'id': id,
        'reason': reason,
      });

  static Future<Map<String, dynamic>> approveAdjustment({
    required String id,
    required String approvalStatus,
    required String reason,
  }) =>
      _post('stockApproveAdjustment', {
        'id': id,
        'approvalStatus': approvalStatus,
        'reason': reason,
      });

  static Future<Map<String, dynamic>> recordPayment(StockPayment payment) =>
      _post('stockRecordPayment', {'payment': payment.toJson()});

  static Future<Map<String, dynamic>> transferStock(StockMovement movement) =>
      _post('stockTransfer', {'movement': movement.toJson()});

  static Future<Map<String, dynamic>> createPurchase(
    StockTransaction transaction,
  ) =>
      _post('stockCreatePurchase', {'transaction': transaction.toJson()});

  static Future<Map<String, dynamic>> createSale(
    StockTransaction transaction,
  ) =>
      _post('stockCreateSale', {'transaction': transaction.toJson()});

  static Future<Map<String, dynamic>> returnTransaction(
    StockTransaction transaction,
  ) =>
      _post('stockReturnTransaction', {'transaction': transaction.toJson()});

  static Future<Map<String, dynamic>> reconcileStock({
    required String productId,
    required double countedQuantity,
    required String reason,
    required String locationId,
    String batchNumber = '',
  }) =>
      _post('stockReconcile', {
        'productId': productId,
        'countedQuantity': countedQuantity,
        'reason': reason,
        'locationId': locationId,
        'batchNumber': batchNumber,
      });
}

/// Immutable snapshot returned by [StockService.loadAll].
class StockData {
  const StockData({
    this.items = const [],
    this.transactions = const [],
    this.payments = const [],
    this.expenses = const [],
    this.locations = const [],
    this.parties = const [],
    this.movements = const [],
    this.adjustments = const [],
    this.auditLogs = const [],
    this.reservations = const [],
    this.lastSyncedAt,
  });

  final List<StockItem> items;
  final List<StockTransaction> transactions;
  final List<StockPayment> payments;
  final List<StockExpense> expenses;
  final List<StockLocation> locations;
  final List<StockParty> parties;
  final List<StockMovement> movements;
  final List<StockAdjustment> adjustments;
  final List<StockAuditLog> auditLogs;
  final List<StockReservation> reservations;
  final DateTime? lastSyncedAt;

  double get totalStockValue =>
      items.fold(0, (sum, item) => sum + item.stockValuation);
  double get expectedSalesValue =>
      items.fold(0, (sum, item) => sum + item.potentialSalesValue);
  double get expectedGrossProfit => expectedSalesValue - totalStockValue;
  int get lowStockCount => items.where((item) => item.isLowStock).length;
  int get expiringSoonCount =>
      items.where((item) => item.isExpiringSoon).length;
}

/// Typed exception so the screen can show a useful Bengali error.
class StockApiException implements Exception {
  const StockApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
