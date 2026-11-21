# Flutter Package Build Guide (Android)

1. ZIP extract করে project-এর সব ফাইল GitHub repository-র root-এ upload করুন (root-এ `pubspec.yaml`, `lib/`, `.github/` থাকবে)।
2. আপনার বর্তমান working branch-এ commit/push করুন; অন্য branch-এ merge না করে আগে build যাচাই করুন।
3. GitHub repository → Actions → **Build APK** workflow খুলুন।
4. Run সফল হলে workflow run-এর Artifacts থেকে `release-apk` download করুন।
5. APK ইনস্টল করে login, সদস্য, বিনিয়োগ, কিস্তিতে পণ্য, লেনদেন, Dark Mode এবং নতুন “উন্নত ফিচারসমূহ” স্ক্রিন পরীক্ষা করুন।

## Build ব্যর্থ হলে
Actions-এর প্রথম লাল error এবং তার আগের 30–50 log line দিন।

## Backend
এই Flutter ZIP-এ Apps Script `Code.gs` পরিবর্তন নেই। Backend phase আলাদাভাবে করতে হবে। Feature-by-feature বর্তমান অবস্থা `FINAL_PACKAGE_STATUS_BN.md`-এ দেওয়া আছে।
