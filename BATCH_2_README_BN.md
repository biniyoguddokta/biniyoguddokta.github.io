# Somiti App — Batch 2

Firebase foundation and migration preparation. The existing Google Sheets backend remains primary. No Apps Script changes are included.

See `FIREBASE_SETUP_BN.md` before configuring Firebase. Do not run the migration service yet; it is a scaffold for a later admin-only workflow after security rules and schema are finalized.

Changed: `pubspec.yaml`, `lib/main.dart`; added Firebase config/bootstrap, migration service, Firestore deny-all rules and setup guide.

Flutter build and live Firebase tests must be confirmed by the user's GitHub Actions and Firebase project.
