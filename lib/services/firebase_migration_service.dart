import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

/// Explicit, repeatable legacy import scaffold.
/// This class is intentionally NOT called automatically by the app.
/// Deploy reviewed Firestore Security Rules and sign in with an authorized
/// migration account before invoking it from a future admin-only migration UI.
class FirebaseMigrationService {
  FirebaseMigrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Map<String, int>> previewLegacyData() async {
    _requireSignedIn();
    final sources = await _loadLegacySources();
    return sources.map((key, value) => MapEntry(key, value.length));
  }

  /// Imports rows using deterministic document IDs, so retrying an import
  /// updates the same documents instead of creating duplicates.
  /// Call only after reviewing field mapping and deploying restrictive rules.
  Future<Map<String, int>> importLegacyData() async {
    _requireSignedIn();
    final sources = await _loadLegacySources();
    final counts = <String, int>{};
    for (final entry in sources.entries) {
      final collection = _firestore.collection('legacy_${entry.key}');
      var batch = _firestore.batch();
      var pending = 0;
      var written = 0;
      for (var i = 0; i < entry.value.length; i++) {
        final row = entry.value[i];
        final docId = _stableId(entry.key, row, i);
        final data = <String, dynamic>{
          ...row,
          '_migrationSource': 'google_sheets',
          '_migrationCollection': entry.key,
          '_migrationImportedAt': FieldValue.serverTimestamp(),
        };
        batch.set(collection.doc(docId), data, SetOptions(merge: true));
        pending++;
        written++;
        if (pending == 400) {
          await batch.commit();
          batch = _firestore.batch();
          pending = 0;
        }
      }
      if (pending > 0) await batch.commit();
      counts[entry.key] = written;
    }
    return counts;
  }

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw StateError('Firebase migration-এর আগে অনুমোদিত Firebase account দিয়ে sign in করুন।');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadLegacySources() async {
    final result = <String, List<Map<String, dynamic>>>{};
    await _add(result, 'members', ApiService.getAllMembers());
    await _add(result, 'transactions', ApiService.getTransactions());
    await _add(result, 'investments', ApiService.getInvestments());
    await _add(result, 'meetings', ApiService.getMeetings());
    await _add(result, 'constitution', ApiService.getConstitution());
    await _add(result, 'late_fees', ApiService.getLateFees());
    await _add(result, 'installment_data', ApiService.getInstallmentData());
    return result;
  }

  Future<void> _add(Map<String, List<Map<String, dynamic>>> target,
      String name, Future<dynamic> request) async {
    final value = await request;
    if (value is Map && value.containsKey('error')) {
      throw StateError('Google Sheets থেকে $name ডেটা পড়া যায়নি: ${value['error']}');
    }
    if (value is List) {
      target[name] = value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      return;
    }
    // Installment API returns a map of named row lists rather than one list.
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.value is List) {
          target['${name}_${entry.key}'] = (entry.value as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false);
        }
      }
      target.putIfAbsent(name, () => <Map<String, dynamic>>[]);
      return;
    }
    target[name] = <Map<String, dynamic>>[];
  }

  String _stableId(String collection, Map<String, dynamic> row, int index) {
    final preferred = row['MemberID'] ?? row['ContractID'] ?? row['PaymentID'] ??
        row['ProductID'] ?? row['ExpenseID'] ?? row['RowIndex'];
    final raw = preferred?.toString().trim();
    final safe = (raw == null || raw.isEmpty) ? 'row_$index' : raw;
    return '${collection}_$safe'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }
}
