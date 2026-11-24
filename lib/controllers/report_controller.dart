import 'package:flutter/foundation.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  SomitiReportData? data;
  bool loading = false;
  String? error;
  String selectedPeriod = 'এই মাস';

  ReportSummary? get summary => data == null
      ? null
      : ReportSummary(data!, ReportPeriod.fromPreset(selectedPeriod));

  Future<void> load({bool forceRefresh = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await ReportService.load(forceRefresh: forceRefresh);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setPeriod(String value) {
    selectedPeriod = value;
    notifyListeners();
  }
}
