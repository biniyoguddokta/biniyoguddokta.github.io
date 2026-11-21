# Batch 3 — Member 360° ও Financial Management

## এই ব্যাচে যুক্ত
- Member Profile-কে Member 360° dashboard-এ উন্নীত করা হয়েছে।
- সদস্যের জমা, বকেয়া, আয় ও ব্যয়ের সারাংশ।
- সদস্যের সাম্প্রতিক লেনদেনের তালিকা এবং সদস্যের পরিচিতি তথ্য।
- বিনিয়োগ প্রকল্পের সারাংশ (বর্তমান Investments API থেকে)।
- নতুন Financial Management screen: সমিতির জমা, বকেয়া, আয়, ব্যয়, সক্রিয় বিনিয়োগ ও ঘোষিত প্রকল্প-লাভ।
- Home screen-এর Drawer থেকে Financial Management-এ প্রবেশ।
- স্থায়ী `android/` platform project যোগ করা হয়েছে; CI আর `flutter create .` চালায় না।

## ডেটা ও সীমাবদ্ধতা
- সব আর্থিক তথ্য বর্তমান Google Apps Script API থেকে read-only summary হিসেবে নেওয়া হয়।
- বর্তমান Transaction API-তে সদস্যের Phone field না থাকলে Member 360° নামের মিল ব্যবহার করে; তাই একই নাম থাকলে হিসাব মিশে যেতে পারে।
- Investments API-তে প্রকল্পের সদস্য-ভিত্তিক মালিকানা/বণ্টন না থাকায় সদস্যের স্ক্রিনে প্রকল্প তালিকা সমিতির সামগ্রিক তালিকা। একে ব্যক্তিগত বিনিয়োগ বলা হচ্ছে না।
- ব্যাংক ব্যালেন্স, double-entry ledger, audited closing, date-range report, approval workflow ও server-side role enforcement-এর জন্য Backend/API পরিবর্তন প্রয়োজন। এই ব্যাচে `Code.gs` পরিবর্তন করা হয়নি।

## Android platform
- `android/` folder স্থায়ীভাবে ZIP-এ অন্তর্ভুক্ত।
- Gradle 8.7, Android Gradle Plugin 8.6.1, Kotlin 2.1.0, Java 21 CI runtime।
- `android/gradlew` pinned Gradle distribution না থাকলে CI/local build environment-এ download করে। Build environment-এ internet access লাগবে।
- Package ID বর্তমানে `com.example.somiti_app`। পূর্বে Play Store-এ প্রকাশিত APK থাকলে তার applicationId-এর সঙ্গে মিলিয়ে নিতে হবে; applicationId বদলালে পুরোনো অ্যাপের ওপর update install হবে না।
- Firebase credentials / `google-services.json` যোগ করা হয়নি; এই ব্যাচে Firebase initialization ঐচ্ছিকই আছে।

## যাচাই
এই পরিবেশে Flutter/Dart SDK নেই, তাই `flutter analyze`, `flutter test` বা APK build চালানো সম্ভব হয়নি। ZIP structure, workflow references ও Android XML/YAML syntax-এর প্রাথমিক যাচাই করা হয়েছে। GitHub Actions build সফল না হওয়া পর্যন্ত APK-কে build-verified বলা যাবে না।
