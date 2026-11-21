# Batch 4 — Digital Receipt PDF & Pledge Documents

এই ZIP-টি Batch 3-এর cumulative source-এর ওপর তৈরি; Batch 1–3-এর ফাইল ও পরিবর্তন অক্ষত রাখা হয়েছে।

## Batch 4 additions
- Digital Receipt PDF generation with member, phone, amount, type, date and note.
- Local receipt PDF storage, preview/print and share.
- Pledge document PDF generation with member details, purpose, terms and signature lines.
- Local saved-document archive with preview, share, print and delete.
- Bundled Noto Sans Bengali font asset for PDF text.
- Permanent Android project retained; workflow verifies Android files and does not run `flutter create .`. The included executable `android/gradlew` downloads its pinned Gradle 8.7 distribution when first run.

## Important limitations
- Receipt numbers are device-local, not server-issued or verified.
- PDFs and archive metadata are stored on this device only. Reinstalling/clearing app data can remove them.
- Server upload/sync, official approval, signature authentication, witness workflow, role permissions and server receipt validation require Apps Script/API backend work. No Code.gs changes are included.
- PDF font support is bundled; verify Bengali conjunct rendering on the target Android device.

## Build validation
GitHub Actions runs `flutter pub get`, icon generation and `flutter build apk --release` using Java 21. This environment did not run Flutter analyze/test/APK build; use Actions to validate the final build.
