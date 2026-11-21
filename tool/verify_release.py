#!/usr/bin/env python3
"""Repository-level release checks for the Somiti Flutter app.

This intentionally locks the installment product screen to its original
Batch 1 bytes. If its design/source is intentionally changed in the future,
review the change explicitly and update this pin only with user approval.
"""
from pathlib import Path
import hashlib
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_INSTALLMENT_SHA256 = "6b2d50969db8f8594767ffaf3b6180e2021bcaf13167fc7c6331e6998916e1e4"
REQUIRED = [
    "pubspec.yaml",
    "android/settings.gradle",
    "android/build.gradle",
    "android/gradle.properties",
    "android/app/build.gradle",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/src/main/kotlin/com/example/somiti_app/MainActivity.kt",
    "android/gradle/wrapper/gradle-wrapper.properties",
    "android/gradlew",
    ".github/workflows/build.yml",
    "lib/screens/installment_product_screen.dart",
    "lib/services/api_service.dart",
    "lib/services/reminder_service.dart",
    "lib/services/backup_service.dart",
    "lib/services/audit_log_service.dart",
    "lib/theme/app_theme.dart",
    "lib/l10n/app_localizations.dart",
    "BATCH_9_FINAL_README_BN.md",
]
missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
if missing:
    print("FAIL: missing required release files:")
    print("\n".join(missing))
    sys.exit(1)

installment = ROOT / "lib/screens/installment_product_screen.dart"
actual = hashlib.sha256(installment.read_bytes()).hexdigest()
if actual != EXPECTED_INSTALLMENT_SHA256:
    print("FAIL: installment_product_screen.dart differs from approved Batch 1 baseline")
    print(f"expected: {EXPECTED_INSTALLMENT_SHA256}")
    print(f"actual:   {actual}")
    sys.exit(1)

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ("flutter_local_notifications:", "timezone:", "flutter_timezone:", "firebase_core:", "firebase_auth:", "cloud_firestore:", "file_picker:"):
    if dep not in pubspec:
        print(f"FAIL: required dependency declaration missing: {dep}")
        sys.exit(1)

manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
for marker in ("POST_NOTIFICATIONS", "RECEIVE_BOOT_COMPLETED"):
    if marker not in manifest:
        print(f"FAIL: required Android manifest entry missing: {marker}")
        sys.exit(1)

workflow = (ROOT / ".github/workflows/build.yml").read_text(encoding="utf-8")
for marker in ("flutter pub get", "flutter build apk --release", "upload-artifact@v4"):
    if marker not in workflow:
        print(f"FAIL: required CI workflow step missing: {marker}")
        sys.exit(1)

print("PASS: required release files are present")
print("PASS: installment product screen matches approved Batch 1 SHA-256")
print("PASS: Firebase, reminder, backup and Android notification declarations are present")
print("PASS: permanent Android project and release APK workflow are present")
