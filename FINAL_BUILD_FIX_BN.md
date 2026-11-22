# Somiti App — Final Build Fix Package

এই প্যাকেজে আগের Somiti app source-এর সঙ্গে Android build configuration সমন্বয় করা হয়েছে।

## স্থির করা build configuration
- Flutter: 3.44.9 (GitHub Actions workflow-এ নির্দিষ্ট)
- Java: 21 (GitHub Actions workflow-এ নির্দিষ্ট)
- Android Gradle Plugin: 8.9.1 (`android/settings.gradle`)
- Gradle: 8.11.1 (`android/gradlew` এবং `android/gradle/wrapper/gradle-wrapper.properties`)
- intl: ^0.20.2 (`pubspec.yaml`)
- Release APK artifact path: `build/app/outputs/flutter-apk/app-release.apk`

## গুরুত্বপূর্ণ
- `android/gradlew` এবং `gradle-wrapper.properties` একই Gradle version ব্যবহার করে। এতে আগের Gradle 8.7 mismatch আর থাকবে না।
- `lib/screens/installment_product_screen.dart` অক্ষত রাখা হয়েছে। প্যাকেজে থাকা `tool/verify_release.py`-এর protected-file SHA-256 check সফল হয়েছে।
- Loss Project এবং Social Link পরিবর্তনসহ আগের ZIP-এর অ্যাপ সোর্স অক্ষত রাখা হয়েছে।
- Loss Project ও Social Link-এর লোকাল-ডিভাইস data sync সীমাবদ্ধতা আগের মতোই আছে; এই build fix নিজে থেকে server sync যোগ করে না।

## যাচাইয়ের অবস্থা
- ZIP integrity: যাচাই করা হয়েছে
- Required release files: যাচাই করা হয়েছে
- Protected installment screen hash: যাচাই করা হয়েছে
- Gradle/AGP/Flutter/intl version alignment: যাচাই করা হয়েছে
- Flutter APK compilation: এই পরিবেশে Flutter SDK না থাকায় চালানো যায়নি। GitHub Actions-এ নতুন workflow run সফল হলে APK build নিশ্চিত হবে।

## Codespaces-এ ব্যবহার
1. ZIP Extract করুন।
2. Extract করা `somiti-app-main` ফোল্ডারের ভেতরের ফাইলগুলো আপনার repository branch-এ দিন; আলাদা nested `somiti-app-main/somiti-app-main` ফোল্ডার তৈরি করবেন না।
3. Commit এবং Push করার পর GitHub Actions-এর `Build APK` workflow খুলুন।
