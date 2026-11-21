# বিনিয়োগ উদ্যোক্তা — Flutter Package Status

এই প্যাকেজটি Batch 1-এর কিস্তিতে পণ্য/বিনিয়োগ UI পরিবর্তন এবং Batch 2-এর Firebase foundation-এর ওপর তৈরি। বিদ্যমান স্ক্রিন ও কিস্তিতে পণ্য স্ক্রিনের বিন্যাস অপরিবর্তিত রাখার চেষ্টা করা হয়েছে। Apps Script `Code.gs` এই প্যাকেজে পরিবর্তন করা হয়নি।

## অ্যাপে বর্তমানে কার্যকর

| ফিচার | বর্তমান অবস্থা |
|---|---|
| সদস্য, বিনিয়োগ, লেনদেন, কিস্তিতে পণ্যসহ আগের মডিউল | বিদ্যমান Google Sheets API-র মাধ্যমে কার্যকর; সার্ভার ও ইন্টারনেটের ওপর নির্ভরশীল |
| কিস্তি চুক্তি, কিস্তি আদায় ও কিস্তি ব্যয় | Batch 1/2-এর Flutter UI এবং বিদ্যমান API integration অন্তর্ভুক্ত |
| সদস্য প্রোফাইল | সদস্যের মৌলিক তথ্য, জমা/বকেয়ার হিসাব ও লেনদেন ইতিহাস দেখায় |
| Dark Mode | SharedPreferences-এ পছন্দ সংরক্ষণসহ কার্যকর |
| Smart Search | API থেকে পাওয়া সদস্য/লেনদেন/বিনিয়োগের ডেটা এই স্ক্রিনে filter করে |
| Pledge Documents | অঙ্গীকারনামার খসড়া এই ডিভাইসে সংরক্ষণ/মুছে ফেলা যায় |
| Advanced Reports | API-তে পাওয়া transaction data থেকে সারাংশ হিসাব করে; CSV text clipboard-এ কপি করা যায় |
| Digital Receipt | রসিদের preview তৈরি ও text কপি করা যায়; এটি PDF নয় |
| Reminder Preferences | রিমাইন্ডার পছন্দ এই ডিভাইসে সংরক্ষণ হয়; notification schedule হয় না |
| ভাষা পছন্দ | বাংলা/English নির্বাচন SharedPreferences-এ সংরক্ষিত হয়; পুরো অ্যাপের ভাষা বদলায় না |
| Firebase bootstrap | dart-define credentials না থাকলে আগের Google Sheets mode চালু থাকে |

## Backend / অতিরিক্ত Integration অপেক্ষমাণ

| ফিচার | যা এখনো করা হয়নি |
|---|---|
| Digital Receipt PDF | আসল PDF file generation, Bengali font rendering, unique receipt ID, server verification, print/share |
| Pledge Documents | Backend-এ upload/sync, স্বাক্ষর/অনুমোদন, member-linked document storage |
| Member 360° পূর্ণাঙ্গ | কিস্তি চুক্তি, সব financial relationship, documents, audit timeline একত্রে নির্ভরযোগ্য server aggregation |
| Advanced Reports | Server-side date filters, permission-controlled report endpoints, audited totals, PDF/Excel file export |
| Smart Search | Server-wide indexed search, pagination, role-aware results এবং result tap থেকে সঠিক detail navigation |
| Push Notification / Auto Reminder | Local notification scheduler, push token, server scheduler এবং delivery |
| Google Drive / OneDrive Backup | OAuth, encrypted backup, restore validation ও conflict handling; বর্তমানে status-only screen |
| Audit Log | Server-side tamper-resistant event log; বর্তমান screen কেবল স্থানীয় log list দেখায় |
| Full Bengali/English Localization | Flutter localization (ARB/generated l10n) এবং সব screen-এর text অনুবাদ |
| Firebase Migration | Firebase credentials, production security rules, auth/role flow, data mapping, duplicate reconciliation, migration verification |

## গুরুত্বপূর্ণ নিরাপত্তা ও ডেটা নোট

- `firestore.rules` ইচ্ছাকৃতভাবে deny-all। Rules পরিবর্তন না করে Firestore client read/write চালু হবে না।
- Firebase migration service scaffold; কোনো screen থেকে স্বয়ংক্রিয়ভাবে চালু হয় না। এখনই migration চালাবেন না।
- Google Sheets/Apps Script backend-ই বর্তমান primary backend। এই Flutter package-এর কারণে পুরোনো deployment বন্ধ বা পরিবর্তন করার দরকার নেই।
- এই ZIP-এ কোনো Firebase private key, service-account JSON বা OAuth secret নেই।
- UI preview বা local preference-কে server-saved/verified feature হিসেবে গণ্য করবেন না।

## Build যাচাই

এই প্যাকেজ তৈরির পরিবেশে Flutter/Dart SDK নেই। তাই এখানে `flutter pub get`, `flutter analyze` বা APK build চালিয়ে সফলতা নিশ্চিত করা যায়নি। GitHub Actions-এ Java 21 ও Flutter stable দিয়ে build workflow রাখা হয়েছে। ZIP extract করে repository-তে upload/push করার পর GitHub Actions run সম্পন্ন না হওয়া পর্যন্ত APK build verified বলা যাবে না।


## Batch 4 update
- Digital Receipt PDF: device-local create/save/preview/print/share implemented. Server verification remains pending.
- Pledge PDF: local create/save/preview/print/share implemented. Signature authentication and server sync remain pending.
- Saved PDF document archive: local list/open/share/print/delete implemented.
