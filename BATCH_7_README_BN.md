# Batch 7 — Backup & Audit Log

## Batch 1–6 cumulative features
এই ZIP Batch 6-এর সম্পূর্ণ source-এর উপর তৈরি। আগের screen/module এবং স্থায়ী `android/` project রাখা হয়েছে।

## Batch 7-এ যোগ হয়েছে
- JSON Backup: Google Sheets API থেকে members, transactions, investments, meetings, constitution, late fees এবং installment data সংগ্রহ করে একটি versioned JSON ফাইলে export/share। কোনো source API error দিলে incomplete backup-কে সফল বলা হয় না।
- Local settings, reminder এবং local activity log backup file-এ রাখা হয়। Login state, PIN/password বা authentication credential backup করা হয় না।
- Restore file picker: JSON format/schema validation, 25 MB size limit এবং restore-এর আগে record count preview।
- Local Restore: theme/language/reminder preference, reminders এবং local audit history restore; অতীতের one-time reminder disabled অবস্থায় restore হয়।
- Audit Log: Google Sheets API-তে সফল/ব্যর্থ mutation action, actor name/phone reference, timestamp এবং safe action description local device-এ log হয়। Reminder create/delete, backup এবং restore-ও log হয়। Sensitive API payload/PIN/financial row contents log-এ লেখা হয় না।
- Activity Log search এবং JSON export।
- Backup/Restore/Activity Log screen-এ scope ও security warning।

## গুরুত্বপূর্ণ সীমাবদ্ধতা
- Google Sheets data JSON backup-এ export হয়; এই সংস্করণে server-side import API না থাকায় Sheets-এ remote data restore করা হয় না। UI-তে এই সীমা স্পষ্টভাবে দেখানো হয়েছে।
- Google Drive/OneDrive OAuth এবং automatic Cloud Sync চালু নয়। Credentials বা token flow ছাড়া cloud sync দাবি করা হয়নি।
- Local Audit Log tamper-proof নয়; app storage মুছে/পরিবর্তন করা সম্ভব। আইনগত/আর্থিক নির্ভরযোগ্য audit trail-এর জন্য authenticated server-side append-only endpoint, actor authorization এবং server timestamps প্রয়োজন।
- `firestore.rules` আগের deny-all নিরাপদ অবস্থায় রাখা হয়েছে। Production schema/role policy review না করে permissive rules দেওয়া হয়নি।
- `google-services.json` তৈরি/যোগ করা হয়নি; কোনো Firebase project credentials সরবরাহ করা হয়নি। বর্তমান optional Dart-define Firebase bootstrap অপরিবর্তিত।
- Backup JSON-এ ব্যক্তিগত ও আর্থিক তথ্য থাকতে পারে; বিশ্বস্ত স্থানে সংরক্ষণ করতে হবে।

## Build validation
এই environment-এ Flutter SDK অনুপস্থিত থাকলে `flutter pub get`, `flutter analyze`, tests এবং release APK build করা সম্ভব নয়। GitHub Actions-এ build করে প্রথম error থাকলে সেটি ঠিক করতে হবে। স্থায়ী `android/` directory এই ZIP-এ আছে; workflow `flutter create .` চালায় না।
