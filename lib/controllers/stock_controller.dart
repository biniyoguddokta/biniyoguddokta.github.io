
import 'package:flutter/foundation.dart';

import '../models/stock_model.dart';
import '../services/stock_service.dart';

/// Stock module state controller.
/// Google Sheets থেকে তথ্য লোড, সংরক্ষণ এবং রিফ্রেশ পরিচালনা করে।
class StockController extends ChangeNotifier {
  StockData _data = const StockData();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  StockData get data => _data;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  List<StockItem> get items => _data.items;
  List<StockTransaction> get transactions => _data.transactions;
  List<StockPayment> get payments => _data.payments;
  List<StockExpense> get expenses => _data.expenses;
  List<StockLocation> get locations => _data.locations;
  List<StockParty> get parties => _data.parties;
  List<StockMovement> get movements => _data.movements;
  List<StockAdjustment> get adjustments => _data.adjustments;
  List<StockAuditLog> get auditLogs => _data.auditLogs;
  List<StockReservation> get reservations => _data.reservations;

  double get totalStockValue => _data.totalStockValue;
  double get expectedSalesValue => _data.expectedSalesValue;
  double get expectedGrossProfit => _data.expectedGrossProfit;

  int get lowStockCount => _data.lowStockCount;
  int get expiringSoonCount => _data.expiringSoonCount;

  /// প্রথমবার অথবা প্রয়োজন অনুযায়ী Google Sheets থেকে সব তথ্য লোড।
  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await StockService.loadAll(
        forceRefresh: forceRefresh,
      );
      _lastSyncedAt = _data.lastSyncedAt;
    } catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// সার্ভার থেকে নতুন তথ্য এনে বর্তমান ডেটা আপডেট।
  Future<void> refresh() async {
    await load(forceRefresh: true);
  }

  /// সব পরিবর্তনের পর সার্ভারের সর্বশেষ তথ্য পুনরায় লোড।
  Future<void> _afterSave() async {
    await load(forceRefresh: true);
  }

  Future<bool> _performSave(
    Future<dynamic> Function() operation,
  ) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      await _afterSave();
      return _errorMessage == null;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveItem(StockItem item) {
    return _performSave(() => StockService.saveItem(item));
  }

  Future<bool> saveTransaction(StockTransaction transaction) {
    return _performSave(
      () => StockService.saveTransaction(transaction),
    );
  }

  Future<bool> savePayment(StockPayment payment) {
    return _performSave(() => StockService.savePayment(payment));
  }

  Future<bool> saveExpense(StockExpense expense) {
    return _performSave(() => StockService.saveExpense(expense));
  }

  Future<bool> saveLocation(StockLocation location) {
    return _performSave(() => StockService.saveLocation(location));
  }

  Future<bool> saveParty(StockParty party) {
    return _performSave(() => StockService.saveParty(party));
  }

  Future<bool> saveMovement(StockMovement movement) {
    return _performSave(() => StockService.saveMovement(movement));
  }

  Future<bool> saveAdjustment(StockAdjustment adjustment) {
    return _performSave(
      () => StockService.saveAdjustment(adjustment),
    );
  }

  Future<bool> saveReservation(StockReservation reservation) {
    return _performSave(
      () => StockService.saveReservation(reservation),
    );
  }

  Future<bool> createPurchase(StockTransaction transaction) {
    return _performSave(
      () => StockService.createPurchase(transaction),
    );
  }

  Future<bool> createSale(StockTransaction transaction) {
    return _performSave(
      () => StockService.createSale(transaction),
    );
  }

  Future<bool> returnTransaction(StockTransaction transaction) {
    return _performSave(
      () => StockService.returnTransaction(transaction),
    );
  }

  Future<bool> transferStock(StockMovement movement) {
    return _performSave(
      () => StockService.transferStock(movement),
    );
  }

  Future<bool> recordPayment(StockPayment payment) {
    return _performSave(
      () => StockService.recordPayment(payment),
    );
  }

  Future<bool> reconcileStock({
    required String productId,
    required double countedQuantity,
    required String reason,
    required String locationId,
    String batchNumber = '',
  }) {
    return _performSave(
      () => StockService.reconcileStock(
        productId: productId,
        countedQuantity: countedQuantity,
        reason: reason,
        locationId: locationId,
        batchNumber: batchNumber,
      ),
    );
  }

  Future<bool> archiveRecord({
    required String entityType,
    required String id,
    required String reason,
  }) {
    return _performSave(
      () => StockService.archiveRecord(
        entityType: entityType,
        id: id,
        reason: reason,
      ),
    );
  }

  Future<bool> approveAdjustment({
    required String id,
    required String approvalStatus,
    required String reason,
  }) {
    return _performSave(
      () => StockService.approveAdjustment(
        id: id,
        approvalStatus: approvalStatus,
        reason: reason,
      ),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _readableError(Object error) {
    if (error is StockApiException) {
      return error.message;
    }
    return error.toString();
  }
}
