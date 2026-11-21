# Batch 2 — Firebase Foundation (বাংলা নির্দেশিকা)

## এই Batch-এ কী আছে
- Firebase Core, Authentication ও Cloud Firestore dependencies।
- `FIREBASE_*` dart-define দিয়ে Firebase initialize করার ব্যবস্থা।
- Firebase credentials ছাড়া অ্যাপ আগের Google Sheets mode-এ চলবে।
- Legacy Google Sheets ডেটা preview/import করার service scaffold। এটি নিজে থেকে চলে না।
- `firestore.rules`-এ secure default deny-all policy।

## গুরুত্বপূর্ণ সীমাবদ্ধতা
এই ZIP-এ আপনার Firebase project-এর credentials নেই। তাই Firebase Console project তৈরি, Android app registration, Authentication provider enable, Firestore database তৈরি এবং Rules deploy না করা পর্যন্ত Firebase read/write চালু হবে না। এখনই Google Sheets ডেটা মুছবেন না বা Apps Script deployment বন্ধ করবেন না।

## Firebase Console-এ প্রস্তুতি
1. Firebase Console-এ একটি project তৈরি করুন।
2. Android app register করুন। Package name জানতে `android/app/build.gradle` বা `android/app/build.gradle.kts`-এর `applicationId` দেখুন।
3. Authentication → Sign-in method-এ প্রয়োজনীয় provider enable করুন (পরবর্তী batch-এ login flow সংযুক্ত হবে)।
4. Firestore Database তৈরি করুন। Production mode নির্বাচন করুন।
5. এই Batch-এর `firestore.rules` deploy করলে সব client access বন্ধ থাকবে—এটি ইচ্ছাকৃত নিরাপদ default। পরবর্তী Batch-এ role/member schema অনুযায়ী নিয়ম তৈরি না হওয়া পর্যন্ত rules খুলবেন না।

## Build command (Firebase config ছাড়া)
```bash
flutter pub get
flutter build apk --release
```

## Firebase config দিয়ে build (প্রকল্পের তথ্য পূরণ করার পর)
```bash
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_ANDROID_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
```

**সতর্কতা:** dart-define values build artifact-এ পড়া সম্ভব; এগুলোকে secret/password হিসেবে বিবেচনা করবেন না। Firebase API key সাধারণত project identifier, কিন্তু security অবশ্যই Authentication, Firestore Rules এবং server-side authorization দিয়ে করতে হবে। Service account JSON/private key কখনো APK বা GitHub-এ দেবেন না।

## Migration service
`lib/services/firebase_migration_service.dart`-এ preview ও import scaffold আছে। এখনো কোনো screen/button থেকে এটি চালু করা হয়নি। Role-based access, duplicate reconciliation, member/transaction relationship mapping, financial totals reconciliation এবং backup যাচাই শেষ না করে import চালাবেন না। Migration-এর আগে Google Sheets-এর পূর্ণ backup নিন।

## Code.gs
এই Batch-এ Apps Script backend পরিবর্তন নেই। আগের deployed `Code.gs` অপরিবর্তিত রাখুন; redeploy প্রয়োজন নেই।
