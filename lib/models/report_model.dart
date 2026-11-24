import 'package:intl/intl.dart';

class SomitiReportData {
  SomitiReportData({
    required this.members,
    required this.transactions,
    required this.investments,
    required this.installments,
    required this.stock,
    required this.salaryConnected,
    required this.salaryMessage,
    required this.lossConnected,
    required this.lossMessage,
    required this.generatedAt,
    required this.localLossProjects,
  });

  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> investments;
  final Map<String, dynamic> installments;
  final Map<String, dynamic> stock;
  final bool salaryConnected;
  final String salaryMessage;
  final bool lossConnected;
  final String lossMessage;
  final DateTime generatedAt;
  final List<Map<String, dynamic>> localLossProjects;

  static List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  factory SomitiReportData.fromJson(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>> localLossProjects = const [],
  }) {
    final salary = _map(json['salary']);
    final loss = _map(json['lossProjects']);
    return SomitiReportData(
      members: _rows(json['members']),
      transactions: _rows(json['transactions']),
      investments: _rows(json['investments']),
      installments: _map(json['installments']),
      stock: _map(json['stock']),
      salaryConnected: salary['connected'] == true,
      salaryMessage: (salary['message'] ?? '').toString(),
      lossConnected: loss['connected'] == true,
      lossMessage: (loss['message'] ?? '').toString(),
      generatedAt: DateTime.tryParse('${json['generatedAt']}') ?? DateTime.now(),
      localLossProjects: localLossProjects,
    );
  }
}

class ReportPeriod {
  const ReportPeriod(this.label, this.start, this.end);
  final String label;
  final DateTime start;
  final DateTime end;

  static ReportPeriod currentMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    return ReportPeriod('এই মাস', DateTime(n.year, n.month), DateTime(n.year, n.month + 1).subtract(const Duration(milliseconds: 1)));
  }

  static ReportPeriod fromPreset(String preset, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    switch (preset) {
      case 'আজ': return ReportPeriod(preset, today, today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)));
      case 'গত ৭ দিন': return ReportPeriod(preset, today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)));
      case 'এই বছর': return ReportPeriod(preset, DateTime(n.year), DateTime(n.year + 1).subtract(const Duration(milliseconds: 1)));
      case 'গত মাস': return ReportPeriod(preset, DateTime(n.year, n.month - 1), DateTime(n.year, n.month).subtract(const Duration(milliseconds: 1)));
      case 'এই মাস': return currentMonth(n);
      default: return ReportPeriod('সব সময়', DateTime(2000), DateTime(2100));
    }
  }
}

class ReportSummary {
  ReportSummary(this.data, this.period);
  final SomitiReportData data;
  final ReportPeriod period;

  static double number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '0').toString().replaceAll(',', '').replaceAll('৳', '').trim()) ?? 0;
  }

  static String _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    }
    return '';
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ?? DateFormat('dd/MM/yyyy').tryParse(raw) ?? DateFormat('dd-MM-yyyy').tryParse(raw);
  }

  bool _inPeriod(dynamic value) {
    final date = _date(value);
    if (date == null) return false;
    return !date.isBefore(period.start) && !date.isAfter(period.end);
  }

  List<Map<String, dynamic>> get filteredTransactions => data.transactions.where((row) => _inPeriod(_text(row, ['Date', 'date', 'TransactionDate']))).toList();

  double get income => filteredTransactions.fold(0.0, (sum, row) {
    final type = _text(row, ['Type', 'type', 'TransactionType']).toLowerCase();
    final status = _text(row, ['Status', 'status']).toLowerCase();
    if (status.contains('unpaid') || status.contains('বকেয়া') || status.contains('due')) return sum;
    if (type.contains('আয়') || type.contains('আয়') || type == 'income' || type == 'deposit' || type.contains('জমা')) {
      return sum + number(_text(row, ['Amount', 'amount']));
    }
    return sum;
  }) + stockSales;

  double get expenses => filteredTransactions.fold(0.0, (sum, row) {
    final type = _text(row, ['Type', 'type', 'TransactionType']).toLowerCase();
    final status = _text(row, ['Status', 'status']).toLowerCase();
    if (status.contains('unpaid') || status.contains('বকেয়া') || status.contains('due')) return sum;
    if (type.contains('ব্যয়') || type.contains('ব্যয়') || type.contains('খরচ') || type == 'expense' || type == 'withdrawal' || type.contains('উত্তোলন')) {
      return sum + number(_text(row, ['Amount', 'amount']));
    }
    return sum;
  }) + stockOperatingExpenses;

  double get net => income - expenses;
  int get totalMembers => data.members.length;
  int get activeMembers => data.members.where((m) => _text(m, ['Status', 'status']).toLowerCase() == 'active' || _text(m, ['Status', 'status']) == 'সক্রিয়').length;

  double get investedPrincipal => data.investments.fold(0.0, (s, row) => s + number(_text(row, ['InvestAmount', 'investAmount', 'InvestmentAmount', 'Amount'])));
  double get investmentProfit => data.investments.where((r) => _text(r, ['Status', 'status']) == 'সম্পন্ন').fold(0.0, (s, r) => s + number(_text(r, ['ProfitAmount', 'profitAmount'])));

  List<Map<String, dynamic>> get contracts => SomitiReportData._rows(data.installments['contracts']);
  List<Map<String, dynamic>> get payments => SomitiReportData._rows(data.installments['payments']);
  double get installmentContractValue => contracts.fold(0.0, (s, r) => s + number(r['SalePrice']));
  double get installmentDownPayment => contracts.fold(0.0, (s, r) => s + number(r['DownPayment']));
  double get installmentCollected => payments.where((r) => _inPeriod(r['PaymentDate'])).fold(0.0, (s, r) => s + number(r['Amount']));
  double get installmentOutstanding => (installmentContractValue - installmentDownPayment - payments.fold(0.0, (s, r) => s + number(r['Amount']))).clamp(0, double.infinity).toDouble();

  List<Map<String, dynamic>> get stockItems => SomitiReportData._rows(data.stock['items']);
  List<Map<String, dynamic>> get stockTransactions => SomitiReportData._rows(data.stock['transactions']);
  List<Map<String, dynamic>> get stockExpenses => SomitiReportData._rows(data.stock['expenses']);
  double get stockValue => stockItems.fold(0.0, (s, r) => s + (number(r['quantity']) - number(r['reservedQuantity']) - number(r['damagedQuantity'])).clamp(0, double.infinity).toDouble() * number(r['landedUnitCost']));
  double get stockSales => stockTransactions.where((r) => (r['type'] ?? '').toString().toLowerCase() == 'sale' && _inPeriod(r['date'])).fold(0.0, (s, r) => s + number(r['totalAmount']));
  double get stockPurchases => stockTransactions.where((r) => (r['type'] ?? '').toString().toLowerCase() == 'purchase' && _inPeriod(r['date'])).fold(0.0, (s, r) => s + number(r['totalAmount']));
  double get stockOperatingExpenses => stockExpenses.where((r) => _inPeriod(r['date']) && (r['referenceType'] ?? 'General').toString() == 'General').fold(0.0, (s, r) => s + number(r['amount']));

  List<Map<String, dynamic>> get filteredLossProjects => data.localLossProjects.where((r) => _inPeriod(r['lossDate'])).toList();
  double get totalLoss => filteredLossProjects.fold(0.0, (s, r) => s + number(r['totalLoss']));
  double get recoveredLoss => filteredLossProjects.fold(0.0, (s, r) => s + number(r['recoveredAmount']));
  double get remainingLoss => (totalLoss - recoveredLoss).clamp(0, double.infinity).toDouble();
}
