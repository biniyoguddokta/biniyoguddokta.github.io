# Batch 9 — Final Integration & Release Package

## কী একত্র করা হয়েছে
- Batch 1–8-এর cumulative Flutter project এই Final ZIP-এর ভিত্তি।
- স্থায়ী `android/` project এবং বিদ্যমান GitHub Actions release workflow রাখা হয়েছে।
- সদস্য, কালেকশন, লেনদেন, বিনিয়োগ, কিস্তিতে পণ্য, রিপোর্ট, PDF, Reminder, Local Backup/Restore, Local Audit Log, Firebase bootstrap ও বিদ্যমান API integration ফাইল রাখা হয়েছে।
- Release verification script যোগ করা হয়েছে: `tool/verify_release.py`।
- বাংলা/ইংরেজি primary navigation ও Settings localization-এর smoke test যোগ করা হয়েছে: `test/app_localizations_test.dart`।
- GitHub Actions-এ release verification ও Flutter smoke test যোগ করা হয়েছে; এরপর Release APK build ও artifact upload হবে।

## কিস্তিতে পণ্য পেজ — অপরিবর্তিত থাকার প্রমাণ
`lib/screens/installment_product_screen.dart` ফাইলটি Batch 1, Batch 7 ও Batch 8 ZIP-এর মধ্যে byte-for-byte একই পাওয়া গেছে। SHA-256:

`6b2d50969db8f8594767ffaf3b6180e2021bcaf13167fc7c6331e6998916e1e4`

Batch 9-এও এই ফাইল পরিবর্তন করা হয়নি। `tool/verify_release.py` এই নির্দিষ্ট SHA-256 যাচাই করে; ফাইল বদলে গেলে CI release build-এর আগে ব্যর্থ হবে। ফলে কিস্তিতে পণ্য পেজের বর্তমান ডিজাইন অজান্তে বদলে গেলে তা ধরা পড়বে।

## গুরুত্বপূর্ণ সীমাবদ্ধতা
- বাংলা/ইংরেজি অনুবাদ সম্পূর্ণ অ্যাপজুড়ে শেষ হয়নি; Batch 8-এ primary navigation ও App Settings অনূদিত। Legacy screens-এ hard-coded বাংলা লেখা থাকতে পারে।
- Local Backup-এ Google Sheets-এর ডেটা export/archive হয়; Restore বর্তমানে device-local preferences, reminders ও audit history-তে সীমিত। Google Sheets server data restore চালু নয়।
- Audit Log device-local এবং tamper-proof/server-authoritative নয়।
- Firebase/Firestore cloud sync চালু নয়; Firebase project credentials ও server-side authorization/rules দরকার। Firestore deny-all policy অপরিবর্তিত। কোনো placeholder `google-services.json` যোগ করা হয়নি।
- Reminder local Android notifications; FCM push, server-side due detection ও automatic installment reminders backend pending।
- `Code.gs` বা Apps Script deployment পরিবর্তন করা হয়নি। বিদ্যমান API URL অপরিবর্তিত।

## যাচাইয়ের অবস্থা
- ZIP archive integrity এবং required-file checks সম্পন্ন করার জন্য release verification script যুক্ত।
- কিস্তিতে পণ্য screen-এর Batch 1 baseline hash যাচাইয়ের ব্যবস্থা যুক্ত।
- Flutter SDK এই packaging environment-এ উপলব্ধ ছিল না; তাই এই ZIP তৈরির সময় `flutter pub get`, `flutter test`, `flutter analyze` বা `flutter build apk --release` চালানো হয়নি।
- GitHub Actions-এ প্রথমে release verification, তারপর `flutter pub get`, localization smoke test এবং release APK build চলবে। GitHub Actions সফল না হওয়া পর্যন্ত APK build সফল বা অ্যাপ error-free বলা যাবে না।
