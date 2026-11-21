import 'package:firebase_core/firebase_core.dart';
import '../config/firebase_options.dart';

/// Optional Firebase initialization. Legacy Google Sheets mode remains active
/// when Firebase project values have not been provided.
class FirebaseBootstrap {
  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    if (isReady || !FirebaseOptionsConfig.isConfigured) return;
    await Firebase.initializeApp(options: FirebaseOptionsConfig.currentPlatform);
  }
}
