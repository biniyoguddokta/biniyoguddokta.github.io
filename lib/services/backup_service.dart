import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';
import 'audit_log_service.dart';
import 'reminder_service.dart';

class BackupInspection {
  final Map<String, dynamic> document;
  final Map<String, int> counts;
  BackupInspection(this.document, this.counts);
}

class BackupService {
  static const int schemaVersion = 1;
  static const List<String> _localPreferenceKeys = [
    'isDarkMode', 'app_language', 'rem_dues', 'rem_meetings', 'rem_installments',
  ];

  static Future<File> createAndShareBackup() async {
    final responses = await Future.wait<dynamic>([
      ApiService.getAllMembers(), ApiService.getTransactions(),
      ApiService.getInvestments(), ApiService.getMeetings(),
      ApiService.getConstitution(), ApiService.getLateFees(),
      ApiService.getInstallmentData(),
    ]);
    const names = ['members', 'transactions', 'investments', 'meetings', 'constitution', 'lateFees', 'installments'];
    final remote = <String, dynamic>{};
    for (var i = 0; i < responses.length; i++) {
      final value = responses[i];
      if (value is Map && value.containsKey('error')) {
        throw StateError('${names[i]} ডেটা পাওয়া যায়নি: ${value['error']}');
      }
      remote[names[i]] = value;
    }

    final prefs = await SharedPreferences.getInstance();
    final local = <String, dynamic>{};
    for (final key in _localPreferenceKeys) {
      if (prefs.containsKey(key)) local[key] = prefs.get(key);
    }
    final reminders = (await ReminderService.instance.getAll()).map((e) => e.toJson()).toList();
    final audit = await AuditLogService.read();
    final document = <String, dynamic>{
      'format': 'somiti_app_backup',
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'app': 'বিনিয়োগ উদ্যোক্তা',
      'remoteData': remote,
      'localData': {'preferences': local, 'reminders': reminders, 'auditLog': audit},
      'restoreNote': 'Remote Google Sheets data is included for archival/export. Server-side restore is not available in this app version.',
    };
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final file = File('${dir.path}/somiti_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(document), flush: true);
    await AuditLogService.record(action: 'Backup export', details: 'JSON backup created and shared');
    await Share.shareXFiles([XFile(file.path)], text: 'সমিতি অ্যাপের JSON Backup');
    return file;
  }

  static Future<BackupInspection> pickAndInspectBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['json'], withData: true,
    );
    if (result == null || result.files.isEmpty) throw StateError('কোনো ফাইল নির্বাচন করা হয়নি।');
    final picked = result.files.single;
    final bytes = picked.bytes ?? (picked.path == null ? null : await File(picked.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) throw StateError('Backup ফাইল পড়া যায়নি।');
    if (bytes.length > 25 * 1024 * 1024) throw StateError('Backup ফাইল ২৫ MB-এর বেশি।');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['format'] != 'somiti_app_backup') {
      throw const FormatException('এটি বিনিয়োগ উদ্যোক্তা অ্যাপের বৈধ Backup ফাইল নয়।');
    }
    if (decoded['schemaVersion'] != schemaVersion) throw const FormatException('এই Backup ফাইলের সংস্করণ সমর্থিত নয়।');
    if (decoded['remoteData'] is! Map || decoded['localData'] is! Map) {
      throw const FormatException('Backup ফাইলের প্রয়োজনীয় data section নেই।');
    }
    final localCheck = Map<String, dynamic>.from(decoded['localData'] as Map);
    final reminderCheck = localCheck['reminders'];
    if (reminderCheck != null && reminderCheck is! List) {
      throw const FormatException('Reminder data format সঠিক নয়।');
    }
    for (final row in (reminderCheck as List? ?? const [])) {
      if (row is! Map) throw const FormatException('একটি Reminder record সঠিক নয়।');
      // Parse now, before the user confirms restore, so malformed dates/IDs
      // cannot leave a partially restored local state.
      ReminderItem.fromJson(Map<String, dynamic>.from(row));
    }
    final remote = Map<String, dynamic>.from(decoded['remoteData'] as Map);
    final counts = <String, int>{};
    for (final entry in remote.entries) {
      counts[entry.key] = _countRows(entry.value);
    }
    return BackupInspection(decoded, counts);
  }

  static int _countRows(dynamic value) {
    if (value is List) return value.length;
    if (value is Map) return value.values.fold<int>(0, (sum, v) => sum + _countRows(v));
    return value == null ? 0 : 1;
  }

  /// Restores only device-local preferences, reminders and activity history.
  /// Google Sheets records require a separately reviewed server import endpoint.
  static Future<void> restoreLocalData(BackupInspection inspection) async {
    final local = inspection.document['localData'];
    if (local is! Map) throw const FormatException('Backup-এ localData নেই।');
    final prefs = await SharedPreferences.getInstance();
    final settings = local['preferences'];
    if (settings is Map) {
      for (final key in _localPreferenceKeys) {
        if (!settings.containsKey(key)) continue;
        final value = settings[key];
        if (value is bool) await prefs.setBool(key, value);
        if (value is String) await prefs.setString(key, value);
        if (value is int) await prefs.setInt(key, value);
        if (value is double) await prefs.setDouble(key, value);
      }
    }
    final reminderRows = local['reminders'];
    if (reminderRows is List) {
      for (final item in reminderRows.whereType<Map>()) {
        final reminder = ReminderItem.fromJson(Map<String, dynamic>.from(item));
        final safeReminder = reminder.repeat == 'none' && reminder.enabled && !reminder.scheduledAt.isAfter(DateTime.now())
            ? reminder.copyWith(enabled: false)
            : reminder;
        await ReminderService.instance.save(safeReminder);
      }
    }
    final auditRows = local['auditLog'];
    if (auditRows is List) await AuditLogService.restore(auditRows);
    await AuditLogService.record(action: 'Local restore', details: 'Device settings, reminders and activity history restored');
  }
}
